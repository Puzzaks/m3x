import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Plug-and-play velocity-based directional motion blur container (Sameera Essentials style).
///
/// Features:
/// 1. **Directional Trailing Streak**: Calculates velocity direction (+/-) and applies
///    an asymmetric trailing translation offset behind the motion vector so blur
///    feels truly directional instead of a sterile symmetric double-vision smear.
/// 2. **Axis Isolation**: Strictly filters out orthogonal axis notifications so
///    horizontal tab sliding (such as in [TabBarView]) never triggers vertical blur.
/// 3. **Plug and play**: Behaves like a standard container. Automatically discovers
///    and binds to the nearest enclosing [Scrollable] (via context) OR catches
///    bubbling [ScrollNotification]s from child scrollables without requiring
///    manual controllers or listeners.
/// 4. **Content-only blur isolation**: In sliver layouts (e.g. [CustomScrollView] with
///    [SliverAppBar.large]), wrapping only the content inside [SliverToBoxAdapter]
///    keeps the expanding app bar title and actions completely static, crisp, and
///    jitter-free while blurring only the scrolling content cards.
/// 5. **Smooth physics ticker**: Interpolates blur dynamically with exponential
///    decay over ~120ms, eliminating 1-frame flickering and abrupt visual cutoffs.
/// 6. **Zero-overhead 120 FPS idle rendering**: Uses [ImageFiltered.enabled] set to `false`
///    when idle, completely bypassing offscreen GPU layer passes to eliminate frame rate caps.
class MotionBlurContainer extends StatefulWidget {
  final Widget child;
  final bool enabled;
  final double blurFactor;
  final double maxBlur;
  final double speedThreshold;
  final Axis direction;
  final bool listenToAncestor;

  const MotionBlurContainer({
    super.key,
    required this.child,
    this.enabled = true,
    this.blurFactor = 0.0035,
    this.maxBlur = 8.0,
    this.speedThreshold = 280.0,
    this.direction = Axis.vertical,
    this.listenToAncestor = true,
  });

  @override
  State<MotionBlurContainer> createState() => _MotionBlurContainerState();
}

