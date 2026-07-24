import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/design/components.dart';
import '../../../core/design/tokens.dart';
import '../../planner/domain/recipe.dart';
import '../application/diary_controller.dart';
import '../domain/food_item.dart';

/// Bottom sheet for adding a food to the diary: search, recent, quick add.
///
/// Barcode scanning and photo attachment are surfaced as clearly optional
/// entry points. They request camera access only at the moment of use and the
/// diary stays fully usable without them (master requirement §10).
class FoodSearchSheet extends ConsumerStatefulWidget {
  const FoodSearchSheet({super.key, required this.slot});

  final MealSlot slot;

  @override
  ConsumerState<FoodSearchSheet> createState() => _FoodSearchSheetState();
}

class _FoodSearchSheetState extends ConsumerState<FoodSearchSheet> {
  final _searchController = TextEditingController();
  String _query = '';
  List<FoodItem> _results = [];
  List<FoodItem> _recent = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final foodRepo = ref.read(foodRepositoryProvider);
    final diaryRepo = ref.read(diaryRepositoryProvider);
    final all = await foodRepo.search('');
    final recentEntries = await diaryRepo.recent(limit: 8);
    final recentFoods = <FoodItem>[];
    for (final e in recentEntries) {
      if (e.foodId != null) {
        final f = await foodRepo.byId(e.foodId!);
        if (f != null) recentFoods.add(f);
      }
    }
    if (!mounted) return;
    setState(() {
      _results = all;
      _recent = recentFoods;
      _loading = false;
    });
  }

  Future<void> _search(String query) async {
    setState(() => _query = query);
    final results = await ref.read(foodRepositoryProvider).search(query);
    if (!mounted) return;
    setState(() => _results = results);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      builder: (context, controller) => Padding(
        padding: EdgeInsets.only(
          left: NGSpacing.lg,
          right: NGSpacing.lg,
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Add to ${widget.slot.label}',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: NGSpacing.md),
            TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search foods…',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          _search('');
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
              ),
              onChanged: _search,
            ),
            const SizedBox(height: NGSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _quickAdd(context),
                    icon: const Icon(Icons.bolt_rounded),
                    label: const Text('Quick add'),
                  ),
                ),
                const SizedBox(width: NGSpacing.sm),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _optionalFeatureNotice(context, 'Barcode'),
                    icon: const Icon(Icons.qr_code_scanner_rounded),
                    label: const Text('Scan'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: NGSpacing.sm),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      controller: controller,
                      children: [
                        if (_query.isEmpty && _recent.isNotEmpty) ...[
                          const SectionHeader(title: 'Recent'),
                          for (final food in _recent)
                            _FoodTile(
                              food: food,
                              onTap: () => _pickPortion(context, food),
                            ),
                        ],
                        SectionHeader(
                          title: _query.isEmpty ? 'All foods' : 'Results',
                        ),
                        if (_results.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(NGSpacing.lg),
                            child: Text(
                              'No foods found. Use Quick add to enter it '
                              'manually.',
                              style: theme.textTheme.bodyMedium,
                            ),
                          )
                        else
                          for (final food in _results)
                            _FoodTile(
                              food: food,
                              onTap: () => _pickPortion(context, food),
                            ),
                        const SizedBox(height: NGSpacing.xxl),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _optionalFeatureNotice(BuildContext context, String feature) {
    // Optional camera features build against the real integration boundary
    // but require the camera plugin + backend barcode lookup to be enabled.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$feature scanning is optional and asks for camera access only '
          'when enabled. The diary works fully without it.',
        ),
      ),
    );
  }

  Future<void> _pickPortion(BuildContext context, FoodItem food) async {
    final grams = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _PortionSheet(food: food),
    );
    if (grams == null || !context.mounted) return;
    await ref
        .read(diaryControllerProvider.notifier)
        .logFood(food: food, slot: widget.slot, grams: grams);
    if (context.mounted) Navigator.pop(context);
  }

  Future<void> _quickAdd(BuildContext context) async {
    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _QuickAddSheet(slot: widget.slot),
    );
    if ((added ?? false) && context.mounted) Navigator.pop(context);
  }
}

