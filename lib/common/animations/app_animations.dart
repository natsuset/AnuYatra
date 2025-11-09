import 'package:flutter/material.dart';

/// Animation durations following Material Design motion guidelines
class AppAnimations {
  AppAnimations._();

  // ============================================
  // ANIMATION DURATIONS
  // ============================================

  /// Extra fast - For very subtle animations
  static const Duration instant = Duration(milliseconds: 100);

  /// Fast - For simple transitions
  static const Duration fast = Duration(milliseconds: 200);

  /// Normal - Standard animations
  static const Duration normal = Duration(milliseconds: 300);

  /// Medium - For more complex animations
  static const Duration medium = Duration(milliseconds: 400);

  /// Slow - For emphasis or complex choreography
  static const Duration slow = Duration(milliseconds: 500);

  /// Very slow - For special emphasis
  static const Duration verySlow = Duration(milliseconds: 700);

  // ============================================
  // ANIMATION CURVES
  // ============================================

  /// Standard easing - Most common curve
  static const Curve standard = Curves.easeInOut;

  /// Deceleration - Element entering screen
  static const Curve decelerate = Curves.easeOut;

  /// Acceleration - Element leaving screen
  static const Curve accelerate = Curves.easeIn;

  /// Sharp - Quick and decisive movement
  static const Curve sharp = Curves.easeInOutCubic;

  /// Bounce - Playful entrance
  static const Curve bounce = Curves.bounceOut;

  /// Elastic - Spring-like motion
  static const Curve elastic = Curves.elasticOut;

  /// Emphasized - Material 3 emphasized easing
  static const Curve emphasized = Curves.easeInOutCubicEmphasized;

  // ============================================
  // PAGE TRANSITION BUILDERS
  // ============================================

  /// Fade transition
  static Widget fadeTransition(
    BuildContext context,
    Animation<double> animation,
    Widget child,
  ) {
    return FadeTransition(opacity: animation, child: child);
  }

  /// Slide from right transition
  static Widget slideFromRightTransition(
    BuildContext context,
    Animation<double> animation,
    Widget child,
  ) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: decelerate)),
      child: child,
    );
  }

  /// Slide from bottom transition
  static Widget slideFromBottomTransition(
    BuildContext context,
    Animation<double> animation,
    Widget child,
  ) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.0, 1.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: decelerate)),
      child: child,
    );
  }

  /// Scale transition
  static Widget scaleTransition(
    BuildContext context,
    Animation<double> animation,
    Widget child,
  ) {
    return ScaleTransition(
      scale: CurvedAnimation(parent: animation, curve: emphasized),
      child: child,
    );
  }

  /// Fade and scale transition
  static Widget fadeScaleTransition(
    BuildContext context,
    Animation<double> animation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: animation,
      child: ScaleTransition(
        scale: Tween<double>(
          begin: 0.8,
          end: 1.0,
        ).animate(CurvedAnimation(parent: animation, curve: decelerate)),
        child: child,
      ),
    );
  }

  // ============================================
  // STAGGERED ANIMATION HELPERS
  // ============================================

  /// Calculate staggered delay for list items
  static Duration staggerDelay(
    int index, {
    Duration baseDelay = const Duration(milliseconds: 50),
  }) {
    return Duration(milliseconds: baseDelay.inMilliseconds * index);
  }

  /// Create interval for staggered animation
  static Interval staggeredInterval(
    int index,
    int totalItems, {
    Curve curve = Curves.easeOut,
  }) {
    final intervalSize = 1.0 / totalItems;
    final begin = intervalSize * index;
    final end = begin + intervalSize;
    return Interval(begin, end, curve: curve);
  }
}

/// Animated widget that fades in and slides up when appearing
class FadeInUp extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final Curve curve;
  final double offset;

  const FadeInUp({
    super.key,
    required this.child,
    this.duration = AppAnimations.normal,
    this.delay = Duration.zero,
    this.curve = AppAnimations.decelerate,
    this.offset = 20.0,
  });

  @override
  State<FadeInUp> createState() => _FadeInUpState();
}

class _FadeInUpState extends State<FadeInUp>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, widget.offset),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));

    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Transform.translate(
        offset: _slideAnimation.value,
        child: widget.child,
      ),
    );
  }
}

/// Animated widget that scales in when appearing
class ScaleIn extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final Curve curve;
  final double initialScale;

  const ScaleIn({
    super.key,
    required this.child,
    this.duration = AppAnimations.normal,
    this.delay = Duration.zero,
    this.curve = AppAnimations.emphasized,
    this.initialScale = 0.8,
  });

  @override
  State<ScaleIn> createState() => _ScaleInState();
}

class _ScaleInState extends State<ScaleIn> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);

    _scaleAnimation = Tween<double>(
      begin: widget.initialScale,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));

    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(scale: _scaleAnimation, child: widget.child),
    );
  }
}

/// Widget that animates its child with a shimmer effect
class ShimmerLoading extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Color? baseColor;
  final Color? highlightColor;

  const ShimmerLoading({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1500),
    this.baseColor,
    this.highlightColor,
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor =
        widget.baseColor ?? (isDark ? Colors.grey[800]! : Colors.grey[300]!);
    final highlightColor =
        widget.highlightColor ??
        (isDark ? Colors.grey[700]! : Colors.grey[100]!);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [baseColor, highlightColor, baseColor],
              stops: [
                _controller.value - 0.3,
                _controller.value,
                _controller.value + 0.3,
              ].map((e) => e.clamp(0.0, 1.0)).toList(),
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}
