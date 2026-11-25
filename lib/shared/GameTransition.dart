
import 'package:flutter/material.dart';
import 'dart:math' as math;

class CircleRevealClipper extends CustomClipper<Path> {
  final Offset center;
  final double fraction;

  CircleRevealClipper({required this.center, required this.fraction});

  static double _calcMaxRadius(Size size, Offset center){
    final width = math.max(center.dx, size.width - center.dx);
    final height = math.max(center.dy, size.height - center.dy);
    return math.sqrt(width * width + height * height);
  }

  @override
  Path getClip(Size size) {
    final double maxRadius = _calcMaxRadius(size, center);
    final double radius = maxRadius * fraction;

    return Path()..addOval(Rect.fromCircle(center: center, radius: radius));
  }

  @override
  bool shouldReclip(covariant CircleRevealClipper oldClipper) {
    return oldClipper.fraction != fraction || oldClipper.center != center;
  }
}

class CircleRevealPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final Offset center;

  CircleRevealPageRoute({
    required this.page,
    required this.center,
    Duration duration = const Duration(milliseconds: 500),
  }) : super(
        transitionDuration: duration,
        reverseTransitionDuration: duration,
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curvedAnimation = CurvedAnimation(
            parent: animation, 
            curve: Curves.easeInOutCubic,
          );

          return ClipPath(
            clipper: CircleRevealClipper(center: center, fraction: curvedAnimation.value),
            child: child,
          );
        },
      );
}

class CirclePulseTransition extends StatefulWidget{
  final Widget child;
  final Color circleColor = Colors.white;

  const CirclePulseTransition({super.key, required this.child});

  static CirclePulseTransitionState of(BuildContext context) {
    final state = context.findAncestorStateOfType<CirclePulseTransitionState>();
    if (state == null) {
      throw FlutterError('CirclePulseTransition not found above this context.');
    }
    return state;
  }

  @override
  State<StatefulWidget> createState() => CirclePulseTransitionState();
}

class CirclePulseTransitionState extends State<CirclePulseTransition> with SingleTickerProviderStateMixin{
  late final AnimationController _controller;
  late final Animation<double> _radiusFraction;
  Offset _center = Offset.zero;
  VoidCallback? _onMidPoint;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500)
    )..addListener(_checkMidPoint);

    _radiusFraction = TweenSequence<double>(
      [
        TweenSequenceItem(
          tween: Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeInCubic)),
          weight: 0.1
        ),

        TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 0.0), 
          weight: 0.1
        )
      ]
    ).animate(_controller);
  }

  void _checkMidPoint() {
    if (_controller.value >= 0.5 && _onMidPoint != null) {
      final callback = _onMidPoint;
      _onMidPoint = null;
      callback!();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void trigger(Offset tapPosition, {VoidCallback? onMidPoint}){
    if (_controller.isAnimating) return;
    final box = context.findRenderObject()! as RenderBox;
    setState(() {
      _center = box.globalToLocal(tapPosition);
      _onMidPoint = onMidPoint;
    });
    _controller.forward(from: 0.0);
  }
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        Positioned.fill(child: AnimatedBuilder(
          animation: _radiusFraction,
          builder:(context, _) {
            if (!_controller.isAnimating) return const SizedBox.shrink();
            return AbsorbPointer(
              child: ClipPath(
                clipper: CircleRevealClipper(
                  center: _center, 
                  fraction: _radiusFraction.value
                ),
                child: Container(
                  color: widget.circleColor,
                  alignment: Alignment.center,
                ),
              )
            );
          },
        ))
      ],
    );
  }
  
}