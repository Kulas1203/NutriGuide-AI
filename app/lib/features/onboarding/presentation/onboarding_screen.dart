import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/design/components.dart';
import '../../../core/design/tokens.dart';
import '../../../core/utils/units.dart';
import '../../auth/application/session_controller.dart';
import '../../diets/domain/diet_catalog.dart';
import '../../legal/consent.dart';
import '../../profile/application/profile_controller.dart';
import '../../profile/domain/user_profile.dart';

/// Draft state accumulated across onboarding steps.
class _Draft {
  String name = '';
  bool adult = false;
  String country = '';
  String language = 'English';
  bool metric = true;
  double heightCm = 168;
  double weightKg = 68;
  int age = 30;
  BiologicalSex sex = BiologicalSex.unspecified;
  ActivityLevel activity = ActivityLevel.light;
  WellnessGoal goal = WellnessGoal.maintain;
  String dietId = 'balanced';
  final Set<String> allergies = {};
  final List<String> avoid = [];
  int mealsPerDay = 3;
  CookingTime cookingTime = CookingTime.moderate;
  BudgetPreference budget = BudgetPreference.medium;
  final List<String> cuisines = [];
  final Set<HealthFlag> healthFlags = {};
  bool disclaimerAck = false;
  bool dataAck = false;
}

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _draft = _Draft();
  final _controller = PageController();
  int _step = 0;
  bool _saving = false;

  late final List<_Step> _steps = [
    _Step('Welcome', _welcome),
    _Step('About you', _aboutYou),
    _Step('Your body', _body),
    _Step('Activity & goal', _activityGoal),
    _Step('Diet style', _dietStyle),
    _Step('Allergies & foods', _allergies),
    _Step('Cooking & budget', _cooking),
    _Step('Health check', _health),
    _Step('Your agreement', _consent),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _canAdvance => switch (_step) {
    1 => _draft.name.trim().isNotEmpty && _draft.adult,
    8 => _draft.disclaimerAck && _draft.dataAck,
    _ => true,
  };

  void _next() {
    if (_step < _steps.length - 1) {
      setState(() => _step++);
      _controller.animateToPage(
        _step,
        duration: NGMotion.of(context, NGMotion.normal),
        curve: NGMotion.standard,
      );
    } else {
      _finish();
    }
  }

  void _back() {
    if (_step == 0) return;
    setState(() => _step--);
    _controller.animateToPage(
      _step,
      duration: NGMotion.of(context, NGMotion.normal),
      curve: NGMotion.standard,
    );
  }

  Future<void> _finish() async {
    setState(() => _saving = true);
    final user = ref.read(sessionControllerProvider).user;
    final profile = UserProfile(
      id: user?.uid ?? const Uuid().v4(),
      displayName: _draft.name.trim(),
      isAdultConfirmed: _draft.adult,
      country: _draft.country.trim(),
      language: _draft.language,
      metricUnits: _draft.metric,
      heightCm: _draft.heightCm,
      weightKg: _draft.weightKg,
      age: _draft.age,
      sex: _draft.sex,
      activityLevel: _draft.activity,
      goal: _draft.goal,
      dietId: _draft.dietId,
      allergies: _draft.allergies.toList(),
      avoidFoods: _draft.avoid,
      mealsPerDay: _draft.mealsPerDay,
      cookingTime: _draft.cookingTime,
      budget: _draft.budget,
      consentVersion: Consent.consentVersion,
      disclaimerAcknowledgedAt: DateTime.now(),
      preferredCuisines: _draft.cuisines,
      healthFlags: _draft.healthFlags.toList(),
      aiHistoryEnabled: true,
    );
    await ref.read(profileControllerProvider.notifier).saveProfile(profile);
    if (!mounted) return;
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                NGSpacing.lg,
                NGSpacing.lg,
                NGSpacing.lg,
                NGSpacing.sm,
              ),
              child: Row(
                children: [
                  if (_step > 0)
                    IconButton(
                      onPressed: _saving ? null : _back,
                      icon: const Icon(Icons.arrow_back_rounded),
                      tooltip: 'Back',
                    )
                  else
                    const SizedBox(width: 48),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: NGRadius.chip,
                      child: LinearProgressIndicator(
                        value: (_step + 1) / _steps.length,
                        minHeight: 6,
                      ),
                    ),
                  ),
                  const SizedBox(width: NGSpacing.md),
                  Text(
                    '${_step + 1}/${_steps.length}',
                    style: theme.textTheme.labelMedium,
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _steps.length,
                itemBuilder: (context, i) => SingleChildScrollView(
                  padding: const EdgeInsets.all(NGSpacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        _steps[i].title,
                        style: theme.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: NGSpacing.lg),
                      _steps[i].builder(),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(NGSpacing.lg),
              child: FilledButton(
                onPressed: (_canAdvance && !_saving) ? _next : null,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        _step == _steps.length - 1
                            ? 'Finish setup'
                            : 'Continue',
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Step builders ---

  Widget _welcome() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Let’s set up a plan that fits your life. This takes about two '
          'minutes, and you can change anything later.',
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: NGSpacing.lg),
        const NoticeBanner(
          severity: NoticeSeverity.info,
          title: 'What NutriGuide is',
          message: Consent.productStatement,
        ),
        const SizedBox(height: NGSpacing.md),
        _bullet(
          Icons.lock_outline_rounded,
          'Your information stays private and is never sold or used for ads.',
        ),
        _bullet(
          Icons.tune_rounded,
          'We only ask for what a feature genuinely needs. Optional questions are clearly marked.',
        ),
        _bullet(
          Icons.medical_information_outlined,
          'For anything medical, we’ll always point you to a qualified professional.',
        ),
      ],
    );
  }

  Widget _aboutYou() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          decoration: const InputDecoration(
            labelText: 'Preferred name',
            hintText: 'What should we call you?',
          ),
          onChanged: (v) => setState(() => _draft.name = v),
        ),
        const SizedBox(height: NGSpacing.md),
        TextField(
          decoration: const InputDecoration(labelText: 'Country (optional)'),
          onChanged: (v) => _draft.country = v,
        ),
        const SizedBox(height: NGSpacing.lg),
        CheckboxListTile(
          value: _draft.adult,
          onChanged: (v) => setState(() => _draft.adult = v ?? false),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          title: const Text(Consent.adultConfirmation),
          subtitle: const Text(
            'NutriGuide is designed for adults. This first version is not '
            'intended for anyone under 18.',
          ),
        ),
      ],
    );
  }

  Widget _body() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: true, label: Text('Metric')),
            ButtonSegment(value: false, label: Text('Imperial')),
          ],
          selected: {_draft.metric},
          onSelectionChanged: (s) => setState(() => _draft.metric = s.first),
        ),
        const SizedBox(height: NGSpacing.xl),
        _sliderRow(
          label: 'Height',
          value: Units.formatHeight(_draft.heightCm, metric: _draft.metric),
          slider: Slider(
            value: _draft.heightCm,
            min: 130,
            max: 210,
            onChanged: (v) => setState(() => _draft.heightCm = v),
          ),
        ),
        _sliderRow(
          label: 'Current weight',
          value: Units.formatWeight(_draft.weightKg, metric: _draft.metric),
          slider: Slider(
            value: _draft.weightKg,
            min: 35,
            max: 200,
            onChanged: (v) => setState(() => _draft.weightKg = v),
          ),
        ),
        _sliderRow(
          label: 'Age',
          value: '${_draft.age} years',
          slider: Slider(
            value: _draft.age.toDouble(),
            min: 18,
            max: 90,
            onChanged: (v) => setState(() => _draft.age = v.round()),
          ),
        ),
        const SizedBox(height: NGSpacing.md),
        Text(
          'Sex (used only for energy estimation)',
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: NGSpacing.sm),
        Wrap(
          spacing: NGSpacing.sm,
          children: [
            for (final s in BiologicalSex.values)
              ChoiceChip(
                label: Text(s.label),
                selected: _draft.sex == s,
                onSelected: (_) => setState(() => _draft.sex = s),
              ),
          ],
        ),
      ],
    );
  }

  Widget _activityGoal() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Activity level', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: NGSpacing.sm),
        RadioGroup<ActivityLevel>(
          groupValue: _draft.activity,
          onChanged: (v) => setState(() => _draft.activity = v!),
          child: Column(
            children: [
              for (final a in ActivityLevel.values)
                RadioListTile<ActivityLevel>(
                  value: a,
                  contentPadding: EdgeInsets.zero,
                  title: Text(a.label),
                  subtitle: Text(a.description),
                ),
            ],
          ),
        ),
        const SizedBox(height: NGSpacing.lg),
        Text('Primary goal', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: NGSpacing.sm),
        Wrap(
          spacing: NGSpacing.sm,
          runSpacing: NGSpacing.sm,
          children: [
            for (final g in WellnessGoal.values)
              ChoiceChip(
                label: Text(g.label),
                selected: _draft.goal == g,
                onSelected: (_) => setState(() => _draft.goal = g),
              ),
          ],
        ),
      ],
    );
  }

  Widget _dietStyle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pick a starting point. You can compare and change diets anytime — '
          'no approach is right for everyone.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: NGSpacing.md),
        RadioGroup<String>(
          groupValue: _draft.dietId,
          onChanged: (v) => setState(() => _draft.dietId = v!),
          child: Column(
            children: [
              for (final diet in DietCatalog.all.take(8))
                RadioListTile<String>(
                  value: diet.id,
                  contentPadding: EdgeInsets.zero,
                  title: Text(diet.name),
                  subtitle: Text(diet.tagline),
                ),
            ],
          ),
        ),
        TextButton.icon(
          onPressed: () => context.push('/diets'),
          icon: const Icon(Icons.compare_arrows_rounded),
          label: const Text('Explore & compare all diets'),
        ),
      ],
    );
  }

  Widget _allergies() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Allergies', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: NGSpacing.xs),
        Text(
          'We use these to filter meal suggestions and warn you. Add your own '
          'below if it’s not listed.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: NGSpacing.sm),
        Wrap(
          spacing: NGSpacing.sm,
          runSpacing: NGSpacing.sm,
          children: [
            for (final a in _commonAllergens)
              FilterChip(
                label: Text(a),
                selected: _draft.allergies.contains(a),
                onSelected: (sel) => setState(() {
                  sel ? _draft.allergies.add(a) : _draft.allergies.remove(a);
                }),
              ),
          ],
        ),
        const SizedBox(height: NGSpacing.lg),
        TextField(
          decoration: const InputDecoration(
            labelText: 'Foods to avoid (optional)',
            hintText: 'e.g. pork, shellfish, cilantro — comma separated',
          ),
          onChanged: (v) => _draft.avoid
            ..clear()
            ..addAll(
              v.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty),
            ),
        ),
      ],
    );
  }

  Widget _cooking() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Meals per day', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: NGSpacing.sm),
        Wrap(
          spacing: NGSpacing.sm,
          children: [
            for (final n in [2, 3, 4, 5])
              ChoiceChip(
                label: Text('$n'),
                selected: _draft.mealsPerDay == n,
                onSelected: (_) => setState(() => _draft.mealsPerDay = n),
              ),
          ],
        ),
        const SizedBox(height: NGSpacing.lg),
        Text('Cooking time', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: NGSpacing.sm),
        RadioGroup<CookingTime>(
          groupValue: _draft.cookingTime,
          onChanged: (v) => setState(() => _draft.cookingTime = v!),
          child: Column(
            children: [
              for (final t in CookingTime.values)
                RadioListTile<CookingTime>(
                  value: t,
                  contentPadding: EdgeInsets.zero,
                  title: Text(t.label),
                ),
            ],
          ),
        ),
        const SizedBox(height: NGSpacing.md),
        Text('Budget', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: NGSpacing.sm),
        Wrap(
          spacing: NGSpacing.sm,
          children: [
            for (final b in BudgetPreference.values)
              ChoiceChip(
                label: Text(b.label),
                selected: _draft.budget == b,
                onSelected: (_) => setState(() => _draft.budget = b),
              ),
          ],
        ),
      ],
    );
  }

  Widget _health() {
    final selectedAny = _draft.healthFlags.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Optional health check',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: NGSpacing.xs),
        Text(
          'This is optional and private. If any apply, NutriGuide keeps its '
          'guidance general and encourages you to work with a professional — '
          'we’d rather be careful with your health.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: NGSpacing.md),
        for (final flag in HealthFlag.values)
          CheckboxListTile(
            value: _draft.healthFlags.contains(flag),
            onChanged: (v) => setState(() {
              (v ?? false)
                  ? _draft.healthFlags.add(flag)
                  : _draft.healthFlags.remove(flag);
            }),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(flag.label),
          ),
        if (selectedAny) ...[
          const SizedBox(height: NGSpacing.md),
          NoticeBanner(
            severity: _draft.healthFlags.contains(HealthFlag.urgentSymptoms)
                ? NoticeSeverity.danger
                : NoticeSeverity.caution,
            message: _draft.healthFlags.contains(HealthFlag.urgentSymptoms)
                ? 'If you are experiencing urgent symptoms right now, please '
                      'contact local emergency services or seek immediate care.'
                : Consent.professionalGuidanceNotice,
          ),
        ],
      ],
    );
  }

  Widget _consent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const NoticeBanner(
          severity: NoticeSeverity.info,
          title: 'Before we finish',
          message: Consent.aiCoachStatement,
        ),
        const SizedBox(height: NGSpacing.lg),
        CheckboxListTile(
          value: _draft.disclaimerAck,
          onChanged: (v) => setState(() => _draft.disclaimerAck = v ?? false),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          title: Text(
            Consent.productStatement,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        CheckboxListTile(
          value: _draft.dataAck,
          onChanged: (v) => setState(() => _draft.dataAck = v ?? false),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          title: Text(
            Consent.dataConsent,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        const SizedBox(height: NGSpacing.sm),
        Wrap(
          children: [
            TextButton(
              onPressed: () => context.push('/legal/privacy'),
              child: const Text('Privacy Policy'),
            ),
            TextButton(
              onPressed: () => context.push('/legal/terms'),
              child: const Text('Terms of Service'),
            ),
            TextButton(
              onPressed: () => context.push('/legal/disclaimer'),
              child: const Text('Wellness Disclaimer'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _bullet(IconData icon, String text) => Padding(
    padding: const EdgeInsets.only(bottom: NGSpacing.md),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: NGSpacing.md),
        Expanded(child: Text(text)),
      ],
    ),
  );

  Widget _sliderRow({
    required String label,
    required String value,
    required Widget slider,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.titleSmall),
          Text(value, style: Theme.of(context).textTheme.titleSmall),
        ],
      ),
      slider,
    ],
  );

  static const _commonAllergens = [
    'peanut',
    'tree nut',
    'milk',
    'egg',
    'wheat',
    'gluten',
    'soy',
    'fish',
    'shellfish',
    'sesame',
  ];
}

class _Step {
  const _Step(this.title, this.builder);
  final String title;
  final Widget Function() builder;
}
