import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';

/**
 * Account lifecycle: authoritative data export and full deletion.
 *
 * Deletion removes the user's entire Firestore subtree, rate-limit counters,
 * and the Auth account. It is triggered by an authenticated, reauthenticated
 * client call (see index.ts) and logged to the audit trail WITHOUT any health
 * details — only the uid, action and timestamp.
 */

const OWNED_SUBCOLLECTIONS = [
  'diary',
  'plans',
  'fasting',
  'progress',
  'coachHistory',
  'customFoods',
  'consent',
];

export async function exportUserData(uid: string): Promise<Record<string, unknown>> {
  const db = getFirestore();
  const userDoc = await db.doc(`users/${uid}`).get();
  const result: Record<string, unknown> = {
    exportedAt: new Date().toISOString(),
    profile: userDoc.exists ? userDoc.data() : null,
  };
  for (const sub of OWNED_SUBCOLLECTIONS) {
    const snap = await db.collection(`users/${uid}/${sub}`).get();
    result[sub] = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
  }
  return result;
}

export async function deleteUserData(uid: string): Promise<void> {
  const db = getFirestore();

  for (const sub of OWNED_SUBCOLLECTIONS) {
    await deleteCollection(db, `users/${uid}/${sub}`);
  }
  await db.doc(`users/${uid}`).delete();

  // Remove rate-limit counters for this user.
  const limits = await db
    .collection('rateLimits')
    .where('__name__', '>=', `${uid}_`)
    .where('__name__', '<', `${uid}_`)
    .get();
  await Promise.all(limits.docs.map((d) => d.ref.delete()));

  // Finally, delete the Auth account.
  await getAuth().deleteUser(uid);

  // Audit: record the action with NO health details.
  await db.collection('audit').add({
    action: 'account_deletion',
    uid,
    at: new Date().toISOString(),
  });
}

async function deleteCollection(
  db: FirebaseFirestore.Firestore,
  path: string,
  batchSize = 200
): Promise<void> {
  const collectionRef = db.collection(path);
  // eslint-disable-next-line no-constant-condition
  while (true) {
    const snap = await collectionRef.limit(batchSize).get();
    if (snap.empty) break;
    const batch = db.batch();
    snap.docs.forEach((d) => batch.delete(d.ref));
    await batch.commit();
    if (snap.size < batchSize) break;
  }
}
