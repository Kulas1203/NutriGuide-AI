import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide_ai/features/coach/domain/chat_message.dart';
import 'package:nutriguide_ai/features/diets/domain/diet_catalog.dart';
import 'package:nutriguide_ai/features/diets/domain/diet_program.dart';
import 'package:nutriguide_ai/features/logging/domain/diary_entry.dart';
import 'package:nutriguide_ai/features/logging/domain/food_item.dart';
import 'package:nutriguide_ai/features/planner/domain/recipe.dart';
import 'package:nutriguide_ai/features/profile/domain/user_profile.dart';

void main() {
  group('DietCatalog integrity', () {
    test('contains all 18 required approaches', () {
      expect(DietCatalog.all.length, 18);
    });

    test('every diet has evidence, limitations and content', () {
      for (final d in DietCatalog.all) {
        expect(d.evidence, isNotEmpty, reason: '${d.id} needs evidence');
        expect(d.limitations, isNotEmpty, reason: '${d.id} needs limitations');
        expect(d.benefits, isNotEmpty);
        expect(d.sampleDay, isNotEmpty);
        expect(d.sustainability, inInclusiveRange(1, 5));
        expect(d.difficulty, inInclusiveRange(1, 5));
        expect(d.recipeTags, isNotEmpty);
      }
    });

    test('macro splits, when present, sum to 100%', () {
      for (final d in DietCatalog.all) {
        final split = d.macroSplit;
        if (split != null) {
          expect(split.isValid, isTrue, reason: '${d.id} split must total 100');
        }
      }
    });

    test('vegan diet only references vegan-safe recipe tags', () {
      final vegan = DietCatalog.byId('vegan');
      expect(vegan.recipeTags, everyElement(equals('vegan')));
    });

    test('byId falls back to the first diet for unknown ids', () {
      expect(DietCatalog.byId('does-not-exist').id, DietCatalog.all.first.id);
    });

    test('fasting schedules are gentle (≤16h) and well-formed', () {
      for (final s in supportedFastingSchedules) {
        expect(s.fastingHours + s.eatingHours, 24);
        expect(s.fastingHours, lessThanOrEqualTo(16));
      }
    });
  });

  group('Serialization round-trips', () {
    test('UserProfile', () {
      final p = UserProfile(
        id: 'u',
        displayName: 'Rey',
        isAdultConfirmed: true,
        country: 'PH',
        language: 'en',
        metricUnits: true,
        heightCm: 170,
        weightKg: 70,
        age: 30,
        sex: BiologicalSex.male,
        activityLevel: ActivityLevel.moderate,
        goal: WellnessGoal.loseWeight,
        dietId: 'mediterranean',
        allergies: const ['peanut'],
        avoidFoods: const ['pork'],
        mealsPerDay: 3,
        cookingTime: CookingTime.quick,
        budget: BudgetPreference.low,
        consentVersion: 'v1',
        disclaimerAcknowledgedAt: DateTime(2026, 7, 21),
        healthFlags: const [HealthFlag.diabetesOnMedication],
        aiHistoryEnabled: false,
      );
      final restored = UserProfile.fromJson(p.toJson());
      expect(restored.displayName, 'Rey');
      expect(restored.allergies, ['peanut']);
      expect(restored.healthFlags, [HealthFlag.diabetesOnMedication]);
      expect(restored.requiresProfessionalGuidance, isTrue);
      expect(restored.aiHistoryEnabled, isFalse);
    });

    test('Nutrients arithmetic and JSON', () {
      const a = Nutrients(
        kcal: 100,
        proteinG: 10,
        carbsG: 5,
        fatG: 2,
        fiberG: 1,
      );
      final scaled = a.scale(2);
      expect(scaled.kcal, 200);
      final sum = a + scaled;
      expect(sum.kcal, 300);
      expect(Nutrients.fromJson(a.toJson()).proteinG, 10);
    });

    test('DiaryEntry', () {
      final e = DiaryEntry(
        id: 'd',
        dayKey: '2026-07-21',
        slot: MealSlot.lunch,
        name: 'Rice',
        grams: 158,
        nutrients: const Nutrients(kcal: 205, proteinG: 4, carbsG: 45, fatG: 0),
        source: NutritionSource.verified,
        loggedAt: DateTime(2026, 7, 21, 12),
      );
      final restored = DiaryEntry.fromJson(e.toJson());
      expect(restored.name, 'Rice');
      expect(restored.slot, MealSlot.lunch);
      expect(restored.source, NutritionSource.verified);
    });

    test('ChatMessage with structured fields', () {
      final m = ChatMessage(
        id: 'm',
        role: ChatRole.coach,
        text: 'Answer',
        createdAt: DateTime(2026, 7, 21),
        explanation: 'because',
        nextSteps: const ['do this'],
        limitations: 'general only',
        sources: const [AnswerSource(title: 'T', source: 'S', date: '2020')],
        confidence: 'established',
        professionalReferral: true,
      );
      final restored = ChatMessage.fromJson(m.toJson());
      expect(restored.text, 'Answer');
      expect(restored.nextSteps, ['do this']);
      expect(restored.sources.first.title, 'T');
      expect(restored.confidence, 'established');
      expect(restored.professionalReferral, isTrue);
    });
  });
}
