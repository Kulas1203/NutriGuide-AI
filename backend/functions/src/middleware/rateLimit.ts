import { getFirestore } from 'firebase-admin/firestore';

/**
 * Per-user, per-day rate limiting for AI requests, enforced server-side using
 * a Firestore counter document. This complements the client-side entitlement
 * check and cannot be bypassed by a modified client.
 *
 * Audit-safe: the counter document stores only counts and a day key — never
 * question text or health details.
 */
export async function checkAndIncrementRateLimit(
  uid: string,
  dailyLimit: number
): Promise<{ allowed: boolean; remaining: number }> {
  const db = getFirestore();
  const dayKey = new Date().toISOString().slice(0, 10);
  const ref = db.doc(`rateLimits/${uid}_${dayKey}`);

  return db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const count = (snap.exists ? (snap.data()?.count as number) : 0) ?? 0;
    if (count >= dailyLimit) {
      return { allowed: false, remaining: 0 };
    }
    tx.set(
      ref,
      {
        count: count + 1,
        dayKey,
        updatedAt: new Date().toISOString(),
        // TTL field for automatic cleanup via a Firestore TTL policy.
        expireAt: new Date(Date.now() + 2 * 24 * 3600 * 1000),
      },
      { merge: true }
    );
    return { allowed: true, remaining: dailyLimit - count - 1 };
  });
}
