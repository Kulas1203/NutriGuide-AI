import { classify, SAFETY_VERSION } from '../safety/classifier';
import { retrieveGrounding } from './grounding';
import {
  AiProvider,
  AiProviderError,
  CoachAnswer,
  CoachRequest,
} from './provider';

/**
 * Coach orchestration: applies the safety layer, retrieves grounding, calls
 * the provider (with retry + optional fallback), and enforces the structured
 * contract. This is the single choke point for AI requests — the app never
 * reaches a model vendor directly.
 */

export interface CoachContext {
  dietId: string;
  calorieTarget: number;
  allergies: string[];
  goal: string;
  requiresProfessionalGuidance: boolean;
  historyEnabled: boolean;
}

export interface OrchestratorResult {
  answer: CoachAnswer;
  blocked: boolean;
  safetyCategory: string;
}

const SYSTEM_PROMPT =
  'You are the NutriGuide AI Nutrition Coach. You provide general, ' +
  'educational nutrition information and wellness guidance for adults. You ' +
  'are NOT a doctor or registered dietitian and you say so when relevant. ' +
  'You never diagnose, prescribe, promise outcomes, encourage extreme ' +
  'restriction, or fabricate studies, citations, or numbers. Distinguish ' +
  'established evidence from general guidance and uncertain evidence, and ' +
  'say when you do not know. Recommend a qualified professional whenever a ' +
  'question exceeds general wellness guidance.';

export class Orchestrator {
  constructor(
    private readonly primary: AiProvider,
    private readonly fallback: AiProvider | null,
    private readonly maxOutputTokens = 900
  ) {}

  async run(
    question: string,
    context: CoachContext,
    history: Array<{ role: 'user' | 'coach'; text: string }>,
    onDelta: (partialText: string) => void
  ): Promise<OrchestratorResult> {
    const safety = classify(question);

    // Hard blocks never reach the model.
    if (safety.action === 'blockEmergency' || safety.action === 'blockRefer') {
      return {
        blocked: true,
        safetyCategory: safety.category,
        answer: {
          text: safety.message ?? '',
          nextSteps: [],
          sources: [],
          confidence: 'individual',
          professionalReferral: true,
        },
      };
    }

    const grounding = await retrieveGrounding(question, context);
    const req: CoachRequest = {
      question,
      systemPrompt: SYSTEM_PROMPT,
      grounding,
      history: context.historyEnabled ? history.slice(-8) : [],
      cautionNote:
        safety.action === 'allowWithCaution' ? safety.message : undefined,
      maxOutputTokens: this.maxOutputTokens,
    };

    const answer = await this.generateWithRetry(req, onDelta);

    // Enforce referral framing for caution categories and profile flags.
    if (safety.action === 'allowWithCaution' || context.requiresProfessionalGuidance) {
      answer.professionalReferral = true;
      if (safety.message) {
        answer.limitations = answer.limitations
          ? `${safety.message}\n\n${answer.limitations}`
          : safety.message;
      }
    }

    return { answer, blocked: false, safetyCategory: safety.category };
  }

  private async generateWithRetry(
    req: CoachRequest,
    onDelta: (partialText: string) => void
  ): Promise<CoachAnswer> {
    const attempts = 2;
    for (let i = 0; i < attempts; i++) {
      try {
        return await this.primary.generate(req, onDelta);
      } catch (err) {
        const retryable = err instanceof AiProviderError && err.retryable;
        if (!retryable || i === attempts - 1) break;
        await delay(250 * Math.pow(2, i));
      }
    }
    // Provider fallback (no secret exposure — both live server-side).
    if (this.fallback) {
      return this.fallback.generate(req, onDelta);
    }
    throw new AiProviderError('All providers failed', false);
  }

  static safetyVersion(): string {
    return SAFETY_VERSION;
  }
}

function delay(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}