class _MotionBlurContainerState extends State<MotionBlurContainer>
    with SingleTickerProviderStateMixin {
  final ValueNotifier<double> _sigmaNotifier = ValueNotifier<double>(0.0);
  late final Ticker _decayTicker;
  ScrollPosition? _scrollPosition;
  DateTime? _lastTimestamp;
  double _lastPixels = 0.0;
  double _currentBlur = 0.0;
  double _targetBlur = 0.0;
  double _velocityDirection = 1.0; // 1.0 = scrolling forward/down, -1.0 = scrolling back/up

  @override
  void initState() {
    super.initState();
    _decayTicker = createTicker(_onDecayTick);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _attachToAncestorScrollPosition();
  }

  @override
  void didUpdateWidget(covariant MotionBlurContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.listenToAncestor != widget.listenToAncestor) {
      _attachToAncestorScrollPosition();
    }
  }

  void _attachToAncestorScrollPosition() {
    final newPosition =
        widget.listenToAncestor ? Scrollable.maybeOf(context)?.position : null;
    if (newPosition != _scrollPosition) {
      _scrollPosition?.removeListener(_onScrollPositionChanged);
      _scrollPosition?.isScrollingNotifier.removeListener(_onIsScrollingChanged);
      _scrollPosition = newPosition;
      _scrollPosition?.addListener(_onScrollPositionChanged);
      _scrollPosition?.isScrollingNotifier.addListener(_onIsScrollingChanged);
    }
  }

  void _onScrollPositionChanged() {
    if (!widget.enabled || _scrollPosition == null) return;
    // Strictly ignore scroll events from opposite axis (e.g. horizontal tab swipes)
    if (_scrollPosition!.axis != widget.direction) return;

    final now = DateTime.now();
    final pixels = _scrollPosition!.pixels;
    _updateVelocity(pixels, now);
  }

  void _onIsScrollingChanged() {
    if (_scrollPosition?.isScrollingNotifier.value == false) {
      _lastTimestamp = null;
      _targetBlur = 0.0;
    }
  }

  void _onDecayTick(Duration elapsed) {
    if (!mounted) return;

    // Smoothly decay target blur
    _targetBlur *= 0.88;

    // Smoothly interpolate current blur towards target
    _currentBlur = _currentBlur + (_targetBlur - _currentBlur) * 0.28;

    if (_currentBlur < 0.15 && _targetBlur < 0.15) {
      _currentBlur = 0.0;
      _targetBlur = 0.0;
      if (_decayTicker.isActive) {
        _decayTicker.stop();
      }
      if (_sigmaNotifier.value != 0.0) {
        _sigmaNotifier.value = 0.0;
      }
    } else {
      _sigmaNotifier.value = _currentBlur;
    }
  }

  void _updateVelocity(double pixels, DateTime now) {
    if (_lastTimestamp != null) {
      final elapsedUs = now.difference(_lastTimestamp!).inMicroseconds;
      if (elapsedUs >= 2000) {
        final elapsedSec = elapsedUs / 1000000.0;
        final delta = pixels - _lastPixels;
        final speed = delta.abs() / elapsedSec;

        if (delta != 0) {
          _velocityDirection = delta > 0 ? 1.0 : -1.0;
        }

        if (speed > widget.speedThreshold) {
          final target = ((speed - widget.speedThreshold) * widget.blurFactor)
              .clamp(0.0, widget.maxBlur);
          _targetBlur = target;
          if (_currentBlur < target) {
            _currentBlur = _currentBlur + (target - _currentBlur) * 0.55;
          }
          if (!_decayTicker.isActive) {
            _decayTicker.start();
          }
        }
        _lastTimestamp = now;
        _lastPixels = pixels;
      }
    } else {
      _lastTimestamp = now;
      _lastPixels = pixels;
    }
  }

  bool _onScrollNotification(ScrollNotification notification) {
    if (!widget.enabled) return false;
    // Ignore bubbling scroll events from deeper nested scrollables.
    if (notification.depth != 0) return false;

    // Strictly ignore scroll events from opposite axis (e.g. horizontal tab swipes in TabBarView)
    if (notification.metrics.axis != widget.direction) return false;

    if (notification is ScrollStartNotification) {
      _lastPixels = notification.metrics.pixels;
      _lastTimestamp = null;
    } else if (notification is ScrollUpdateNotification) {
      final now = DateTime.now();
      final pixels = notification.metrics.pixels;
      _updateVelocity(pixels, now);
    } else if (notification is ScrollEndNotification) {
      _lastTimestamp = null;
      _targetBlur = 0.0;
    }
    return false; // Allow notification to continue bubbling
  }

  @override
  void dispose() {
    _scrollPosition?.removeListener(_onScrollPositionChanged);
    _scrollPosition?.isScrollingNotifier.removeListener(_onIsScrollingChanged);
    _decayTicker.dispose();
    _sigmaNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    return NotificationListener<ScrollNotification>(
      onNotification: _onScrollNotification,
      child: ValueListenableBuilder<double>(
        valueListenable: _sigmaNotifier,
        builder: (context, sigma, child) {
          final bool isBlurring = sigma >= 0.15;
          final double sigmaX = widget.direction == Axis.horizontal ? sigma : 0.0;
          final double sigmaY = widget.direction == Axis.vertical ? sigma : 0.0;

          // Directional trailing streak: shifts blurred texture slightly behind motion vector
          final double trailShift = -_velocityDirection * (sigma * 0.38);
          final Offset trailOffset = widget.direction == Axis.vertical
              ? Offset(0.0, trailShift)
              : Offset(trailShift, 0.0);

          // Zero GPU offscreen texture passes when idle!
          return Transform.translate(
            offset: isBlurring ? trailOffset : Offset.zero,
            child: ImageFiltered(
              enabled: isBlurring,
              imageFilter: isBlurring
                  ? ImageFilter.blur(sigmaX: sigmaX, sigmaY: sigmaY)
                  : ImageFilter.blur(sigmaX: 0.0, sigmaY: 0.0),
              child: child!,
            ),
          );
        },
        child: RepaintBoundary(child: widget.child),
      ),
    );
  }
}

/// Backwards-compatible alias for [MotionBlurContainer].
typedef MotionBlurScrollView = MotionBlurContainer;
