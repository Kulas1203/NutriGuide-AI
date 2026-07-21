import 'dart:async';

import '../../../core/config/env.dart';
import '../domain/chat_message.dart';
import 'coach_service.dart';

/// Development-only coach that produces grounded, honest educational answers
/// from a small curated knowledge base — with NO model vendor involved.
///
/// It exists so the full chat experience (streaming, sources, confidence,
/// safety framing) can be exercised without backend credentials. Every
/// answer is clearly labeled a development stub ([ChatMessage.isStub]) and
/// this class throws if constructed outside a dev build. It never fabricates
/// numbers: when a question isn't in the knowledge base it says so and points
/// to the real backend, rather than inventing an answer.
class DevCoachService implements CoachService {
  DevCoachService() {
    if (!AppEnvironment.useDevStub) {
      throw StateError(
        'DevCoachService must never be constructed outside dev builds.',
      );
    }
  }

  @override
  Stream<CoachChunk> ask({
    required String question,
    required CoachContext context,
    required List<ChatMessage> history,
    required String? authToken,
  }) async* {
    final answer = _answerFor(question, context);
    // Stream the direct answer word-by-word to mimic real streaming.
    final words = answer.text.split(' ');
    final buffer = StringBuffer();
    for (final word in words) {
      buffer.write('$word ');
      await Future<void>.delayed(const Duration(milliseconds: 12));
      yield CoachChunk.delta(buffer.toString().trimRight());
    }
    yield CoachChunk.result(answer);
  }

  ChatMessage _answerFor(String question, CoachContext context) {
    final q = question.toLowerCase();
    final now = DateTime.now();
    final base = _knowledge.firstWhere(
      (k) => k.triggers.any(q.contains),
      orElse: () => _fallback,
    );

    final referral = context.requiresProfessionalGuidance;
    return ChatMessage(
      id: 'stub_${now.microsecondsSinceEpoch}',
      role: ChatRole.coach,
      text: base.answer,
      createdAt: now,
      status: MessageStatus.complete,
      explanation: base.explanation,
      nextSteps: base.nextSteps,
      limitations: base.limitations,
      sources: base.sources,
      confidence: base.confidence,
      professionalReferral: referral || base.suggestProfessional,
      isStub: true,
    );
  }

  static const _KnowledgeItem _fallback = _KnowledgeItem(
    triggers: [],
    answer:
        "I don't have a grounded answer for that in this development build. "
        'The full AI Nutrition Coach runs on the secure backend, where it '
        'can retrieve nutrition data and cite sources. I would rather tell '
        "you I don't know than guess.",
    explanation:
        'This development stub only answers from a small built-in knowledge '
        'base so it never invents facts or numbers.',
    nextSteps: [
      'Configure the backend (see docs/SETUP.md) to enable the full coach.',
      'For anything specific to your health, consult a registered dietitian.',
    ],
    limitations:
        'Development stub — not the production AI. It cannot look things up.',
    sources: [],
    confidence: 'uncertain',
  );

