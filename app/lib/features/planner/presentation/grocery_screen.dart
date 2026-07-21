import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/components.dart';
import '../../../core/design/tokens.dart';
import '../application/planner_controller.dart';
import '../domain/plan_validator.dart';

class GroceryScreen extends ConsumerWidget {
  const GroceryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(plannerControllerProvider.notifier);
    ref.watch(plannerControllerProvider); // rebuild on check changes
    final items = notifier.groceryList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Grocery list'),
        actions: [
          IconButton(
            onPressed: items.isEmpty ? null : () => _share(context, items),
            icon: const Icon(Icons.ios_share_rounded),
            tooltip: 'Share list',
          ),
        ],
      ),
      body: items.isEmpty
          ? const EmptyState(
              icon: Icons.shopping_cart_outlined,
              title: 'Nothing to buy yet',
              message: 'Generate a meal plan to build a grocery list.',
            )
          : _GroceryList(items: items, notifier: notifier),
    );
  }

  void _share(BuildContext context, List<GroceryItem> items) {
    // Export excludes any personal profile data (master requirement §9): the
    // list is only item names and quantities.
    final buffer = StringBuffer('NutriGuide grocery list\n\n');
    String? category;
    for (final item in items) {
      if (item.category != category) {
        category = item.category;
        buffer.writeln('\n$category');
      }
      buffer.writeln('- ${item.name} (${item.grams.round()} g)');
    }
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Shareable list'),
        content: SingleChildScrollView(child: Text(buffer.toString())),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _GroceryList extends StatelessWidget {
  const _GroceryList({required this.items, required this.notifier});

  final List<GroceryItem> items;
  final PlannerController notifier;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final grouped = <String, List<GroceryItem>>{};
    for (final item in items) {
      grouped.putIfAbsent(item.category, () => []).add(item);
    }
    final checkedCount = items.where((i) => i.checked).length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(NGSpacing.lg),
          child: NGCard(
            padding: const EdgeInsets.all(NGSpacing.md),
            child: Row(
              children: [
                Icon(Icons.checklist_rounded, color: theme.colorScheme.primary),
                const SizedBox(width: NGSpacing.md),
                Text(
                  '$checkedCount of ${items.length} items checked',
                  style: theme.textTheme.titleSmall,
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              NGSpacing.lg,
              0,
              NGSpacing.lg,
              NGSpacing.xxxl,
            ),
            children: [
              for (final category in grouped.keys) ...[
                SectionHeader(title: category),
                for (final item in grouped[category]!)
                  CheckboxListTile(
                    value: item.checked,
                    onChanged: (_) => notifier.toggleGrocery(item.name),
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      item.name,
                      style: item.checked
                          ? theme.textTheme.bodyMedium?.copyWith(
                              decoration: TextDecoration.lineThrough,
                              color: theme.colorScheme.onSurfaceVariant,
                            )
                          : theme.textTheme.bodyMedium,
                    ),
                    secondary: Text(
                      '${item.grams.round()} g',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
