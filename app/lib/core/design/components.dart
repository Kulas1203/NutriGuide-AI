import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'tokens.dart';

/// Surface card used across the app for grouped content.
class NGCard extends StatelessWidget {
  const NGCard({
    super.key,
    required this.child,
    this.padding = NGSpacing.card,
    this.onTap,
    this.color,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final card = Card(
      color: color,
      child: Padding(padding: padding, child: child),
    );
    if (onTap == null) return card;
    return Card(
      color: color,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// Section header with optional trailing action.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: NGSpacing.xl, bottom: NGSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
          if (actionLabel != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}

/// Circular progress ring for calories/macros with a center label.
class StatRing extends StatelessWidget {
  const StatRing({
    super.key,
    required this.progress,
    required this.label,
    required this.sublabel,
    this.size = 132,
    this.color,
  });

  /// 0..1+; values above 1 render as full with an "over" tint.
  final double progress;
  final String label;
  final String sublabel;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final over = progress > 1.0;
    final ringColor = over ? NGColors.caution : (color ?? scheme.primary);
    return Semantics(
      label: '$label, $sublabel',
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: size,
              height: size,
              child: CircularProgressIndicator(
                value: math.min(progress, 1.0),
                strokeWidth: 10,
                strokeCap: StrokeCap.round,
                color: ringColor,
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                Text(
                  sublabel,
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Labeled linear macro bar (e.g. "Protein 80 / 120 g").
class MacroBar extends StatelessWidget {
  const MacroBar({
    super.key,
    required this.label,
    required this.consumed,
    required this.target,
    required this.unit,
    required this.color,
  });

  final String label;
  final double consumed;
  final double target;
  final String unit;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ratio = target <= 0 ? 0.0 : (consumed / target).clamp(0.0, 1.0);
    return Semantics(
      label: '$label ${consumed.round()} of ${target.round()} $unit',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: theme.textTheme.labelMedium),
              Text(
                '${consumed.round()} / ${target.round()} $unit',
                style: theme.textTheme.labelMedium,
              ),
            ],
          ),
          const SizedBox(height: NGSpacing.xs),
          ClipRRect(
            borderRadius: NGRadius.chip,
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Empty state with icon, message and optional action.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(NGSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 32,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: NGSpacing.lg),
            Text(
              title,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: NGSpacing.sm),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null) ...[
              const SizedBox(height: NGSpacing.xl),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Error state with retry, used wherever loading can fail.
class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    required this.message,
    this.onRetry,
    this.retryLabel = 'Try again',
  });

  final String message;
  final VoidCallback? onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.error_outline_rounded,
      title: 'Something went wrong',
      message: message,
      actionLabel: onRetry == null ? null : retryLabel,
      onAction: onRetry,
    );
  }
}

/// Shimmer-free skeleton block honoring reduced motion.
class SkeletonBox extends StatefulWidget {
  const SkeletonBox({
    super.key,
    this.height = 16,
    this.width = double.infinity,
    this.radius = NGRadius.sm,
  });

  final double height;
  final double width;
  final double radius;

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
    lowerBound: 0.4,
    upperBound: 0.9,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    if (!reduced && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (reduced && _controller.isAnimating) {
      _controller.stop();
    }
    final base = Theme.of(context).colorScheme.surfaceContainerHighest;
    return FadeTransition(
      opacity: reduced ? const AlwaysStoppedAnimation(0.7) : _controller,
      child: Container(
        height: widget.height,
        width: widget.width,
        decoration: BoxDecoration(
          color: base,
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}

enum NoticeSeverity { info, caution, danger, success }

/// Prominent notice banner for safety, offline and status messaging.
class NoticeBanner extends StatelessWidget {
  const NoticeBanner({
    super.key,
    required this.message,
    this.title,
    this.severity = NoticeSeverity.info,
    this.onDismiss,
    this.action,
  });

  final String message;
  final String? title;
  final NoticeSeverity severity;
  final VoidCallback? onDismiss;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final (Color fg, Color bg) = switch (severity) {
      NoticeSeverity.info => (
        dark ? const Color(0xFF9FC1E4) : NGColors.info,
        dark ? const Color(0xFF1E2C3A) : const Color(0xFFE3ECF5),
      ),
      NoticeSeverity.caution => (
        dark ? const Color(0xFFE0B96A) : NGColors.caution,
        dark ? const Color(0xFF37301C) : const Color(0xFFF6ECD7),
      ),
      NoticeSeverity.danger => (
        dark ? const Color(0xFFE5897C) : NGColors.danger,
        dark ? const Color(0xFF3A241F) : const Color(0xFFF7E4E1),
      ),
      NoticeSeverity.success => (
        dark ? const Color(0xFF8FC49E) : NGColors.leafDeep,
        dark ? const Color(0xFF22321F) : NGColors.leafSoft,
      ),
    };
    final icon = switch (severity) {
      NoticeSeverity.info => Icons.info_outline_rounded,
      NoticeSeverity.caution => Icons.warning_amber_rounded,
      NoticeSeverity.danger => Icons.report_outlined,
      NoticeSeverity.success => Icons.check_circle_outline_rounded,
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(NGSpacing.lg),
      decoration: BoxDecoration(color: bg, borderRadius: NGRadius.card),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: fg, size: 22),
          const SizedBox(width: NGSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null) ...[
                  Text(
                    title!,
                    style: theme.textTheme.titleSmall?.copyWith(color: fg),
                  ),
                  const SizedBox(height: NGSpacing.xs),
                ],
                Text(
                  message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                if (action != null) ...[
                  const SizedBox(height: NGSpacing.sm),
                  action!,
                ],
              ],
            ),
          ),
          if (onDismiss != null)
            IconButton(
              onPressed: onDismiss,
              icon: const Icon(Icons.close_rounded, size: 20),
              tooltip: 'Dismiss',
            ),
        ],
      ),
    );
  }
}

/// Chip communicating AI answer confidence.
class ConfidenceChip extends StatelessWidget {
  const ConfidenceChip({super.key, required this.level});

  /// 'established' | 'general' | 'individual' | 'uncertain'
  final String level;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (String label, Color color) = switch (level) {
      'established' => ('Established evidence', NGColors.success),
      'general' => ('General guidance', NGColors.info),
      'individual' => ('Depends on you', NGColors.caution),
      _ => ('Uncertain evidence', NGColors.caution),
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: NGSpacing.sm,
        vertical: NGSpacing.xs,
      ),
      decoration: BoxDecoration(
        borderRadius: NGRadius.chip,
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_outlined, size: 14, color: color),
          const SizedBox(width: NGSpacing.xs),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

/// Compact source attribution card shown under AI answers and food entries.
class SourceCard extends StatelessWidget {
  const SourceCard({
    super.key,
    required this.title,
    required this.source,
    this.date,
  });

  final String title;
  final String source;
  final String? date;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(NGSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: NGRadius.control,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.menu_book_outlined,
            size: 18,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: NGSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.labelLarge),
                const SizedBox(height: 2),
                Text(
                  date == null ? source : '$source · $date',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
