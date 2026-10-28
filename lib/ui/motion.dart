import 'package:brahma_core/brahma_core.dart';
import 'package:flutter/material.dart';

/// Vinyasa's motion: pages rise and settle into place, cards give a little
/// under a finger, and everything holds still when the system asks for
/// less motion.

/// A page that fades in while it grows from 94% and rises 24 px, and the
/// page below sinks back a little.
Route<T> fluidRoute<T>(Widget page) => PageRouteBuilder<T>(
  transitionDuration: const Duration(milliseconds: 420),
  reverseTransitionDuration: const Duration(milliseconds: 300),
  pageBuilder: (_, _, _) => page,
  transitionsBuilder: (context, animation, secondary, child) {
    if (Motion.reduced(context)) return child;
    final into = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutQuart,
      reverseCurve: Curves.easeInCubic,
    );
    final under = CurvedAnimation(parent: secondary, curve: Curves.easeOutCubic);
    return AnimatedBuilder(
      animation: Listenable.merge([into, under]),
      child: child,
      builder: (context, child) {
        final t = into.value, s = under.value;
        return Opacity(
          opacity: t.clamp(0, 1),
          child: Transform.translate(
            offset: Offset(0, 24 * (1 - t)),
            child: Transform.scale(scale: (0.94 + 0.06 * t) * (1 - 0.03 * s), child: child),
          ),
        );
      },
    );
  },
);

/// Shrinks its child a touch while pressed, and springs back.
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.child, required this.onTap, this.onLongPress});
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool down) {
    if (down != _down) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown: (_) => _set(true),
    onTapUp: (_) => _set(false),
    onTapCancel: () => _set(false),
    onTap: widget.onTap,
    onLongPress: widget.onLongPress,
    child: AnimatedScale(
      scale: _down ? 0.97 : 1,
      duration: Motion.reduced(context) ? Duration.zero : const Duration(milliseconds: 160),
      curve: _down ? Curves.easeOut : Curves.elasticOut,
      child: widget.child,
    ),
  );
}

/// The children of a list, each fading in a little after the one before.
List<Widget> staggered(List<Widget> children, {int stepMs = 45, int cap = 8}) => [
  for (final (i, c) in children.indexed)
    FadeIn(
      delay: Duration(milliseconds: stepMs * i.clamp(0, cap)),
      child: c,
    ),
];
