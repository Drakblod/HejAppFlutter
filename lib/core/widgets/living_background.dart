import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A decorative, non-interactive backdrop shared by the entry screens.
class LivingBackground extends StatefulWidget {
  const LivingBackground({super.key, required this.child});

  final Widget child;

  @override
  State<LivingBackground> createState() => _LivingBackgroundState();
}

class _LivingBackgroundState extends State<LivingBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 24),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
      _controller.value = 0;
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: ExcludeSemantics(
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: _LivingBackgroundPainter(_controller),
                ),
              ),
            ),
          ),
        ),
        RepaintBoundary(child: widget.child),
      ],
    );
  }
}

class _LivingBackgroundPainter extends CustomPainter {
  final Animation<double> animation;

  _LivingBackgroundPainter(this.animation) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF1F6F1), Color(0xFFDFEBE1)],
        ).createShader(bounds),
    );

    final angle = animation.value * math.pi * 2;
    _drawGlow(
      canvas,
      Offset(
        size.width * (0.12 + math.sin(angle) * 0.035),
        size.height * (0.22 + math.cos(angle) * 0.05),
      ),
      size.shortestSide * 0.34,
      const Color(0xFF75B887),
    );
    _drawGlow(
      canvas,
      Offset(
        size.width * (0.88 + math.cos(angle) * 0.035),
        size.height * (0.20 + math.sin(angle) * 0.045),
      ),
      size.shortestSide * 0.27,
      const Color(0xFFF0C987),
    );
    _drawGlow(
      canvas,
      Offset(
        size.width * (0.80 + math.sin(angle) * 0.045),
        size.height * (0.84 + math.cos(angle) * 0.04),
      ),
      size.shortestSide * 0.31,
      const Color(0xFF8FB8B1),
    );

    _drawFloatingBubble(
      canvas,
      Offset(
        size.width * (0.06 + math.sin(angle) * 0.018),
        size.height * (0.72 + math.cos(angle) * 0.035),
      ),
      46,
      angle,
    );
    _drawFloatingBubble(
      canvas,
      Offset(
        size.width * (0.91 + math.cos(angle) * 0.02),
        size.height * (0.57 + math.sin(angle) * 0.035),
      ),
      34,
      -angle,
    );
  }

  void _drawGlow(Canvas canvas, Offset center, double radius, Color color) {
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [color.withValues(alpha: 0.32), color.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
  }

  void _drawFloatingBubble(
    Canvas canvas,
    Offset center,
    double radius,
    double rotation,
  ) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(math.sin(rotation) * 0.08);

    final bubbleRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset.zero,
        width: radius * 2.15,
        height: radius * 1.45,
      ),
      Radius.circular(radius * 0.44),
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = const Color(0xFF225C32).withValues(alpha: 0.12);
    canvas.drawRRect(bubbleRect, paint);

    final tail = Path()
      ..moveTo(radius * 0.35, radius * 0.67)
      ..quadraticBezierTo(
        radius * 0.48,
        radius * 0.92,
        radius * 0.72,
        radius * 0.94,
      )
      ..quadraticBezierTo(
        radius * 0.55,
        radius * 0.76,
        radius * 0.52,
        radius * 0.61,
      );
    canvas.drawPath(tail, paint);

    for (var index = -1; index <= 1; index++) {
      canvas.drawCircle(
        Offset(index * radius * 0.36, 0),
        radius * 0.075,
        Paint()..color = const Color(0xFF225C32).withValues(alpha: 0.14),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LivingBackgroundPainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
}