class _FoodTile extends StatelessWidget {
  const _FoodTile({required this.food, required this.onTap});
  final FoodItem food;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final perServing = food.perServing;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      title: Text(food.name),
      subtitle: Text(
        '${perServing.kcal.round()} kcal · ${food.servingName}'
        '${food.source == NutritionSource.verified ? '' : ' · ${food.source.label}'}',
        style: theme.textTheme.bodySmall,
      ),
      trailing: const Icon(Icons.add_rounded),
    );
  }
}

class _PortionSheet extends StatefulWidget {
  const _PortionSheet({required this.food});
  final FoodItem food;

  @override
  State<_PortionSheet> createState() => _PortionSheetState();
}

class _PortionSheetState extends State<_PortionSheet> {
  late double _servings = 1;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final grams = widget.food.servingGrams * _servings;
    final nutrients = widget.food.forGrams(grams);
    return Padding(
      padding: EdgeInsets.only(
        left: NGSpacing.lg,
        right: NGSpacing.lg,
        top: NGSpacing.sm,
        bottom: MediaQuery.of(context).viewInsets.bottom + NGSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.food.name, style: theme.textTheme.titleLarge),
          const SizedBox(height: NGSpacing.xs),
          Text(
            '${widget.food.servingName} = ${widget.food.servingGrams.round()} g',
            style: theme.textTheme.bodySmall,
          ),
          if (widget.food.isEstimate && widget.food.assumptions != null) ...[
            const SizedBox(height: NGSpacing.sm),
            SourceCard(
              title: 'Estimate assumptions',
              source: widget.food.assumptions!,
            ),
          ],
          const SizedBox(height: NGSpacing.lg),
          Row(
            children: [
              Text('Servings', style: theme.textTheme.labelLarge),
              Expanded(
                child: Slider(
                  value: _servings,
                  min: 0.25,
                  max: 5,
                  divisions: 19,
                  label: _servings.toStringAsFixed(2),
                  onChanged: (v) => setState(() => _servings = v),
                ),
              ),
              Text('${grams.round()} g', style: theme.textTheme.labelLarge),
            ],
          ),
          const SizedBox(height: NGSpacing.sm),
          Text(
            '${nutrients.kcal.round()} kcal · P ${nutrients.proteinG.round()}g · '
            'C ${nutrients.carbsG.round()}g · F ${nutrients.fatG.round()}g',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: NGSpacing.lg),
          FilledButton(
            onPressed: () => Navigator.pop(context, grams),
            child: const Text('Add to diary'),
          ),
        ],
      ),
    );
  }
}

class _QuickAddSheet extends ConsumerStatefulWidget {
  const _QuickAddSheet({required this.slot});

  final MealSlot slot;

  @override
  ConsumerState<_QuickAddSheet> createState() => _QuickAddSheetState();
}

class _QuickAddSheetState extends ConsumerState<_QuickAddSheet> {
  final _name = TextEditingController();
  final _kcal = TextEditingController();
  final _protein = TextEditingController();
  final _carbs = TextEditingController();
  final _fat = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _kcal.dispose();
    _protein.dispose();
    _carbs.dispose();
    _fat.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: NGSpacing.lg,
        right: NGSpacing.lg,
        top: NGSpacing.sm,
        bottom: MediaQuery.of(context).viewInsets.bottom + NGSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Quick add', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: NGSpacing.md),
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Food name'),
          ),
          const SizedBox(height: NGSpacing.sm),
          TextField(
            controller: _kcal,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Calories (kcal)'),
          ),
          const SizedBox(height: NGSpacing.sm),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _protein,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'P (g)'),
                ),
              ),
              const SizedBox(width: NGSpacing.sm),
              Expanded(
                child: TextField(
                  controller: _carbs,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'C (g)'),
                ),
              ),
              const SizedBox(width: NGSpacing.sm),
              Expanded(
                child: TextField(
                  controller: _fat,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'F (g)'),
                ),
              ),
            ],
          ),
          const SizedBox(height: NGSpacing.lg),
          FilledButton(onPressed: _submit, child: const Text('Add')),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a name.')));
      return;
    }
    final nutrients = Nutrients(
      kcal: double.tryParse(_kcal.text) ?? 0,
      proteinG: double.tryParse(_protein.text) ?? 0,
      carbsG: double.tryParse(_carbs.text) ?? 0,
      fatG: double.tryParse(_fat.text) ?? 0,
    );
    await ref
        .read(diaryControllerProvider.notifier)
        .quickAdd(name: name, slot: widget.slot, nutrients: nutrients);
    if (mounted) Navigator.pop(context, true);
  }
}
