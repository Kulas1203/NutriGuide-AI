#!/usr/bin/env node
/**
 * Seed-data generator for NutriGuide AI.
 *
 * Produces app/assets/data/foods.json and app/assets/data/recipes.json from
 * the definitions below.
 *
 * Data rules (see docs/CONTENT_REVIEW_CHECKLIST.md):
 *  - `verified` foods carry USDA FoodData Central references and use the
 *    published kcal value; the generator checks it against the Atwater
 *    estimate (4/4/9) and fails on implausible entries.
 *  - Filipino dishes and all recipes are `recipeEstimate`: kcal is COMPUTED
 *    from macros (Atwater) so totals can never be internally inconsistent,
 *    and every entry lists the ingredient/serving assumptions used.
 *
 * Run: node tool/generate_seed_data.mjs
 */
import { writeFileSync, mkdirSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const outDir = join(root, 'app', 'assets', 'data');
mkdirSync(outDir, { recursive: true });

const atwater = (p, c, f) => p * 4 + c * 4 + f * 9;
const round1 = (v) => Math.round(v * 10) / 10;

/** Verified foods: per-100 g values from USDA FoodData Central. */
// name, category, kcal, protein, carbs, fat, fiber, sodiumMg, serving name, serving g, FDC ref, allergens, tags
const verifiedFoods = [
  ['rice_white_cooked', 'White rice, cooked', 'grains', 130, 2.7, 28.2, 0.3, 0.4, 1, '1 cup, cooked', 158, 'USDA FDC 168878', [], ['balanced', 'general', 'vegetarian', 'vegan']],
  ['rice_brown_cooked', 'Brown rice, cooked', 'grains', 123, 2.7, 25.6, 1.0, 1.6, 4, '1 cup, cooked', 195, 'USDA FDC 168875', [], ['balanced', 'high_fiber', 'whole_food', 'vegan']],
  ['oats_dry', 'Rolled oats, dry', 'grains', 389, 16.9, 66.3, 6.9, 10.6, 2, '1/2 cup, dry', 40, 'USDA FDC 169705', ['gluten'], ['high_fiber', 'whole_food', 'vegan', 'balanced']],
  ['bread_whole_wheat', 'Whole-wheat bread', 'grains', 252, 12.3, 42.7, 3.5, 6.8, 455, '1 slice', 32, 'USDA FDC 335240', ['wheat', 'gluten'], ['high_fiber', 'balanced', 'vegan']],
  ['potato_boiled', 'Potato, boiled', 'grains', 87, 1.9, 20.1, 0.1, 1.8, 4, '1 medium', 150, 'USDA FDC 170438', [], ['whole_food', 'vegan', 'balanced']],
  ['sweet_potato_boiled', 'Sweet potato, boiled', 'grains', 76, 1.4, 17.7, 0.1, 2.5, 27, '1 medium', 150, 'USDA FDC 168483', [], ['whole_food', 'high_fiber', 'vegan']],
  ['pasta_cooked', 'Pasta, cooked', 'grains', 158, 5.8, 30.9, 0.9, 1.8, 1, '1 cup, cooked', 140, 'USDA FDC 168927', ['wheat', 'gluten'], ['balanced', 'vegan']],
  ['chicken_breast_cooked', 'Chicken breast, roasted, skinless', 'protein', 165, 31.0, 0, 3.6, 0, 74, '100 g, cooked', 100, 'USDA FDC 171477', [], ['high_protein', 'low_carb', 'keto', 'balanced']],
  ['chicken_thigh_cooked', 'Chicken thigh, roasted', 'protein', 209, 26.0, 0, 10.9, 0, 84, '1 thigh', 90, 'USDA FDC 171482', [], ['high_protein', 'keto', 'low_carb']],
  ['beef_ground_cooked', 'Ground beef 85% lean, pan-browned', 'protein', 246, 24.6, 0, 15.4, 0, 72, '100 g, cooked', 100, 'USDA FDC 174036', [], ['high_protein', 'keto', 'low_carb']],
  ['pork_loin_cooked', 'Pork loin, cooked', 'protein', 242, 27.3, 0, 14.0, 0, 53, '100 g, cooked', 100, 'USDA FDC 167902', [], ['high_protein', 'keto', 'low_carb']],
  ['egg_boiled', 'Egg, hard-boiled', 'dairy', 155, 12.6, 1.1, 10.6, 0, 124, '1 large egg', 50, 'USDA FDC 173424', ['egg'], ['high_protein', 'keto', 'low_carb', 'vegetarian']],
  ['salmon_cooked', 'Salmon, Atlantic, cooked', 'protein', 206, 22.1, 0, 12.4, 0, 61, '1 fillet', 125, 'USDA FDC 175168', ['fish'], ['pescatarian', 'mediterranean', 'keto', 'high_protein']],
  ['tuna_canned_water', 'Tuna, canned in water, drained', 'protein', 116, 25.5, 0, 0.8, 0, 320, '1 can, drained', 120, 'USDA FDC 175159', ['fish'], ['pescatarian', 'high_protein', 'low_carb']],
  ['milkfish_raw', 'Milkfish (bangus), raw', 'protein', 148, 20.5, 0, 6.7, 0, 72, '1 serving', 120, 'USDA FDC 171961', ['fish'], ['pescatarian', 'high_protein']],
  ['tilapia_cooked', 'Tilapia, cooked', 'protein', 128, 26.2, 0, 2.7, 0, 56, '1 fillet', 110, 'USDA FDC 175177', ['fish'], ['pescatarian', 'high_protein', 'low_carb']],
  ['shrimp_cooked', 'Shrimp, cooked', 'protein', 99, 24.0, 0.2, 0.3, 0, 111, '100 g, cooked', 100, 'USDA FDC 175180', ['shellfish'], ['pescatarian', 'high_protein', 'keto']],
  ['tofu_firm', 'Tofu, firm', 'protein', 144, 17.3, 2.8, 8.7, 2.3, 14, '1/2 block', 120, 'USDA FDC 172476', ['soy'], ['vegan', 'vegetarian', 'high_protein', 'low_carb']],
  ['milk_whole', 'Milk, whole', 'dairy', 61, 3.2, 4.8, 3.3, 0, 43, '1 cup', 244, 'USDA FDC 171265', ['milk'], ['vegetarian', 'balanced']],
  ['yogurt_plain', 'Yogurt, plain, whole milk', 'dairy', 61, 3.5, 4.7, 3.3, 0, 46, '1 cup', 245, 'USDA FDC 171284', ['milk'], ['vegetarian', 'balanced', 'mediterranean']],
  ['greek_yogurt_nonfat', 'Greek yogurt, plain, nonfat', 'dairy', 59, 10.2, 3.6, 0.4, 0, 36, '1 cup', 245, 'USDA FDC 170903', ['milk'], ['high_protein', 'vegetarian', 'mediterranean']],
  ['cheddar', 'Cheddar cheese', 'dairy', 403, 24.9, 1.3, 33.1, 0, 621, '1 slice', 28, 'USDA FDC 168826', ['milk'], ['keto', 'low_carb', 'vegetarian']],
  ['cottage_cheese', 'Cottage cheese, 2%', 'dairy', 84, 11.0, 4.3, 2.3, 0, 321, '1/2 cup', 113, 'USDA FDC 173417', ['milk'], ['high_protein', 'vegetarian', 'low_carb']],
  ['broccoli_cooked', 'Broccoli, cooked', 'vegetables', 35, 2.4, 7.2, 0.4, 3.3, 41, '1 cup, chopped', 156, 'USDA FDC 169967', [], ['vegan', 'keto', 'low_carb', 'high_fiber', 'whole_food']],
  ['spinach_raw', 'Spinach, raw', 'vegetables', 23, 2.9, 3.6, 0.4, 2.2, 79, '2 cups, raw', 60, 'USDA FDC 168462', [], ['vegan', 'keto', 'low_carb', 'high_fiber']],
  ['carrot_raw', 'Carrot, raw', 'vegetables', 41, 0.9, 9.6, 0.2, 2.8, 69, '1 medium', 61, 'USDA FDC 170393', [], ['vegan', 'whole_food', 'high_fiber']],
  ['tomato_raw', 'Tomato, raw', 'vegetables', 18, 0.9, 3.9, 0.2, 1.2, 5, '1 medium', 123, 'USDA FDC 170457', [], ['vegan', 'keto', 'mediterranean', 'whole_food']],
  ['cabbage_raw', 'Cabbage, raw', 'vegetables', 25, 1.3, 5.8, 0.1, 2.5, 18, '1 cup, shredded', 89, 'USDA FDC 169975', [], ['vegan', 'low_carb', 'high_fiber']],
  ['kangkong_raw', 'Water spinach (kangkong), raw', 'vegetables', 19, 2.6, 3.1, 0.2, 2.1, 113, '1 bunch', 100, 'USDA FDC 168571', [], ['vegan', 'low_carb', 'whole_food']],
  ['eggplant_cooked', 'Eggplant, cooked', 'vegetables', 35, 0.8, 8.7, 0.2, 2.5, 1, '1 cup', 99, 'USDA FDC 169229', [], ['vegan', 'low_carb', 'mediterranean']],
  ['squash_butternut', 'Squash (kalabasa), baked', 'vegetables', 40, 0.9, 10.5, 0.1, 3.2, 4, '1 cup, cubed', 205, 'USDA FDC 169296', [], ['vegan', 'whole_food', 'high_fiber']],
  ['green_beans_cooked', 'Green beans (sitaw), cooked', 'vegetables', 35, 1.9, 7.9, 0.3, 3.2, 1, '1 cup', 125, 'USDA FDC 169961', [], ['vegan', 'high_fiber', 'whole_food']],
  ['banana', 'Banana', 'fruit', 89, 1.1, 22.8, 0.3, 2.6, 1, '1 medium', 118, 'USDA FDC 173944', [], ['vegan', 'whole_food', 'balanced']],
  ['apple', 'Apple, with skin', 'fruit', 52, 0.3, 13.8, 0.2, 2.4, 1, '1 medium', 182, 'USDA FDC 171688', [], ['vegan', 'whole_food', 'high_fiber']],
  ['orange', 'Orange', 'fruit', 47, 0.9, 11.8, 0.1, 2.4, 0, '1 medium', 131, 'USDA FDC 169097', [], ['vegan', 'whole_food']],
  ['mango', 'Mango', 'fruit', 60, 0.8, 15.0, 0.4, 1.6, 1, '1 cup, sliced', 165, 'USDA FDC 169910', [], ['vegan', 'whole_food']],
  ['papaya', 'Papaya', 'fruit', 43, 0.5, 10.8, 0.3, 1.7, 8, '1 cup, cubed', 145, 'USDA FDC 169926', [], ['vegan', 'whole_food']],
  ['pineapple', 'Pineapple', 'fruit', 50, 0.5, 13.1, 0.1, 1.4, 1, '1 cup, chunks', 165, 'USDA FDC 169124', [], ['vegan', 'whole_food']],
  ['mung_beans_cooked', 'Mung beans (monggo), cooked', 'legumes', 105, 7.0, 19.2, 0.4, 7.6, 2, '1 cup, cooked', 202, 'USDA FDC 175265', [], ['vegan', 'high_fiber', 'whole_food', 'high_protein']],
  ['chickpeas_cooked', 'Chickpeas, cooked', 'legumes', 164, 8.9, 27.4, 2.6, 7.6, 7, '1 cup, cooked', 164, 'USDA FDC 173757', [], ['vegan', 'high_fiber', 'mediterranean']],
  ['lentils_cooked', 'Lentils, cooked', 'legumes', 116, 9.0, 20.1, 0.4, 7.9, 2, '1 cup, cooked', 198, 'USDA FDC 172421', [], ['vegan', 'high_fiber', 'mediterranean', 'high_protein']],
  ['kidney_beans_cooked', 'Kidney beans, cooked', 'legumes', 127, 8.7, 22.8, 0.5, 6.4, 1, '1 cup, cooked', 177, 'USDA FDC 175194', [], ['vegan', 'high_fiber']],
  ['peanut_butter', 'Peanut butter, smooth', 'legumes', 588, 25.1, 19.6, 50.4, 6.0, 426, '2 tbsp', 32, 'USDA FDC 172470', ['peanut'], ['vegan', 'keto', 'high_protein']],
  ['almonds', 'Almonds, raw', 'legumes', 579, 21.2, 21.6, 49.9, 12.5, 1, '1 small handful', 28, 'USDA FDC 170567', ['tree nut'], ['vegan', 'keto', 'mediterranean', 'high_fiber']],
  ['olive_oil', 'Olive oil', 'fats', 884, 0, 0, 100, 0, 2, '1 tbsp', 14, 'USDA FDC 171413', [], ['vegan', 'keto', 'mediterranean']],
  ['butter', 'Butter', 'fats', 717, 0.9, 0.1, 81.1, 0, 643, '1 tbsp', 14, 'USDA FDC 173430', ['milk'], ['keto', 'vegetarian']],
  ['avocado', 'Avocado', 'fats', 160, 2.0, 8.5, 14.7, 6.7, 7, '1/2 fruit', 100, 'USDA FDC 171705', [], ['vegan', 'keto', 'mediterranean', 'whole_food']],
  ['coconut_milk_canned', 'Coconut milk, canned', 'fats', 197, 2.0, 2.8, 21.3, 0, 13, '1/4 cup', 60, 'USDA FDC 170173', [], ['vegan', 'keto']],
  ['soy_milk_unsweetened', 'Soy milk, unsweetened', 'beverages', 33, 2.9, 1.2, 1.8, 0.4, 38, '1 cup', 243, 'USDA FDC 175215', ['soy'], ['vegan', 'low_carb']],
  ['quinoa_cooked', 'Quinoa, cooked', 'grains', 120, 4.4, 21.3, 1.9, 2.8, 7, '1 cup, cooked', 185, 'USDA FDC 168917', [], ['vegan', 'high_fiber', 'whole_food', 'mediterranean']],
  ['corn_boiled', 'Corn, sweet, boiled', 'vegetables', 96, 3.4, 21.0, 1.5, 2.4, 1, '1 ear', 103, 'USDA FDC 169998', [], ['vegan', 'whole_food']],
  ['hummus', 'Hummus', 'legumes', 166, 7.9, 14.3, 9.6, 6.0, 379, '1/4 cup', 60, 'USDA FDC 174289', ['sesame'], ['vegan', 'mediterranean', 'high_fiber']],
];

/**
 * Filipino dishes: per-100 g estimates computed from typical home recipes.
 * kcal is derived from macros (Atwater) — never invented independently.
 * Each entry documents its assumptions for in-app display.
 */
// id, name, protein, carbs, fat, fiber, sodiumMg, serving, servingG, assumptions, allergens, tags
const estimatedDishes = [
  ['chicken_adobo', 'Chicken adobo', 16.0, 3.5, 11.0, 0.3, 480, '1 cup with sauce', 225,
    'Chicken thigh braised in soy sauce, vinegar, garlic and oil; ~1 tbsp sauce included per serving. Home recipe proportions: 1 kg chicken, 1/2 cup soy sauce, 1/2 cup vinegar, 2 tbsp oil for 6 servings.', ['soy'], ['general', 'balanced', 'high_protein', 'filipino']],
  ['pork_sinigang', 'Pork sinigang (sour soup)', 5.5, 4.5, 2.9, 1.2, 420, '1 bowl with broth', 350,
    'Pork belly and shoulder mix simmered with tamarind broth, kangkong, radish, tomato and string beans. Broth included; ~120 g pork per liter of soup.', [], ['general', 'balanced', 'whole_food', 'low_carb', 'filipino']],
  ['chicken_tinola', 'Chicken tinola', 6.0, 2.5, 2.4, 0.6, 350, '1 bowl with broth', 350,
    'Chicken pieces simmered with ginger broth, green papaya/sayote and malunggay leaves. Bone-out edible portion estimated at 90 g per bowl.', [], ['general', 'balanced', 'whole_food', 'low_carb', 'filipino']],
  ['pinakbet_veg', 'Pinakbet (vegetable version)', 2.5, 7.0, 2.7, 2.6, 390, '1 cup', 160,
    'Kalabasa, sitaw, talong, ampalaya and okra sautéed with tomato and a small amount of miso in place of bagoong. Traditional versions with bagoong or pork have more sodium and fat.', ['soy'], ['vegan', 'vegetarian', 'high_fiber', 'whole_food', 'filipino']],
  ['pancit_bihon', 'Pancit bihon with chicken and vegetables', 6.0, 18.0, 3.9, 1.4, 410, '1 cup', 160,
    'Rice noodles stir-fried with shredded chicken breast, cabbage, carrots and soy sauce; 1 tbsp oil per 4 servings.', ['soy'], ['general', 'balanced', 'filipino']],
  ['arroz_caldo', 'Arroz caldo (chicken rice porridge)', 5.0, 13.5, 2.4, 0.3, 380, '1 bowl', 300,
    'Rice porridge with chicken, ginger, garlic and fish sauce, topped with a sliver of egg. ~60 g chicken and 50 g raw rice per bowl.', ['egg'], ['general', 'balanced', 'filipino']],
  ['tortang_talong', 'Tortang talong (eggplant omelet)', 5.5, 4.5, 6.3, 1.8, 260, '1 piece', 170,
    'Grilled eggplant flattened into beaten egg and pan-fried in ~1 tsp oil per piece.', ['egg'], ['vegetarian', 'low_carb', 'general', 'filipino']],
  ['ginisang_monggo', 'Ginisang monggo (mung bean stew)', 6.5, 11.0, 2.6, 3.4, 330, '1 cup', 240,
    'Mung beans simmered and sautéed with garlic, onion, tomato and malunggay; plant version without pork or shrimp. 1 tbsp oil per 4 servings.', [], ['vegan', 'vegetarian', 'high_fiber', 'whole_food', 'general', 'filipino']],
  ['sinangag', 'Sinangag (garlic fried rice)', 3.5, 29.0, 5.4, 0.5, 300, '1 cup', 160,
    'Day-old rice fried with garlic and ~1 tsp oil per cup, lightly salted.', [], ['vegan', 'general', 'filipino']],
  ['lumpiang_shanghai', 'Lumpiang shanghai (fried spring rolls)', 10.0, 18.0, 14.4, 1.0, 420, '3 pieces', 90,
    'Ground pork and vegetable filling in wheat wrappers, deep-fried. Oil absorption estimated at 10% of weight.', ['wheat', 'gluten'], ['general', 'filipino']],
  ['beef_tapa', 'Beef tapa', 22.0, 4.0, 10.8, 0, 620, '1 serving', 100,
    'Thin-sliced beef cured with soy sauce, garlic and sugar, pan-fried. Cure absorbs ~1 tsp soy sauce per serving.', ['soy'], ['high_protein', 'low_carb', 'general', 'filipino']],
  ['lechon_kawali', 'Lechon kawali (crispy pork belly)', 18.0, 1.0, 38.3, 0, 480, '1 serving', 100,
    'Pork belly boiled then deep-fried; skin included. Values reflect the high fat of the cut.', [], ['keto', 'low_carb', 'general', 'filipino']],
];

const foods = [];
for (const [id, name, category, kcal, p, c, f, fiber, sodium, servingName, servingGrams, ref, allergens, tags] of verifiedFoods) {
  const est = atwater(p, c, f);
  // Fiber contributes listed carbs but ~2 kcal/g, so high-fiber foods run
  // below the 4/4/9 estimate; allow that plus general rounding slack.
  const slack = Math.max(15, est * 0.15) + fiber * 2.5;
  if (Math.abs(est - kcal) > slack) {
    throw new Error(`Implausible energy for ${id}: listed ${kcal}, Atwater ${est.toFixed(0)}`);
  }
  foods.push({
    id, name, category,
    per100g: { kcal, proteinG: p, carbsG: c, fatG: f, fiberG: fiber, sodiumMg: sodium },
    servingName, servingGrams, source: 'verified', sourceRef: ref,
    allergens, tags,
  });
}
for (const [id, name, p, c, f, fiber, sodium, servingName, servingGrams, assumptions, allergens, tags] of estimatedDishes) {
  foods.push({
    id, name, category: 'dishes',
    per100g: { kcal: round1(atwater(p, c, f)), proteinG: p, carbsG: c, fatG: f, fiberG: fiber, sodiumMg: sodium },
    servingName, servingGrams, source: 'recipeEstimate',
    sourceRef: 'NutriGuide curated dataset v1',
    assumptions, allergens, tags,
  });
}

/**
 * Recipes for the meal planner. perServing kcal computed from macros.
 * [id, name, description, cuisine, slots, servings, prepMin, costTier,
 *  protein, carbs, fat, fiber, sodium, ingredients, steps, tags, allergens, assumptions]
 */
const recipes = [
  ['banana_peanut_oatmeal', 'Banana peanut oatmeal', 'Warm oats with banana slices and peanut butter, made with water or any plant milk.', 'General', ['breakfast'], 1, 10, 1,
    13, 62, 14, 8.5, 160,
    [['Rolled oats', 50], ['Banana', 118, null, ['Apple', 'Mango']], ['Peanut butter', 16, null, ['Almond butter']], ['Water or unsweetened soy milk', 240]],
    ['Simmer oats in liquid for 4–5 minutes.', 'Top with sliced banana and peanut butter.'],
    ['vegan', 'vegetarian', 'high_fiber', 'whole_food', 'balanced', 'low_sodium', 'general'], ['peanut', 'gluten'],
    'Made with water or unsweetened soy milk; dairy milk adds ~90 kcal.'],
  ['veggie_omelet', 'Vegetable omelet with cheese', 'Two-egg omelet with tomato, spinach and a little cheddar.', 'General', ['breakfast'], 1, 12, 1,
    21, 6, 25, 1.8, 480,
    [['Eggs', 100], ['Spinach', 40], ['Tomato', 60], ['Cheddar cheese', 20, null, ['Feta']], ['Olive oil', 7]],
    ['Sauté vegetables in oil.', 'Add beaten eggs, cook until just set, fold with cheese.'],
    ['vegetarian', 'keto', 'low_carb', 'high_protein', 'balanced', 'general'], ['egg', 'milk'], null],
  ['greek_yogurt_bowl', 'Greek yogurt bowl with fruit and almonds', 'High-protein yogurt with mango and crunchy almonds.', 'Mediterranean', ['breakfast', 'snack'], 1, 5, 2,
    24, 32, 12, 4.5, 95,
    [['Greek yogurt, plain', 200], ['Mango', 120, null, ['Banana', 'Papaya']], ['Almonds', 20], ['Honey (optional)', 7]],
    ['Layer yogurt, fruit and almonds in a bowl.'],
    ['vegetarian', 'high_protein', 'mediterranean', 'balanced', 'general'], ['milk', 'tree nut'], null],
  ['tofu_scramble', 'Tofu scramble with vegetables', 'Savory crumbled tofu with tomato, onion and greens.', 'General', ['breakfast'], 1, 15, 1,
    22, 10, 16, 3.5, 380,
    [['Firm tofu', 150], ['Tomato', 80], ['Spinach or kangkong', 50], ['Olive oil', 10], ['Turmeric and pepper', 2]],
    ['Crumble tofu into a hot oiled pan.', 'Add vegetables and spices; cook 5 minutes.'],
    ['vegan', 'vegetarian', 'high_protein', 'low_carb', 'whole_food', 'general'], ['soy'], null],
  ['tomato_olive_toast', 'Tomato and olive oil toast', 'Whole-grain toast rubbed with tomato, olive oil and oregano.', 'Mediterranean', ['breakfast', 'snack'], 1, 8, 1,
    9, 46, 13, 7.0, 490,
    [['Whole-wheat bread', 64], ['Tomato', 100], ['Olive oil', 10], ['Oregano', 1]],
    ['Toast bread.', 'Top with grated tomato, oil and oregano.'],
    ['vegan', 'vegetarian', 'mediterranean', 'high_fiber', 'balanced', 'general'], ['wheat', 'gluten'], null],
  ['sinangag_egg', 'Garlic rice with fried egg', 'Classic Filipino breakfast: sinangag topped with an egg and tomato.', 'Filipino', ['breakfast'], 1, 15, 1,
    14, 50, 18, 1.8, 520,
    [['Sinangag (garlic fried rice)', 160], ['Egg', 50], ['Tomato', 60], ['Oil for frying', 5]],
    ['Fry day-old rice with garlic.', 'Top with a fried egg and sliced tomato.'],
    ['vegetarian', 'general', 'balanced'], ['egg'],
    'Estimated from home proportions; see the sinangag entry for rice assumptions.'],
  ['arroz_caldo_bowl', 'Chicken arroz caldo', 'Comforting ginger rice porridge with chicken and calamansi.', 'Filipino', ['breakfast', 'lunch'], 4, 40, 1,
    17, 41, 8, 1.0, 900,
    [['Rice', 200, 'raw'], ['Chicken thigh', 400, null, ['Chicken breast']], ['Ginger, garlic, onion', 60], ['Fish sauce', 24], ['Calamansi', 20]],
    ['Sauté aromatics, add rice and stock; simmer 25 minutes.', 'Add shredded chicken; season and serve with calamansi.'],
    ['general', 'balanced'], [],
    'Sodium from ~1.5 tsp fish sauce per serving; reduce fish sauce to lower it.'],
  ['chicken_tinola_meal', 'Chicken tinola with rice', 'Ginger chicken soup with sayote and malunggay over rice.', 'Filipino', ['lunch', 'dinner'], 4, 45, 1,
    28, 47, 10, 2.6, 780,
    [['Chicken pieces', 500], ['Sayote or green papaya', 300], ['Malunggay leaves', 40], ['Ginger, garlic, onion', 60], ['Fish sauce', 20], ['Rice, cooked', 632, '158 g per serving']],
    ['Sauté aromatics, brown chicken lightly.', 'Add water, simmer 25 minutes; add sayote then malunggay.', 'Serve each bowl with 1 cup rice.'],
    ['general', 'balanced', 'whole_food'], [],
    'Nutrition per serving includes 1 cup white rice.'],
  ['chicken_adobo_meal', 'Chicken adobo with rice and greens', 'Braised soy-vinegar chicken with steamed rice and sautéed kangkong.', 'Filipino', ['lunch', 'dinner'], 4, 50, 1,
    35, 49, 17, 2.4, 950,
    [['Chicken adobo', 225], ['Rice, cooked', 158], ['Kangkong, sautéed', 80, null, ['Spinach']]],
    ['Braise chicken in soy-vinegar sauce 35 minutes.', 'Serve with rice and quickly sautéed greens.'],
    ['general', 'balanced', 'high_protein'], ['soy'],
    'Sodium mostly from soy sauce; use low-sodium soy sauce to reduce it.'],
  ['pork_sinigang_meal', 'Pork sinigang with rice', 'Sour tamarind soup loaded with vegetables, with a cup of rice.', 'Filipino', ['lunch', 'dinner'], 4, 55, 2,
    24, 51, 12, 4.2, 880,
    [['Pork sinigang', 350], ['Rice, cooked', 158]],
    ['Simmer pork until tender; add tamarind base and vegetables.', 'Serve hot with rice.'],
    ['general', 'balanced', 'whole_food'], [],
    'Per-serving values include broth and 1 cup rice.'],
  ['ginisang_monggo_meal', 'Monggo stew with brown rice', 'Hearty mung bean stew with malunggay over brown rice.', 'Filipino', ['lunch', 'dinner'], 4, 45, 1,
    17, 62, 8, 10.4, 620,
    [['Ginisang monggo', 240], ['Brown rice, cooked', 195]],
    ['Simmer mung beans until soft; sauté aromatics and combine.', 'Serve over brown rice.'],
    ['vegan', 'vegetarian', 'high_fiber', 'whole_food', 'balanced', 'general'], [],
    'Plant version without pork or shrimp; add them separately if desired.'],
  ['pinakbet_rice_meal', 'Pinakbet with brown rice', 'Sautéed native vegetables with miso, over brown rice.', 'Filipino', ['lunch', 'dinner'], 2, 30, 1,
    9, 55, 8, 8.2, 720,
    [['Pinakbet (vegetable version)', 200], ['Brown rice, cooked', 195]],
    ['Sauté vegetables with tomato and miso.', 'Serve with brown rice.'],
    ['vegan', 'vegetarian', 'high_fiber', 'whole_food', 'general'], ['soy'],
    'Traditional bagoong versions are higher in sodium and not vegetarian.'],
  ['grilled_bangus_meal', 'Inihaw na bangus with rice and eggplant salad', 'Grilled milkfish with rice and ensaladang talong.', 'Filipino', ['lunch', 'dinner'], 2, 35, 2,
    32, 46, 12, 3.4, 640,
    [['Milkfish (bangus)', 150], ['Rice, cooked', 158], ['Eggplant', 100], ['Tomato and onion', 80], ['Vinegar dressing', 15]],
    ['Grill bangus until cooked through.', 'Grill eggplant; toss with tomato, onion and vinegar.', 'Serve with rice.'],
    ['pescatarian', 'balanced', 'whole_food', 'dash', 'general'], ['fish'], null],
  ['baked_tilapia_plate', 'Baked tilapia with vegetables', 'Herb-baked tilapia with broccoli and roasted squash — naturally low in sodium.', 'General', ['dinner'], 2, 30, 2,
    30, 14, 9, 5.4, 220,
    [['Tilapia fillet', 110], ['Broccoli', 156], ['Squash (kalabasa)', 150], ['Olive oil', 7], ['Lemon and herbs', 10]],
    ['Season fish with herbs and lemon; bake 15 minutes.', 'Roast vegetables tossed in oil alongside.'],
    ['pescatarian', 'low_carb', 'keto', 'dash', 'low_sodium', 'high_protein', 'whole_food'], ['fish'], null],
  ['med_lentil_soup', 'Mediterranean lentil soup', 'Lentils simmered with tomato, carrot and olive oil; finished with lemon.', 'Mediterranean', ['lunch', 'dinner'], 4, 40, 1,
    15, 42, 9, 9.6, 380,
    [['Lentils, dry', 80], ['Tomato', 120], ['Carrot', 60], ['Onion and garlic', 50], ['Olive oil', 10], ['Lemon', 15]],
    ['Sauté vegetables in oil; add lentils and water.', 'Simmer 30 minutes; season and finish with lemon.'],
    ['vegan', 'vegetarian', 'mediterranean', 'high_fiber', 'dash', 'low_sodium', 'balanced', 'general'], [], null],
  ['chickpea_salad_bowl', 'Chickpea and vegetable salad', 'Chickpeas, tomato, cabbage and olive-oil lemon dressing.', 'Mediterranean', ['lunch'], 1, 15, 1,
    13, 44, 15, 11.0, 340,
    [['Chickpeas, cooked', 164], ['Tomato', 100], ['Cabbage', 60], ['Olive oil', 12], ['Lemon juice', 15]],
    ['Toss everything with the dressing.', 'Rest 5 minutes before serving.'],
    ['vegan', 'vegetarian', 'mediterranean', 'high_fiber', 'dash', 'low_sodium', 'whole_food', 'general'], [], null],
  ['grilled_chicken_salad', 'Grilled chicken salad', 'Chicken breast over greens with olive-oil dressing.', 'General', ['lunch', 'dinner'], 1, 20, 2,
    36, 9, 21, 3.2, 320,
    [['Chicken breast', 120], ['Lettuce and spinach', 80], ['Tomato', 80], ['Olive oil', 14], ['Vinegar', 10]],
    ['Grill seasoned chicken; slice.', 'Toss greens with dressing; top with chicken.'],
    ['high_protein', 'low_carb', 'keto', 'balanced', 'whole_food', 'general'], [], null],
  ['salmon_quinoa_plate', 'Baked salmon with quinoa and greens', 'Omega-3 rich salmon with fluffy quinoa and sautéed spinach.', 'Mediterranean', ['dinner'], 1, 30, 3,
    34, 25, 22, 4.6, 300,
    [['Salmon fillet', 125], ['Quinoa, cooked', 185], ['Spinach', 80], ['Olive oil', 7], ['Lemon', 15]],
    ['Bake salmon 12–14 minutes.', 'Serve over quinoa with sautéed spinach.'],
    ['pescatarian', 'mediterranean', 'high_protein', 'dash', 'balanced', 'general'], ['fish'], null],
  ['beef_stirfry_rice', 'Lean beef stir-fry with rice', 'Beef strips with broccoli and carrots over steamed rice.', 'Asian', ['dinner'], 2, 25, 2,
    31, 51, 15, 3.8, 750,
    [['Ground or sliced beef, lean', 120], ['Broccoli', 120], ['Carrot', 60], ['Rice, cooked', 158], ['Soy sauce', 12], ['Oil', 7]],
    ['Sear beef; remove.', 'Stir-fry vegetables, return beef with sauce; serve over rice.'],
    ['high_protein', 'balanced', 'general'], ['soy'], null],
  ['tofu_veggie_stirfry', 'Tofu vegetable stir-fry with rice', 'Crispy tofu with cabbage, carrots and green beans over rice.', 'Asian', ['lunch', 'dinner'], 2, 25, 1,
    20, 52, 14, 5.6, 620,
    [['Firm tofu', 150], ['Cabbage', 80], ['Carrot', 60], ['Green beans', 80], ['Rice, cooked', 158], ['Soy sauce', 10], ['Oil', 8]],
    ['Pan-fry tofu cubes until golden.', 'Stir-fry vegetables; combine with sauce and serve over rice.'],
    ['vegan', 'vegetarian', 'balanced', 'high_fiber', 'general'], ['soy'], null],
  ['keto_chicken_plate', 'Chicken thigh with buttered broccoli', 'Roasted chicken thigh with broccoli in butter and cauliflower rice.', 'General', ['dinner'], 1, 30, 2,
    35, 10, 34, 5.2, 420,
    [['Chicken thigh', 135], ['Broccoli', 156], ['Cauliflower rice', 100], ['Butter', 14]],
    ['Roast chicken thigh until crisp.', 'Steam broccoli and cauliflower rice; toss with butter.'],
    ['keto', 'low_carb', 'high_protein', 'general'], ['milk'], null],
  ['avocado_egg_plate', 'Avocado and egg plate', 'Boiled eggs with half an avocado, tomato and olive oil.', 'General', ['breakfast', 'snack'], 1, 10, 2,
    16, 12, 30, 8.0, 260,
    [['Eggs', 100], ['Avocado', 100], ['Tomato', 80], ['Olive oil', 5]],
    ['Boil eggs to your liking.', 'Plate with sliced avocado and tomato; drizzle oil.'],
    ['keto', 'low_carb', 'vegetarian', 'whole_food', 'general'], ['egg'], null],
  ['pancit_bihon_meal', 'Pancit bihon', 'Filipino rice-noodle stir-fry with chicken and vegetables.', 'Filipino', ['lunch', 'dinner'], 4, 35, 1,
    15, 45, 10, 3.5, 1030,
    [['Pancit bihon with chicken and vegetables', 250]],
    ['Soak noodles; stir-fry chicken and vegetables.', 'Add noodles and sauce; toss until absorbed.'],
    ['general', 'balanced'], ['soy'],
    'Sodium from soy sauce; use low-sodium soy sauce to reduce it.'],
  ['fruit_nut_plate', 'Fruit and nut plate', 'Seasonal fruit with a small handful of almonds.', 'General', ['snack'], 1, 5, 1,
    7, 38, 15, 7.6, 5,
    [['Apple or mango', 182], ['Almonds', 28]],
    ['Slice fruit; serve with almonds.'],
    ['vegan', 'vegetarian', 'mediterranean', 'whole_food', 'high_fiber', 'low_sodium', 'dash', 'general', 'balanced'], ['tree nut'], null],
  ['veggie_hummus_snack', 'Vegetable sticks with hummus', 'Carrot and cucumber sticks with creamy hummus.', 'Mediterranean', ['snack'], 1, 8, 1,
    9, 22, 10, 8.0, 420,
    [['Hummus', 60], ['Carrot', 122], ['Cucumber', 100]],
    ['Cut vegetables into sticks; serve with hummus.'],
    ['vegan', 'vegetarian', 'mediterranean', 'dash', 'high_fiber', 'general', 'balanced'], ['sesame'], null],
  ['cottage_cheese_snack', 'Cottage cheese with tomato', 'Savory high-protein snack with cracked pepper.', 'General', ['snack'], 1, 3, 1,
    14, 9, 3, 1.2, 400,
    [['Cottage cheese', 113], ['Tomato', 123], ['Black pepper', 1]],
    ['Combine and season.'],
    ['vegetarian', 'high_protein', 'keto', 'low_carb', 'general', 'balanced'], ['milk'], null],
  ['boiled_eggs_snack', 'Two boiled eggs', 'Simple protein snack, good warm or cold.', 'General', ['snack'], 1, 12, 1,
    13, 1, 11, 0, 250,
    [['Eggs', 100]],
    ['Boil eggs 7–10 minutes; cool in cold water.'],
    ['keto', 'low_carb', 'high_protein', 'vegetarian', 'whole_food', 'general', 'balanced', 'low_sodium'], ['egg'], null],
  ['banana_oat_pancakes', 'Banana oat pancakes', 'Three-ingredient pancakes from oats, banana and eggs.', 'General', ['breakfast'], 2, 20, 1,
    14, 45, 12, 5.6, 190,
    [['Rolled oats', 60], ['Banana', 118], ['Eggs', 100], ['Oil for the pan', 5]],
    ['Blend all ingredients into a batter.', 'Cook small pancakes 2 minutes per side.'],
    ['vegetarian', 'balanced', 'high_fiber', 'whole_food', 'low_sodium', 'general'], ['egg', 'gluten'], null],
];

const groceryCategories = {
  'Rolled oats': 'Grains & bread', 'Banana': 'Produce', 'Peanut butter': 'Pantry',
  'Water or unsweetened soy milk': 'Dairy & alternatives', 'Eggs': 'Dairy & eggs',
  'Spinach': 'Produce', 'Tomato': 'Produce', 'Cheddar cheese': 'Dairy & eggs',
  'Olive oil': 'Pantry', 'Greek yogurt, plain': 'Dairy & eggs', 'Mango': 'Produce',
  'Almonds': 'Pantry', 'Honey (optional)': 'Pantry', 'Firm tofu': 'Chilled',
  'Spinach or kangkong': 'Produce', 'Turmeric and pepper': 'Pantry',
  'Whole-wheat bread': 'Grains & bread', 'Oregano': 'Pantry',
  'Sinangag (garlic fried rice)': 'Prepared', 'Egg': 'Dairy & eggs',
  'Oil for frying': 'Pantry', 'Rice': 'Grains & bread', 'Chicken thigh': 'Meat & fish',
  'Ginger, garlic, onion': 'Produce', 'Fish sauce': 'Pantry', 'Calamansi': 'Produce',
  'Chicken pieces': 'Meat & fish', 'Sayote or green papaya': 'Produce',
  'Malunggay leaves': 'Produce', 'Rice, cooked': 'Grains & bread',
  'Chicken adobo': 'Prepared', 'Kangkong, sautéed': 'Produce',
  'Pork sinigang': 'Prepared', 'Ginisang monggo': 'Prepared',
  'Brown rice, cooked': 'Grains & bread', 'Pinakbet (vegetable version)': 'Prepared',
  'Milkfish (bangus)': 'Meat & fish', 'Eggplant': 'Produce',
  'Tomato and onion': 'Produce', 'Vinegar dressing': 'Pantry',
  'Tilapia fillet': 'Meat & fish', 'Broccoli': 'Produce',
  'Squash (kalabasa)': 'Produce', 'Lemon and herbs': 'Produce',
  'Lentils, dry': 'Pantry', 'Onion and garlic': 'Produce', 'Lemon': 'Produce',
  'Chickpeas, cooked': 'Pantry', 'Cabbage': 'Produce', 'Lemon juice': 'Produce',
  'Chicken breast': 'Meat & fish', 'Lettuce and spinach': 'Produce',
  'Vinegar': 'Pantry', 'Salmon fillet': 'Meat & fish', 'Quinoa, cooked': 'Grains & bread',
  'Ground or sliced beef, lean': 'Meat & fish', 'Carrot': 'Produce',
  'Soy sauce': 'Pantry', 'Oil': 'Pantry', 'Green beans': 'Produce',
  'Cauliflower rice': 'Produce', 'Butter': 'Dairy & eggs', 'Avocado': 'Produce',
  'Pancit bihon with chicken and vegetables': 'Prepared',
  'Apple or mango': 'Produce', 'Hummus': 'Chilled', 'Cucumber': 'Produce',
  'Black pepper': 'Pantry', 'Oil for the pan': 'Pantry',
};

const recipesOut = recipes.map(([id, name, description, cuisine, slots, servings, prepMinutes, costTier, p, c, f, fiber, sodium, ingredients, steps, tags, allergens, assumptions]) => ({
  id, name, description, cuisine, slots, servings, prepMinutes, costTier,
  perServing: { kcal: Math.round(atwater(p, c, f)), proteinG: p, carbsG: c, fatG: f, fiberG: fiber, sodiumMg: sodium },
  ingredients: ingredients.map(([iname, grams, note, substitutes]) => ({ name: iname, grams, note: note ?? null, substitutes: substitutes ?? [] })),
  steps,
  source: 'recipeEstimate',
  sourceRef: 'NutriGuide curated dataset v1',
  tags, allergens,
  assumptions: assumptions ?? 'Estimated from the listed ingredient weights using USDA per-100 g values.',
  groceryCategory: Object.fromEntries(ingredients.map(([iname]) => [iname, groceryCategories[iname] ?? 'Other'])),
}));

writeFileSync(join(outDir, 'foods.json'), JSON.stringify({ version: 'seed-v1', items: foods }, null, 1));
writeFileSync(join(outDir, 'recipes.json'), JSON.stringify({ version: 'seed-v1', items: recipesOut }, null, 1));
console.log(`Wrote ${foods.length} foods and ${recipesOut.length} recipes.`);
