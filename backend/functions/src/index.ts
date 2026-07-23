import { initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { HttpsError, onCall, onRequest } from 'firebase-functions/v2/https';
import { defineSecret, defineString } from 'firebase-functions/params';

import { DeepSeekProvider } from './ai/deepseekProvider';
import { Orchestrator, CoachContext } from './ai/orchestrator';
import { setKnowledgeStore } from './ai/grounding';
import { checkAndIncrementRateLimit } from './middleware/rateLimit';
import { deleteUserData, exportUserData } from './account/lifecycle';
import { isAcceptable, validatePlan, MealPlan } from './plan/validatePlan';

initializeApp();

// Secrets and config. Model ID is a non-secret parameter so it can be changed
// (after passing the eval suite) without redeploying secrets.
const DEEPSEEK_API_KEY = defineSecret('DEEPSEEK_API_KEY');
const MODEL_ID = defineString('MODEL_ID', { default: 'deepseek-chat' });
const DEEPSEEK_BASE_URL = defineString('DEEPSEEK_BASE_URL', {
  default: 'https://api.deepseek.com',
});
const DAILY_AI_LIMIT = defineString('DAILY_AI_LIMIT', { default: '150' });
// App Check enforcement. Defaults to enforced (fail-closed). May be set to
// 'false' ONLY for a development project that is verified from a client
// without the native App Check SDK (e.g. the Flutter web build). Production
// and native Android/iOS builds must keep this enforced.
const APP_CHECK_ENFORCED = defineString('APP_CHECK_ENFORCED', {
  default: 'true',
});

// Optional: wire the reviewed knowledge base for retrieval grounding. Until a
// KnowledgeStore is provided, grounding returns an empty set (the model then
// states uncertainty rather than fabricating). See ai/grounding.ts.
setKnowledgeStore({
  async search() {
    // Placeholder integration boundary — replace with a Firestore/vector
    // lookup over the reviewed `/reference/**` collection. Returning [] here
    // is safe: it never fabricates sources.
    return [];
  },
});

function requireAuth(auth: { uid?: string } | undefined): string {
  if (!auth?.uid) {
    throw new HttpsError('unauthenticated', 'Sign-in required.');
  }
  return auth.uid;
}

/**
 * AI Coach endpoint. Streams newline-delimited JSON events:
 *   {"type":"delta","text":"..."}   (incremental)
 *   {"type":"final", ...CoachAnswer} (structured result)
 * App Check is enforced; per-user rate limiting is applied server-side.
 */
export const coachAsk = onRequest(
  {
    secrets: [DEEPSEEK_API_KEY],
    // Allow cross-origin calls (needed for the Flutter web build, whose
    // origin differs from the functions domain). This does not weaken
    // security: every request must still carry a valid App Check token and
    // Firebase ID token — a foreign origin has neither. Native Android/iOS
    // builds do not use CORS at all.
    cors: true,
    timeoutSeconds: 60,
    memory: '512MiB',
  },
  async (request, response) => {
    if (request.method !== 'POST') {
      response.status(405).send('Method not allowed');
      return;
    }
    // App Check: streaming onRequest handlers verify the token manually
    // (enforceAppCheck is only available on onCall). Reject requests without
    // a valid App Check token to block automated abuse. Enforcement can be
    // disabled per-environment (APP_CHECK_ENFORCED=false) for a dev project
    // exercised from a client without the native App Check SDK; production
    // stays fail-closed by default.
    if (APP_CHECK_ENFORCED.value() !== 'false') {
      const appCheckToken = request.get('X-Firebase-AppCheck');
      if (!appCheckToken) {
        response.status(401).send('App Check required');
        return;
      }
      try {
        const { getAppCheck } = await import('firebase-admin/app-check');
        await getAppCheck().verifyToken(appCheckToken);
      } catch {
        response.status(401).send('Invalid App Check token');
        return;
      }
    }
    // The client sends a Firebase ID token; verify via the Admin SDK.
    const authHeader = request.get('Authorization') ?? '';
    const token = authHeader.replace(/^Bearer /, '');
    let uid: string;
    try {
      const { getAuth } = await import('firebase-admin/auth');
      uid = (await getAuth().verifyIdToken(token)).uid;
    } catch {
      response.status(401).send('Unauthorized');
      return;
    }

    const limit = parseInt(DAILY_AI_LIMIT.value(), 10);
    const rate = await checkAndIncrementRateLimit(uid, limit);
    if (!rate.allowed) {
      response.status(429).json({ error: 'Daily AI limit reached.' });
      return;
    }

    const body = request.body as {
      question?: string;
      context?: CoachContext;
      history?: Array<{ role: 'user' | 'coach'; text: string }>;
    };
    if (!body.question || !body.context) {
      response.status(400).json({ error: 'Missing question or context.' });
      return;
    }

    const provider = new DeepSeekProvider(
      DEEPSEEK_API_KEY.value(),
      MODEL_ID.value(),
      DEEPSEEK_BASE_URL.value()
    );
    const orchestrator = new Orchestrator(provider, null);

    response.setHeader('Content-Type', 'application/x-ndjson');
    try {
      const result = await orchestrator.run(
        body.question,
        body.context,
        body.history ?? [],
        (partial) => {
          response.write(
            JSON.stringify({ type: 'delta', text: partial }) + '\n'
          );
        }
      );
      response.write(
        JSON.stringify({ type: 'final', ...result.answer }) + '\n'
      );
      // Audit WITHOUT content: only metadata.
      await getFirestore().collection('audit').add({
        action: 'coach_ask',
        uid,
        blocked: result.blocked,
        safetyCategory: result.safetyCategory,
        at: new Date().toISOString(),
      });
      response.end();
    } catch (err) {
      response.write(
        JSON.stringify({
          type: 'error',
          message: 'The AI Coach is temporarily unavailable.',
        }) + '\n'
      );
      response.end();
      console.error('coachAsk failed', (err as Error).message);
    }
  }
);

/** Validates a meal plan before it is persisted/synced. */
export const validateMealPlan = onCall(
  { enforceAppCheck: true },
  async (request) => {
    requireAuth(request.auth);
    const { plan, allergies, recipeAllergens } = request.data as {
      plan: MealPlan;
      allergies: string[];
      recipeAllergens: Record<string, string[]>;
    };
    const issues = validatePlan(plan, allergies ?? [], recipeAllergens ?? {});
    return { issues, acceptable: isAcceptable(issues) };
  }
);

/** Exports all of the caller's data as JSON. */
export const exportMyData = onCall(
  { enforceAppCheck: true },
  async (request) => {
    const uid = requireAuth(request.auth);
    return exportUserData(uid);
  }
);

/**
 * Deletes the caller's account and all associated data. Requires a recent
 * sign-in (reauthentication) — Firebase marks the token with auth_time, which
 * we require to be within the last 5 minutes for this destructive action.
 */
export const deleteMyAccount = onCall(
  { enforceAppCheck: true },
  async (request) => {
    const uid = requireAuth(request.auth);
    const authTime = (request.auth?.token as { auth_time?: number })?.auth_time;
    const fresh = authTime && Date.now() / 1000 - authTime < 300;
    if (!fresh) {
      throw new HttpsError(
        'failed-precondition',
        'Please reauthenticate before deleting your account.'
      );
    }
    await deleteUserData(uid);
    return { deleted: true };
  }
);
