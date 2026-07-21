import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/components.dart';
import '../../../core/design/tokens.dart';
import '../../legal/consent.dart';
import '../../profile/application/profile_controller.dart';
import '../application/coach_controller.dart';

/// AI chat information screen (master requirement §1, §8, §15).
class CoachInfoScreen extends ConsumerWidget {
  const CoachInfoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profile = ref.watch(profileControllerProvider).profile;
    final historyEnabled = profile?.aiHistoryEnabled ?? true;

    return Scaffold(
      appBar: AppBar(title: const Text('About the AI Coach')),
      body: ListView(
        padding: const EdgeInsets.all(NGSpacing.lg),
        children: [
          const NoticeBanner(
            severity: NoticeSeverity.info,
            title: 'What it is',
            message: Consent.aiCoachStatement,
          ),
          const SizedBox(height: NGSpacing.lg),
          Text('How it works', style: theme.textTheme.titleMedium),
          const SizedBox(height: NGSpacing.sm),
          _point(
            context,
            Icons.lock_outline_rounded,
            'Your questions go over an encrypted connection to our secure backend. AI provider credentials never touch your device.',
          ),
          _point(
            context,
            Icons.menu_book_outlined,
            'Answers are grounded with evidence (e.g. USDA data and reviewed content) and include sources and a confidence level.',
          ),
          _point(
            context,
            Icons.health_and_safety_outlined,
            'A safety layer detects urgent, eating-disorder, medication and other sensitive topics and responds with appropriate guidance.',
          ),
          _point(
            context,
            Icons.block_outlined,
            'It won’t diagnose, prescribe, promise outcomes, or invent studies or numbers. It will tell you when it doesn’t know.',
          ),
          const SizedBox(height: NGSpacing.lg),
          Text('Your data controls', style: theme.textTheme.titleMedium),
          const SizedBox(height: NGSpacing.sm),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: historyEnabled,
            onChanged: profile == null ? null : (v) => _setHistory(ref, v),
            title: const Text('Save conversation history'),
            subtitle: const Text(
              'When off, messages stay only in this session and the app '
              'still works. We never train models on your private '
              'conversations without separate, explicit opt-in.',
            ),
          ),
          const SizedBox(height: NGSpacing.sm),
          OutlinedButton.icon(
            onPressed: () => _clearHistory(context, ref),
            icon: const Icon(Icons.delete_outline_rounded),
            label: const Text('Delete conversation history'),
          ),
          const SizedBox(height: NGSpacing.lg),
          TextButton(
            onPressed: () => context.push('/legal/ai-transparency'),
            child: const Text('Read the full AI Transparency Notice'),
          ),
        ],
      ),
    );
  }

  Future<void> _setHistory(WidgetRef ref, bool value) async {
    final controller = ref.read(profileControllerProvider.notifier);
    final profile = ref.read(profileControllerProvider).profile;
    if (profile == null) return;
    await controller.saveProfile(
      profile.copyWith(aiHistoryEnabled: value),
      recomputeTargets: false,
    );
  }

  Future<void> _clearHistory(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete conversation history?'),
        content: const Text(
          'This permanently removes your saved AI Coach messages from this '
          'device and our servers.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(coachControllerProvider.notifier).clearHistory();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Conversation history deleted.')),
        );
      }
    }
  }

  Widget _point(BuildContext context, IconData icon, String text) => Padding(
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
}
