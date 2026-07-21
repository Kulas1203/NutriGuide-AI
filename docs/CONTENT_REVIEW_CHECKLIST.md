# Human-Review Checklist for Nutritional Content

All nutrition content is drafted for general education and must be reviewed by
a qualified professional (registered dietitian) before public release.

## Diet program content (`app/lib/features/diets/domain/diet_catalog.dart`)

- [ ] No diet is portrayed as universally superior.
- [ ] Every program lists limitations and "who should seek guidance first".
- [ ] Evidence references are real, verifiable publications.
- [ ] No extreme restriction, detox/cleanse, prolonged or dry fasting.
- [ ] Sustainability/difficulty ratings are reasonable.
- [ ] Nutrient-gap notes are accurate (e.g. vegan B12).
- [ ] Content version bumped when copy changes.

## Food & recipe data (`data/*`, `app/assets/data/*`)

- [ ] Verified foods carry USDA FoodData Central references.
- [ ] Verified kcal is within tolerance of the Atwater estimate (generator
      enforces this and fails the build otherwise).
- [ ] Filipino dishes and recipes are clearly marked "recipe estimate".
- [ ] Estimated items show their ingredient/serving assumptions in-app.
- [ ] No fabricated local-food values.

## Calorie & macro logic (`features/targets/domain/energy_calculator.dart`)

- [ ] Formula (Mifflin–St Jeor) is disclosed to the user.
- [ ] Safety calorie floor is respected; no shame-based messaging.
- [ ] Unrealistic target dates are flagged.
- [ ] Calculation version recorded for reproducibility.

## AI safety copy (`features/coach/domain/safety_classifier.dart`, backend)

- [ ] Emergency, self-harm, ED, dangerous-fasting, severe-restriction, child,
      pregnancy, medication, disease messages are compassionate and accurate.
- [ ] AI evaluation suite passes (`node ai_evals/run_safety_evals.mjs`).

## Legal & disclaimers

- [ ] Product statement appears in all required places.
- [ ] All legal drafts reviewed by qualified legal counsel.
- [ ] No false company/credential/certification claims.
