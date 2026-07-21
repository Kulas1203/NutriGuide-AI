/**
 * Server-side meal-plan validation, mirroring the Flutter client
 * (app/lib/features/planner/domain/plan_validator.dart). Plans that sync are
 * re-validated here so a compromised or buggy client cannot persist an
 * impossible or allergen-violating plan.
 */

export interface PlanNutrients {
  kcal: number;
  proteinG: number;
  carbsG: number;
  fatG: number;
}

export interface PlanMeal {
  recipeId: string;
  recipeName: string;
  servings: number;
  perServing: PlanNutrients;
}

export interface DayPlan {
  dayKey: string;
  meals: PlanMeal[];
}

export interface MealPlan {
  calorieTarget: number;
  days: DayPlan[];
}

export interface PlanIssue {
  code: string;
  message: string;
  blocking: boolean;
}

export const CALORIE_TOLERANCE = 0.2;
const MIN_SERVINGS = 0.5;
const MAX_SERVINGS = 3.0;

export function validatePlan(
  plan: MealPlan,
  allergies: string[],
  recipeAllergens: Record<string, string[]>
): PlanIssue[] {
  const issues: PlanIssue[] = [];
  const allergySet = new Set(allergies.map((a) => a.toLowerCase()));

  if (!plan.days || plan.days.length === 0) {
    issues.push({ code: 'empty_plan', message: 'Plan has no days.', blocking: true });
    return issues;
  }

  for (const day of plan.days) {
    if (!day.meals || day.meals.length === 0) {
      issues.push({
        code: 'empty_day',
        message: `Day ${day.dayKey} has no meals.`,
        blocking: true,
      });
      continue;
    }
    for (const meal of day.meals) {
      if (meal.servings < MIN_SERVINGS || meal.servings > MAX_SERVINGS) {
        issues.push({
          code: 'bad_servings',
          message: `${meal.recipeName}: impossible serving quantity.`,
          blocking: true,
        });
      }
      const n = meal.perServing;
      if (n.kcal <= 0 || n.proteinG < 0 || n.carbsG < 0 || n.fatG < 0) {
        issues.push({
          code: 'bad_nutrition',
          message: `${meal.recipeName}: invalid nutrition values.`,
          blocking: true,
        });
      }
      const atwater = n.proteinG * 4 + n.carbsG * 4 + n.fatG * 9;
      if (atwater > 0 && Math.abs(n.kcal - atwater) / atwater > 0.25) {
        issues.push({
          code: 'inconsistent_energy',
          message: `${meal.recipeName}: calories do not match macronutrients.`,
          blocking: true,
        });
      }
      const allergens = recipeAllergens[meal.recipeId] ?? [];
      for (const a of allergens) {
        if (allergySet.has(a.toLowerCase())) {
          issues.push({
            code: 'allergen_violation',
            message: `${meal.recipeName} contains ${a}, which is in the allergy list.`,
            blocking: true,
          });
        }
      }
    }
    const total = day.meals.reduce(
      (sum, m) => sum + m.perServing.kcal * m.servings,
      0
    );
    const deviation = Math.abs(total - plan.calorieTarget) / plan.calorieTarget;
    if (deviation > CALORIE_TOLERANCE) {
      issues.push({
        code: 'calorie_deviation',
        message: `Day ${day.dayKey} deviates more than ${CALORIE_TOLERANCE * 100}% from target.`,
        blocking: false,
      });
    }
  }
  return issues;
}

export function isAcceptable(issues: PlanIssue[]): boolean {
  return issues.every((i) => !i.blocking);
}
