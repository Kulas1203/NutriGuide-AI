import { describe, expect, it } from 'vitest';
import { isAcceptable, MealPlan, validatePlan } from './validatePlan';

function plan(overrides: Partial<MealPlan> = {}): MealPlan {
  return {
    calorieTarget: 1800,
    days: [
      {
        dayKey: '2026-07-21',
        meals: [
          {
            recipeId: 'a',
            recipeName: 'A',
            servings: 1,
            perServing: { kcal: 600, proteinG: 30, carbsG: 60, fatG: 20 },
          },
          {
            recipeId: 'b',
            recipeName: 'B',
            servings: 1,
            perServing: { kcal: 600, proteinG: 30, carbsG: 60, fatG: 20 },
          },
          {
            recipeId: 'c',
            recipeName: 'C',
            servings: 1,
            perServing: { kcal: 600, proteinG: 30, carbsG: 60, fatG: 20 },
          },
        ],
      },
    ],
    ...overrides,
  };
}

describe('server validatePlan', () => {
  it('accepts a well-formed plan', () => {
    const issues = validatePlan(plan(), [], {});
    expect(isAcceptable(issues)).toBe(true);
  });

  it('rejects impossible servings', () => {
    const p = plan();
    p.days[0].meals[0].servings = 9;
    const issues = validatePlan(p, [], {});
    expect(issues.some((i) => i.code === 'bad_servings' && i.blocking)).toBe(true);
  });

  it('rejects energy inconsistent with macros', () => {
    const p = plan();
    p.days[0].meals[0].perServing = { kcal: 2000, proteinG: 5, carbsG: 5, fatG: 5 };
    const issues = validatePlan(p, [], {});
    expect(issues.some((i) => i.code === 'inconsistent_energy')).toBe(true);
  });

  it('flags allergen violations as blocking', () => {
    const issues = validatePlan(plan(), ['peanut'], { a: ['peanut'] });
    expect(
      issues.some((i) => i.code === 'allergen_violation' && i.blocking)
    ).toBe(true);
    expect(isAcceptable(issues)).toBe(false);
  });

  it('treats calorie deviation as advisory', () => {
    const p = plan({ calorieTarget: 4000 });
    const issues = validatePlan(p, [], {});
    const dev = issues.find((i) => i.code === 'calorie_deviation');
    expect(dev?.blocking).toBe(false);
    expect(isAcceptable(issues)).toBe(true);
  });
});
