import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/env.dart';
import '../../../core/design/components.dart';
import '../../../core/design/tokens.dart';
import '../../legal/consent.dart';
import '../application/coach_controller.dart';
import '../domain/chat_message.dart';
import '../domain/safety_classifier.dart';

class CoachScreen extends ConsumerStatefulWidget {
  const CoachScreen({super.key});

  @override
  ConsumerState<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends ConsumerState<CoachScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send() {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    _input.clear();
    ref.read(coachControllerProvider.notifier).send(text);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent + 240,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(coachControllerProvider);
    // Restore a saved draft after a failed send.
    if (state.draft.isNotEmpty && _input.text.isEmpty) {
      _input.text = state.draft;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Nutrition Coach'),
        actions: [
          IconButton(
            onPressed: () => context.push('/coach/info'),
            icon: const Icon(Icons.info_outline_rounded),
            tooltip: 'About the AI Coach',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: state.loading
                ? const Center(child: CircularProgressIndicator())
                : state.messages.isEmpty
                ? _Intro()
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(NGSpacing.lg),
                    itemCount: state.messages.length,
                    itemBuilder: (context, i) =>
                        _MessageBubble(message: state.messages[i]),
                  ),
          ),
          if (state.error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: NGSpacing.lg),
              child: NoticeBanner(
                severity: NoticeSeverity.caution,
                message: state.error!,
                onDismiss: ref
                    .read(coachControllerProvider.notifier)
                    .dismissError,
              ),
            ),
          _Composer(controller: _input, sending: state.sending, onSend: _send),
        ],
      ),
    );
  }
}

