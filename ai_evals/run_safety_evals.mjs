#!/usr/bin/env node
/**
 * Runs the versioned AI evaluation dataset against the AUTHORITATIVE
 * server-side safety classifier, asserting each case produces the expected
 * safety action/category. This is the gate that MUST pass before enabling a
 * new safety-classifier or prompt version (master requirement §21).
 *
 * It imports the compiled backend classifier so there is a single source of
 * truth (no duplicated safety logic). Build the backend first:
 *   (cd backend/functions && npm run build)
 * then:
 *   node ai_evals/run_safety_evals.mjs
 *
 * Full model-answer evaluation (checking the natural-language answer against
 * each case's expectedBehavior) runs against a staging backend and is
 * documented in docs/SETUP.md; this script covers the deterministic safety
 * gate that protects users regardless of model behavior.
 */
import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const datasetPath = join(here, 'dataset.v1.json');
const classifierPath = join(
  here,
  '..',
  'backend',
  'functions',
  'lib',
  'safety',
  'classifier.js'
);

let classify, SAFETY_VERSION;
try {
  ({ classify, SAFETY_VERSION } = await import(classifierPath));
} catch (e) {
  console.error(
    'Could not load the compiled safety classifier. Build the backend first:\n' +
      '  (cd backend/functions && npm run build)\n'
  );
  console.error(String(e.message ?? e));
  process.exit(2);
}

const dataset = JSON.parse(readFileSync(datasetPath, 'utf8'));

if (dataset.safetyVersion !== SAFETY_VERSION) {
  console.error(
    `Safety version mismatch: dataset expects ${dataset.safetyVersion} but ` +
      `classifier is ${SAFETY_VERSION}. Re-review the dataset before shipping.`
  );
  process.exit(2);
}

let passed = 0;
const failures = [];
for (const c of dataset.cases) {
  const result = classify(c.input);
  const actionOk = result.action === c.expectedAction;
  const categoryOk = result.category === c.expectedCategory;
  if (actionOk && categoryOk) {
    passed++;
  } else {
    failures.push({
      id: c.id,
      input: c.input,
      expected: { action: c.expectedAction, category: c.expectedCategory },
      got: { action: result.action, category: result.category },
    });
  }
}

console.log(`AI safety evals (${dataset.version} / ${SAFETY_VERSION})`);
console.log(`  Passed ${passed}/${dataset.cases.length}`);
if (failures.length) {
  console.error('\nFailures:');
  for (const f of failures) {
    console.error(
      `  [${f.id}] "${f.input}"\n    expected ${JSON.stringify(f.expected)}\n    got      ${JSON.stringify(f.got)}`
    );
  }
  process.exit(1);
}
console.log('All safety evaluations passed.');
