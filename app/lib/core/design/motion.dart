import 'package:flutter/material.dart';

import 'tokens.dart';

/// Premium micro-interaction primitives.
///
/// Design rules (master requirement §14): motion is purposeful, quick and
/// consistent. Every effect here collapses to a static end-state when the
/// platform requests reduced motion, so accessibility is never traded for
/// polish.

/// Subtle scale-down feedback while a surface is pressed. Uses a [Listener]
/// so it never steals gestures from the wrapped InkWell or button.
class PressableScale extends StatefulWidget {
  const PressableScale({
    super.key,
    required this.child,
    this.pressedScale = 0.98,
    this.enabled = true,
  });

  final Widget child;
  final double pressedScale;
  final bool enabled;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || MediaQuery.disableAnimationsOf(context)) {
      return widget.child;
    }
    return Listener(
      onPointerDown: (_) => setState(() => _pressed = true),
      onPointerUp: (_) => setState(() => _pressed = false),
      onPointerCancel: (_) => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1.0,
        duration: NGMotion.fast,
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// One-shot entrance: fade + gentle rise, staggered by [index]. Used for
/// dashboard cards and chat bubbles so screens assemble instead of popping.
class Entrance extends StatefulWidget {
  const Entrance({
    super.key,
    required this.child,
    this.index = 0,
    this.duration = const Duration(milliseconds: 320),
    this.delayPerItem = const Duration(milliseconds: 45),
    this.offset = 14,
  });

  final Widget child;
  final int index;
  final Duration duration;
  final Duration delayPerItem;
  final double offset;

  @override
  State<Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<Entrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  late final CurvedAnimation _curve = CurvedAnimation(
    parent: _controller,
    curve: NGMotion.emphasized,
  );
  bool _scheduled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_scheduled) return;
    _scheduled = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
      return;
    }
    Future<void>.delayed(widget.delayPerItem * widget.index, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curve,
      builder: (context, child) => Opacity(
        opacity: _curve.value,
        child: Transform.translate(
          offset: Offset(0, (1 - _curve.value) * widget.offset),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}

/// Animated integer readout: counts toward [value] whenever it changes.
/// Keeps calorie and macro numbers feeling alive without layout shift.
class AnimatedCount extends StatelessWidget {
  const AnimatedCount({
    super.key,
    required this.value,
    this.style,
    this.suffix = '',
    this.duration = const Duration(milliseconds: 550),
  });

  final num value;
  final TextStyle? style;
  final String suffix;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: value.toDouble()),
      duration: NGMotion.of(context, duration),
      curve: NGMotion.standard,
      builder: (context, animated, _) => Text(
        '${animated.round()}$suffix',
        style: style,
      ),
    );
  }
}

/// Fade-through transition between bottom-navigation destinations
/// (Material 3 top-level transition pattern).
class FadeThroughSwitcher extends StatelessWidget {
  const FadeThroughSwitcher({
    super.key,
    required this.switchKey,
    required this.child,
  });

  final Object switchKey;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return AnimatedSwitcher(
      duration: NGMotion.normal,
      switchInCurve: const Interval(0.35, 1, curve: Curves.easeOutCubic),
      switchOutCurve: const Interval(0.65, 1, curve: Curves.easeInCubic),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween(begin: 0.985, end: 1.0).animate(animation),
          child: child,
        ),
      ),
      child: KeyedSubtree(key: ValueKey(switchKey), child: child),
    );
  }
}