class _Intro extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(NGSpacing.lg),
      children: [
        const SizedBox(height: NGSpacing.xl),
        Icon(Icons.forum_rounded, size: 48, color: theme.colorScheme.primary),
        const SizedBox(height: NGSpacing.md),
        Text(
          'AI Nutrition Coach',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: NGSpacing.sm),
        // Disclaimer shown before the first AI conversation (master req §1).
        const NoticeBanner(
          severity: NoticeSeverity.info,
          title: 'Before we start',
          message: Consent.aiCoachStatement,
        ),
        if (AppEnvironment.useDevStub) ...[
          const SizedBox(height: NGSpacing.md),
          const NoticeBanner(
            severity: NoticeSeverity.caution,
            title: 'Development stub',
            message:
                'This build answers from a small offline knowledge base and '
                'labels replies as development stubs. Configure the backend '
                'for the full AI Coach.',
          ),
        ],
        const SizedBox(height: NGSpacing.lg),
        Text('Try asking', style: theme.textTheme.titleSmall),
        const SizedBox(height: NGSpacing.sm),
        for (final s in const [
          'How much protein do I need?',
          'What are good high-fiber foods?',
          'Is intermittent fasting effective?',
          'How do I read a nutrition label?',
        ])
          Card(
            child: ListTile(
              title: Text(s),
              trailing: const Icon(Icons.north_east_rounded, size: 16),
              onTap: () {
                final ctx = context;
                final state = ProviderScope.containerOf(ctx);
                state.read(coachControllerProvider.notifier).send(s);
              },
            ),
          ),
      ],
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.role == ChatRole.user;
    final isSafety =
        message.safetyCategory != null &&
        message.safetyCategory != SafetyCategory.none;

    if (isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: NGSpacing.md, left: 48),
          padding: const EdgeInsets.all(NGSpacing.md),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(NGRadius.lg),
              topRight: Radius.circular(NGRadius.lg),
              bottomLeft: Radius.circular(NGRadius.lg),
            ),
          ),
          child: Text(
            message.text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onPrimary,
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: NGSpacing.lg, right: 32),
      padding: const EdgeInsets.all(NGSpacing.lg),
      decoration: BoxDecoration(
        color: isSafety
            ? theme.colorScheme.errorContainer.withValues(alpha: 0.4)
            : theme.colorScheme.surfaceContainer,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(NGRadius.lg),
          topRight: Radius.circular(NGRadius.lg),
          bottomRight: Radius.circular(NGRadius.lg),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.status == MessageStatus.streaming && message.text.isEmpty)
            const _TypingIndicator()
          else ...[
            Text(message.text, style: theme.textTheme.bodyLarge),
            if (message.explanation != null &&
                message.explanation!.isNotEmpty) ...[
              const SizedBox(height: NGSpacing.md),
              Text(message.explanation!, style: theme.textTheme.bodyMedium),
            ],
            if (message.nextSteps.isNotEmpty) ...[
              const SizedBox(height: NGSpacing.md),
              Text('Next steps', style: theme.textTheme.titleSmall),
              const SizedBox(height: NGSpacing.xs),
              for (final step in message.nextSteps)
                Padding(
                  padding: const EdgeInsets.only(bottom: NGSpacing.xs),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('•  '),
                      Expanded(child: Text(step)),
                    ],
                  ),
                ),
            ],
            if (message.limitations != null &&
                message.limitations!.isNotEmpty) ...[
              const SizedBox(height: NGSpacing.md),
              Container(
                padding: const EdgeInsets.all(NGSpacing.md),
                decoration: BoxDecoration(
                  color: NGColors.caution.withValues(alpha: 0.12),
                  borderRadius: NGRadius.control,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 18,
                      color: NGColors.caution,
                    ),
                    const SizedBox(width: NGSpacing.sm),
                    Expanded(child: Text(message.limitations!)),
                  ],
                ),
              ),
            ],
            if (message.sources.isNotEmpty) ...[
              const SizedBox(height: NGSpacing.md),
              Text('Sources', style: theme.textTheme.titleSmall),
              const SizedBox(height: NGSpacing.xs),
              for (final source in message.sources)
                Padding(
                  padding: const EdgeInsets.only(bottom: NGSpacing.xs),
                  child: SourceCard(
                    title: source.title,
                    source: source.source,
                    date: source.date,
                  ),
                ),
            ],
            const SizedBox(height: NGSpacing.md),
            Wrap(
              spacing: NGSpacing.sm,
              runSpacing: NGSpacing.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (message.confidence != null)
                  ConfidenceChip(level: message.confidence!),
                if (message.professionalReferral) _referralChip(context),
                if (message.isStub) _stubChip(context),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _referralChip(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: NGSpacing.sm, vertical: 4),
    decoration: BoxDecoration(
      borderRadius: NGRadius.chip,
      border: Border.all(color: NGColors.info.withValues(alpha: 0.6)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.medical_information_outlined,
          size: 14,
          color: NGColors.info,
        ),
        const SizedBox(width: NGSpacing.xs),
        Text(
          'See a professional',
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: NGColors.info),
        ),
      ],
    ),
  );

  Widget _stubChip(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: NGSpacing.sm, vertical: 4),
    decoration: BoxDecoration(
      borderRadius: NGRadius.chip,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
    ),
    child: Text(
      'Development stub',
      style: Theme.of(context).textTheme.labelSmall,
    ),
  );
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 3; i++)
          AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              final t = (_c.value + i * 0.2) % 1.0;
              return Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Opacity(
                  opacity: 0.3 + 0.7 * (t < 0.5 ? t * 2 : (1 - t) * 2),
                  child: const CircleAvatar(radius: 4),
                ),
              );
            },
          ),
      ],
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(NGSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 5,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                  hintText: 'Ask a nutrition question…',
                ),
              ),
            ),
            const SizedBox(width: NGSpacing.sm),
            SizedBox(
              height: 52,
              width: 52,
              child: FilledButton(
                onPressed: sending ? null : onSend,
                style: FilledButton.styleFrom(
                  padding: EdgeInsets.zero,
                  shape: const CircleBorder(),
                ),
                child: sending
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.colorScheme.onPrimary,
                        ),
                      )
                    : const Icon(Icons.arrow_upward_rounded),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
