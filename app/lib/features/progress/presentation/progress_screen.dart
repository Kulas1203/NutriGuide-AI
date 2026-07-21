import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/components.dart';
import '../../../core/design/tokens.dart';
import '../../profile/application/profile_controller.dart';
import '../application/progress_controller.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(progressControllerProvider);
    final notifier = ref.read(progressControllerProvider.notifier);
    final hideWeight =
        ref.watch(profileControllerProvider).profile?.hideWeightFeatures ??
        false;

    return Scaffold(
      appBar: AppBar(title: const Text('Progress')),
      body: state.loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                NGSpacing.lg,
                NGSpacing.lg,
                NGSpacing.lg,
                NGSpacing.xxxl,
              ),
              children: [
                if (!hideWeight) ...[
                  _WeightSection(state: state, notifier: notifier),
                  const SizedBox(height: NGSpacing.lg),
                ],
                _HabitsSection(state: state, notifier: notifier),
                const SizedBox(height: NGSpacing.lg),
                const NoticeBanner(
                  severity: NoticeSeverity.info,
                  message:
                      'We show gentle trends, not daily judgments. Weight '
                      'naturally fluctuates day to day — the direction over '
                      'weeks is what matters.',
                ),
              ],
            ),
    );
  }
}

class _WeightSection extends StatelessWidget {
  const _WeightSection({required this.state, required this.notifier});

  final ProgressState state;
  final ProgressController notifier;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trend = notifier.weeklyWeightTrend();
    return NGCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Weight', style: theme.textTheme.titleMedium),
              const Spacer(),
              FilledButton.tonal(
                onPressed: () => _logWeight(context),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.symmetric(horizontal: NGSpacing.md),
                ),
                child: const Text('Log'),
              ),
            ],
          ),
          const SizedBox(height: NGSpacing.md),
          if (state.weights.length < 2)
            Text(
              'Log your weight a few times to see a trend.',
              style: theme.textTheme.bodySmall,
            )
          else ...[
            SizedBox(height: 180, child: _WeightChart(state: state)),
            const SizedBox(height: NGSpacing.md),
            if (trend != null)
              Text(
                trend.abs() < 0.05
                    ? 'Holding steady over recent entries.'
                    : '${trend < 0 ? 'Down' : 'Up'} about '
                          '${trend.abs().toStringAsFixed(2)} kg/week recently.',
                style: theme.textTheme.bodyMedium,
              ),
          ],
        ],
      ),
    );
  }

  Future<void> _logWeight(BuildContext context) async {
    final controller = TextEditingController();
    final value = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log weight'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Weight (kg)',
            suffixText: 'kg',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(context, double.tryParse(controller.text)),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (value != null && value > 0) {
      await notifier.logWeight(value);
    }
  }
}

class _WeightChart extends StatelessWidget {
  const _WeightChart({required this.state});
  final ProgressState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final points = state.weights;
    final spots = [
      for (var i = 0; i < points.length; i++)
        FlSpot(i.toDouble(), points[i].weightKg),
    ];
    final values = points.map((e) => e.weightKg);
    final minY = values.reduce((a, b) => a < b ? a : b) - 1;
    final maxY = values.reduce((a, b) => a > b ? a : b) + 1;

    return LineChart(
      LineChartData(
        minY: minY,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: theme.colorScheme.outlineVariant, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (value, meta) => Text(
                value.toStringAsFixed(0),
                style: theme.textTheme.labelSmall,
              ),
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: theme.colorScheme.primary,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }
}

class _HabitsSection extends StatelessWidget {
  const _HabitsSection({required this.state, required this.notifier});

  final ProgressState state;
  final ProgressController notifier;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return NGCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Daily habits', style: theme.textTheme.titleMedium),
              const Spacer(),
              IconButton(
                onPressed: () => _addHabit(context),
                icon: const Icon(Icons.add_rounded),
                tooltip: 'Add habit',
              ),
            ],
          ),
          if (state.habits.isEmpty)
            Text(
              'Add a small, positive habit like “vegetables with lunch”.',
              style: theme.textTheme.bodySmall,
            )
          else
            for (final habit in state.habits)
              CheckboxListTile(
                value: state.todayHabitIds.contains(habit.id),
                onChanged: (_) => notifier.toggleHabitToday(habit.id),
                contentPadding: EdgeInsets.zero,
                title: Text(habit.title),
                secondary: IconButton(
                  onPressed: () => notifier.archiveHabit(habit.id),
                  icon: const Icon(Icons.close_rounded),
                  tooltip: 'Remove habit',
                ),
              ),
        ],
      ),
    );
  }

  Future<void> _addHabit(BuildContext context) async {
    final controller = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New habit'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'e.g. Walk after dinner'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (title != null && title.trim().isNotEmpty) {
      await notifier.addHabit(title);
    }
  }
}
