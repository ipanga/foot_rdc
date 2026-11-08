import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Whether the bottom tab bar is shown, driven by the vertical scrolling of the visible tab.
///
/// Reading further down (finger moving up) hides the bar; going back up shows it. Small movements are ignored: the
/// direction must be held for [threshold] logical pixels. The bar always shows at the top and at the end of the
/// content, on content too short to need the room, on tab changes and when returning from another screen
/// (see [show]). One listener at the app shell covers every tab, so screens need no code of their own.
class BottomBarVisibility extends ValueNotifier<bool> {
  BottomBarVisibility() : super(true);

  /// Distance in one direction before the bar reacts.
  static const threshold = 28.0;

  /// Content that scrolls less than this never hides the bar (a short Plus menu, an empty state).
  static const minScrollable = 160.0;

  /// Edge zone treated as "at the top" or "at the end".
  static const edge = 8.0;

  double _travel = 0;

  void show() {
    _travel = 0;
    value = true;
  }

  /// Feeds a scroll notification from the tab body. Returns false so the notification keeps bubbling.
  bool onScroll(ScrollNotification n) {
    final m = n.metrics;
    if (m.axis != Axis.vertical || n is! ScrollUpdateNotification) return false;
    if (m.maxScrollExtent - m.minScrollExtent < minScrollable ||
        m.pixels <= m.minScrollExtent + edge ||
        m.pixels >= m.maxScrollExtent - edge) {
      show();
      return false;
    }
    final delta = n.scrollDelta ?? 0;
    if (delta == 0) return false;
    // A change of direction starts counting again, so a tremor never adds up to a toggle.
    if (_travel != 0 && delta.sign != _travel.sign) _travel = 0;
    _travel += delta;
    if (_travel > threshold && value) {
      value = false;
      _travel = 0;
    } else if (_travel < -threshold && !value) {
      show();
    }
    return false;
  }
}

/// Slides [child] (the bottom bar, safe area included) down out of view when [visibility] is false. The slot shrinks
/// with it, so the page gains the room without content moving. Instant when the system asks for reduced motion;
/// never hidden while a screen reader is on, so the tabs stay reachable.
class AutoHideBottomBar extends StatefulWidget {
  final ValueListenable<bool> visibility;
  final Widget child;
  const AutoHideBottomBar({super.key, required this.visibility, required this.child});

  static const duration = Duration(milliseconds: 220);

  @override
  State<AutoHideBottomBar> createState() => _AutoHideBottomBarState();
}

class _AutoHideBottomBarState extends State<AutoHideBottomBar> with SingleTickerProviderStateMixin {
  late final AnimationController _shown = AnimationController(
    vsync: this,
    duration: AutoHideBottomBar.duration,
    value: widget.visibility.value ? 1 : 0,
  );
  late final Animation<double> _curve = CurvedAnimation(
    parent: _shown,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );

  @override
  void initState() {
    super.initState();
    widget.visibility.addListener(_update);
  }

  @override
  void didUpdateWidget(AutoHideBottomBar old) {
    super.didUpdateWidget(old);
    if (old.visibility != widget.visibility) {
      old.visibility.removeListener(_update);
      widget.visibility.addListener(_update);
      _update();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.accessibleNavigationOf(context)) _shown.value = 1;
  }

  void _update() {
    final show = widget.visibility.value || MediaQuery.accessibleNavigationOf(context);
    if (MediaQuery.disableAnimationsOf(context)) {
      _shown.value = show ? 1 : 0;
    } else if (show) {
      _shown.forward();
    } else {
      _shown.reverse();
    }
  }

  @override
  void dispose() {
    widget.visibility.removeListener(_update);
    _shown.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _curve,
    child: widget.child,
    builder: (context, child) {
      final shown = _curve.value;
      return ClipRect(
        child: Align(
          alignment: Alignment.topCenter,
          heightFactor: shown,
          // Hidden tabs can't be tapped or focused.
          child: IgnorePointer(
            ignoring: shown < 0.5,
            child: ExcludeFocus(excluding: shown < 0.5, child: child!),
          ),
        ),
      );
    },
  );
}
