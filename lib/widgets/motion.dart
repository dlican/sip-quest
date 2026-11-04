import 'package:flutter/material.dart';

import '../services/fx.dart';

/// Shared motion: one set of durations and curves for every transition, so
/// dialogs, sheets, pages and in-game phase changes all feel alike.
class Motion {
  static const fast = Duration(milliseconds: 180);
  static const medium = Duration(milliseconds: 280);
  static const slow = Duration(milliseconds: 420);

  static const enter = Curves.easeOutCubic;
  static const exit = Curves.easeInCubic;
  static const pop = Curves.easeOutBack;
}

/// Opens a dialog that grows out of the centre with a soft fade, and shrinks
/// back on dismiss. Used instead of [showDialog] everywhere.
Future<T?> showPixelDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool dismissible = true,
}) {
  Fx.open();
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: dismissible,
    barrierLabel: 'Dismiss',
    barrierColor: const Color(0xB3000000),
    transitionDuration: Motion.medium,
    pageBuilder: (context, _, _) => SafeArea(child: Builder(builder: builder)),
    transitionBuilder: (context, anim, _, child) {
      final fade = CurvedAnimation(parent: anim, curve: Motion.enter, reverseCurve: Motion.exit);
      final grow = CurvedAnimation(parent: anim, curve: Motion.pop, reverseCurve: Motion.exit);
      return FadeTransition(
        opacity: fade,
        child: ScaleTransition(scale: Tween(begin: 0.86, end: 1.0).animate(grow), child: child),
      );
    },
  ).whenComplete(Fx.close);
}

/// Slides a panel up from the bottom edge (used for how-to-play and settings).
Future<T?> showPixelSheet<T>({required BuildContext context, required WidgetBuilder builder}) {
  Fx.open();
  return Navigator.of(context)
      .push<T>(
        PageRouteBuilder<T>(
          opaque: false,
          barrierDismissible: true,
          barrierLabel: 'Dismiss',
          barrierColor: const Color(0xB3000000),
          transitionDuration: Motion.slow,
          reverseTransitionDuration: Motion.medium,
          pageBuilder: (context, _, _) => Align(
            alignment: Alignment.bottomCenter,
            child: Builder(builder: builder),
          ),
          transitionsBuilder: (context, anim, _, child) {
            final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutQuart, reverseCurve: Motion.exit);
            return SlideTransition(
              position: Tween(begin: const Offset(0, 1), end: Offset.zero).animate(curved),
              child: child,
            );
          },
        ),
      )
      .whenComplete(Fx.close);
}

/// Cross-fades between game phases with a slight rise, instead of the old
/// hard cut. Give each phase's child a distinct [ValueKey].
class PhaseSwitcher extends StatelessWidget {
  const PhaseSwitcher({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: Motion.medium,
      reverseDuration: Motion.fast,
      switchInCurve: Motion.enter,
      switchOutCurve: Motion.exit,
      layoutBuilder: (current, previous) =>
          Stack(alignment: Alignment.topCenter, fit: StackFit.expand, children: [...previous, ?current]),
      transitionBuilder: (child, anim) => _IgnoreWhileLeaving(
        animation: anim,
        child: FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween(begin: const Offset(0, 0.025), end: Offset.zero).animate(anim),
            child: ScaleTransition(scale: Tween(begin: 0.98, end: 1.0).animate(anim), child: child),
          ),
        ),
      ),
      child: child,
    );
  }
}

/// Stops taps landing on a phase that is fading out (no double actions).
class _IgnoreWhileLeaving extends AnimatedWidget {
  const _IgnoreWhileLeaving({required Animation<double> animation, required this.child}) : super(listenable: animation);
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final s = (listenable as Animation<double>).status;
    return IgnorePointer(ignoring: s == AnimationStatus.reverse || s == AnimationStatus.dismissed, child: child);
  }
}

/// Pops a value in (scale + fade) whenever [value] changes: results, scores.
class PopIn extends StatelessWidget {
  const PopIn({super.key, required this.value, required this.child});
  final Object? value;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: Motion.medium,
      switchInCurve: Motion.pop,
      switchOutCurve: Motion.exit,
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: ScaleTransition(scale: Tween(begin: 0.8, end: 1.0).animate(anim), child: child),
      ),
      child: KeyedSubtree(key: ValueKey(value), child: child),
    );
  }
}

/// Page transition: the new page glides in from the right while fading up,
/// the old one drifts left and dims. Smooth easing replaces the old stepped
/// 8-bit slide, which read as choppy on a 120 Hz screen.
class SmoothPageTransition extends PageTransitionsBuilder {
  const SmoothPageTransition();

  @override
  Duration get transitionDuration => const Duration(milliseconds: 340);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 280);

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondary,
    Widget child,
  ) {
    final inCurve = CurvedAnimation(parent: animation, curve: Curves.easeOutQuart, reverseCurve: Curves.easeInCubic);
    final outCurve = CurvedAnimation(parent: secondary, curve: Curves.easeOutQuart, reverseCurve: Curves.easeInCubic);
    return SlideTransition(
      position: Tween(begin: Offset.zero, end: const Offset(-0.18, 0)).animate(outCurve),
      child: FadeTransition(
        opacity: Tween(begin: 1.0, end: 0.4).animate(outCurve),
        child: SlideTransition(
          position: Tween(begin: const Offset(0.35, 0), end: Offset.zero).animate(inCurve),
          child: FadeTransition(opacity: inCurve, child: child),
        ),
      ),
    );
  }
}
