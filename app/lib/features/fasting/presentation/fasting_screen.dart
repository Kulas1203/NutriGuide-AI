import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/components.dart';
import '../../../core/design/tokens.dart';
import '../../../core/utils/dates.dart';
import '../../diets/domain/diet_program.dart';
import '../application/fasting_controller.dart';
import '../domain/fasting_session.dart';

class FastingScreen extends ConsumerWidget {
  const FastingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(fastingControllerProvider);
    final notifier = ref.read(fastingControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Fasting')),
      body: ListView(
        padding: const EdgeInsets.all(NGSpacing.lg),
        children: [
          if (state.active != null)
            _ActiveFast(session: state.active!, notifier: notifier)
          else
            _StartFast(notifier: notifier),
          const SizedBox(height: NGSpacing.lg),
          const NoticeBanner(
            severity: NoticeSeverity.danger,
            title: 'Your safety comes first',
            message: FastingSafety.stopNowText,
          ),
          const SizedBox(height: NGSpacing.md),
          const NoticeBanner(
            severity: NoticeSeverity.info,
            message: FastingSafety.infoText,
          ),
          if (state.history.isNotEmpty) ...[
            const SectionHeader(title: 'History'),
            for (final session in state.history.take(20))
              _HistoryTile(session: session),
          ],
        ],
      ),
    );
  }
}

class _ActiveFast extends StatelessWidget {
  const _ActiveFast({required this.session, required this.notifier});

  final FastingSession session;
  final FastingController notifier;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final elapsed = session.elapsed(now);
    final progress = session.progress(now);
    final reachedTarget = elapsed >= session.target;

    return NGCard(
      child: Column(
        children: [
          Text(
            reachedTarget
                ? 'Eating window is open'
                : FastingSession.scheduleById(session.scheduleId).label,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: NGSpacing.lg),
          StatRing(
            progress: progress,
            label: Dates.formatClock(elapsed),
            sublabel: reachedTarget
                ? 'Target reached'
                : 'of ${session.targetHours}h',
            size: 168,
          ),
          const SizedBox(height: NGSpacing.lg),
          if (!reachedTarget)
            Text(
              'Eating window opens around '
              '${TimeOfDay.fromDateTime(session.windowOpensAt()).format(context)}',
              style: theme.textTheme.bodySmall,
            ),
          const SizedBox(height: NGSpacing.lg),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: session.status == FastingStatus.paused
                      ? notifier.resume
                      : notifier.pause,
                  icon: Icon(
                    session.status == FastingStatus.paused
                        ? Icons.play_arrow_rounded
                        : Icons.pause_rounded,
                  ),
                  label: Text(
                    session.status == FastingStatus.paused ? 'Resume' : 'Pause',
                  ),
                ),
              ),
              const SizedBox(width: NGSpacing.md),
              Expanded(
                child: FilledButton.icon(
                  // Stop is immediate — no confirmation friction (master §11).
                  onPressed: notifier.stop,
                  icon: const Icon(Icons.stop_rounded),
                  label: const Text('Stop'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StartFast extends StatelessWidget {
  const _StartFast({required this.notifier});
  final FastingController notifier;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Start a fast', style: theme.textTheme.titleMedium),
        const SizedBox(height: NGSpacing.xs),
        Text(
          'Gentle schedules only. You can stop anytime.',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: NGSpacing.md),
        for (final schedule in supportedFastingSchedules)
          Padding(
            padding: const EdgeInsets.only(bottom: NGSpacing.sm),
            child: NGCard(
              onTap: () => notifier.start(schedule),
              padding: const EdgeInsets.all(NGSpacing.md),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Text(
                      schedule.label.split(':').first,
                      style: TextStyle(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: NGSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(schedule.label, style: theme.textTheme.titleSmall),
                        Text(
                          '${schedule.fastingHours}h fasting · '
                          '${schedule.eatingHours}h eating window',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.play_arrow_rounded),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.session});
  final FastingSession session;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final duration = session.elapsed(session.endedAt ?? DateTime.now());
    final completed = session.status == FastingStatus.completed;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        completed
            ? Icons.check_circle_outline_rounded
            : Icons.timelapse_rounded,
        color: completed
            ? NGColors.success
            : theme.colorScheme.onSurfaceVariant,
      ),
      title: Text(
        '${FastingSession.scheduleById(session.scheduleId).label} · '
        '${Dates.formatDuration(duration)}',
      ),
      subtitle: Text(Dates.friendly(session.startedAt)),
      trailing: Text(
        completed ? 'Completed' : 'Ended early',
        style: theme.textTheme.labelSmall,
      ),
    );
  }
}
