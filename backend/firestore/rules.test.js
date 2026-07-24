/**
 * Firestore security-rules tests.
 *
 * Runs against the Firestore emulator using @firebase/rules-unit-testing.
 * Verifies per-user authorization: users can read/write only their own data,
 * cross-user access is denied, reference content is read-only, and audit logs
 * are never client-accessible.
 *
 * Run:
 *   firebase emulators:exec --only firestore \
 *     "node --test backend/firestore/rules.test.js"
 */
const assert = require('node:assert');
const { test, before, after } = require('node:test');
const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} = require('@firebase/rules-unit-testing');
const fs = require('node:fs');
const path = require('node:path');

let testEnv;

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: 'nutriguide-rules-test',
    firestore: {
      rules: fs.readFileSync(path.join(__dirname, 'firestore.rules'), 'utf8'),
      host: '127.0.0.1',
      port: 8080,
    },
  });
});

after(async () => {
  if (testEnv) await testEnv.cleanup();
});

function alice() {
  return testEnv.authenticatedContext('alice').firestore();
}
function bob() {
  return testEnv.authenticatedContext('bob').firestore();
}
function anon() {
  return testEnv.unauthenticatedContext().firestore();
}

test('a user can create and read their own profile', async () => {
  const db = alice();
  await assertSucceeds(db.doc('users/alice').set({ id: 'alice', name: 'A' }));
  await assertSucceeds(db.doc('users/alice').get());
});

test('a user cannot read another user profile', async () => {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    await ctx.firestore().doc('users/alice').set({ id: 'alice' });
  });
  await assertFails(bob().doc('users/alice').get());
});

test('a user cannot write another user diary entry', async () => {
  await assertFails(
    bob().doc('users/alice/diary/x').set({ name: 'stolen' })
  );
});

test('a user can write their own diary entries', async () => {
  await assertSucceeds(
    alice().doc('users/alice/diary/x').set({ name: 'rice', dayKey: '2026-07-21' })
  );
});

test('unauthenticated access is denied', async () => {
  await assertFails(anon().doc('users/alice').get());
});

test('profile uid is immutable / must match on create', async () => {
  await assertFails(alice().doc('users/alice').set({ id: 'bob' }));
});

test('clients cannot delete the root user document', async () => {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    await ctx.firestore().doc('users/alice').set({ id: 'alice' });
  });
  await assertFails(alice().doc('users/alice').delete());
});

test('reference content is read-only for clients', async () => {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    await ctx.firestore().doc('reference/diet-balanced').set({ v: 1 });
  });
  await assertSucceeds(alice().doc('reference/diet-balanced').get());
  await assertFails(alice().doc('reference/diet-balanced').set({ v: 2 }));
});

test('audit logs are never client-accessible', async () => {
  await assertFails(alice().doc('audit/x').get());
  await assertFails(alice().doc('audit/x').set({ a: 1 }));
});

test('consent history is append-only', async () => {
  await assertSucceeds(
    alice().doc('users/alice/consent/c1').set({ version: 'v1' })
  );
  await assertFails(
    alice().doc('users/alice/consent/c1').set({ version: 'v2' })
  );
});