  static const List<_KnowledgeItem> _knowledge = [
    _KnowledgeItem(
      triggers: ['protein', 'how much protein'],
      answer:
          'For most healthy, active adults, roughly 1.2–2.0 grams of protein '
          'per kilogram of body weight per day supports muscle maintenance '
          'and satiety.',
      explanation:
          'Protein needs rise with training and during weight loss (to '
          'protect muscle). Spreading intake across meals — about 20–40 g '
          'each — is a practical way to reach the total.',
      nextSteps: [
        'Include a protein source at each meal (eggs, fish, poultry, tofu, '
            'legumes, dairy).',
        'If you lift weights, aim toward the higher end of the range.',
      ],
      limitations:
          'People with kidney disease should get an individualized target '
          'from their care team rather than following general ranges.',
      sources: [
        AnswerSource(
          title: 'ISSN position stand: protein and exercise',
          source: 'J Int Soc Sports Nutr',
          date: '2017',
        ),
      ],
      confidence: 'established',
      suggestProfessional: false,
    ),
    _KnowledgeItem(
      triggers: ['fiber', 'fibre'],
      answer:
          'Aim for about 25–38 grams of fiber a day from vegetables, fruit, '
          'whole grains and legumes.',
      explanation:
          'Fiber supports digestion and heart health and helps you feel '
          'full. Increase it gradually and drink water to avoid discomfort.',
      nextSteps: [
        'Add a serving of beans or lentils a few times a week.',
        'Choose whole grains over refined ones where you can.',
      ],
      limitations:
          'People with IBS or IBD may need to adjust fiber type and amount '
          'with a dietitian.',
      sources: [
        AnswerSource(
          title: 'Carbohydrate quality and human health (systematic reviews)',
          source: 'The Lancet',
          date: '2019',
        ),
      ],
      confidence: 'established',
    ),
    _KnowledgeItem(
      triggers: ['water', 'hydration', 'how much water'],
      answer:
          'A common general guide is about 2–3 liters of fluid a day for '
          'adults, but needs vary with body size, activity and climate.',
      explanation:
          'Thirst and pale-yellow urine are reasonable everyday signals. '
          'Food (especially fruit and soup) also contributes fluid.',
      nextSteps: [
        'Keep water within reach and drink more around exercise and heat.',
      ],
      limitations:
          'Some heart and kidney conditions require fluid limits — follow '
          'your physician’s guidance over general advice.',
      sources: [
        AnswerSource(
          title: 'Dietary Reference Intakes for water and electrolytes',
          source: 'Institute of Medicine',
          date: '2005',
        ),
      ],
      confidence: 'general',
    ),
    _KnowledgeItem(
      triggers: ['keto', 'ketogenic', 'low carb'],
      answer:
          'Keto restricts carbohydrate to roughly 5–10% of calories so the '
          'body relies more on fat. It can help some people in the short '
          'term, but long-term results tend to match other calorie-matched '
          'diets — adherence matters most.',
      explanation:
          'Early weight loss often includes water. The diet is demanding '
          'socially and can crowd out fiber and some micronutrients.',
      nextSteps: [
        'If you try it, plan non-starchy vegetables and watch fiber, '
            'magnesium and folate.',
      ],
      limitations:
          'Not appropriate for everyone. People with diabetes on medication, '
          'or kidney/liver conditions, should get medical guidance first.',
      sources: [
        AnswerSource(
          title: 'Ketogenic diets for weight loss: network meta-analysis',
          source: 'BMJ',
          date: '2020',
        ),
      ],
      confidence: 'individual',
      suggestProfessional: true,
    ),
    _KnowledgeItem(
      triggers: ['b12', 'vegan', 'plant based', 'plant-based'],
      answer:
          'Well-planned vegan diets can be nutritionally adequate for '
          'adults, but vitamin B12 must come from fortified foods or a '
          'supplement — it is not optional.',
      explanation:
          'Also keep an eye on iron, calcium, iodine, omega-3 and getting '
          'enough protein from legumes, soy foods, nuts and seeds.',
      nextSteps: [
        'Take a reliable B12 source daily or as directed on the label.',
        'Include a variety of legumes and whole grains for protein and iron.',
      ],
      limitations:
          'Pregnancy, breastfeeding and childhood raise the stakes — get '
          'professional guidance for those situations.',
      sources: [
        AnswerSource(
          title:
              'Position of the Academy of Nutrition and Dietetics: '
              'vegetarian diets',
          source: 'J Acad Nutr Diet',
          date: '2016',
        ),
      ],
      confidence: 'established',
    ),
    _KnowledgeItem(
      triggers: [
        'calorie',
        'calories',
        'deficit',
        'lose weight',
        'weight loss',
      ],
      answer:
          'Gradual weight loss of about 0.25–0.75 kg per week, from a modest '
          'calorie reduction, is the sustainable range most guidelines '
          'support.',
      explanation:
          'Very aggressive deficits are hard to maintain and can cost muscle '
          'and energy. Protein and fiber help you stay satisfied at lower '
          'intakes.',
      nextSteps: [
        'Use your NutriGuide target as a starting estimate and adjust based '
            'on 2–3 week trends, not single days.',
      ],
      limitations:
          'NutriGuide keeps a calorie safety floor and will not plan very '
          'low intakes. For faster medically-supervised options, see a '
          'dietitian or physician.',
      sources: [
        AnswerSource(
          title: 'Obesity management clinical practice guidelines',
          source: 'AACE/ACE',
          date: '2016',
        ),
      ],
      confidence: 'general',
    ),
    _KnowledgeItem(
      triggers: ['fasting', 'intermittent', '16:8', 'time restricted'],
      answer:
          'Gentle intermittent fasting (like 16:8) limits eating to a daily '
          'window. Research suggests results are similar to ordinary calorie '
          'reduction — it is a scheduling tool, not magic.',
      explanation:
          'Some people find a shorter eating window helps them snack less. '
          'Hunger in the first couple of weeks is common.',
      nextSteps: [
        'Stay hydrated during the fast and eat balanced meals in the window.',
      ],
      limitations:
          'Not for everyone: skip fasting and seek guidance if pregnant, on '
          'diabetes medication, taking medicines that need food, or with a '
          'history of disordered eating.',
      sources: [
        AnswerSource(
          title: 'Time-restricted eating for weight loss (TREAT trial)',
          source: 'JAMA Internal Medicine',
          date: '2020',
        ),
      ],
      confidence: 'individual',
    ),
  ];
}

class _KnowledgeItem {
  const _KnowledgeItem({
    required this.triggers,
    required this.answer,
    required this.explanation,
    required this.nextSteps,
    required this.limitations,
    required this.sources,
    required this.confidence,
    this.suggestProfessional = false,
  });

  final List<String> triggers;
  final String answer;
  final String explanation;
  final List<String> nextSteps;
  final String limitations;
  final List<AnswerSource> sources;
  final String confidence;
  final bool suggestProfessional;
}
