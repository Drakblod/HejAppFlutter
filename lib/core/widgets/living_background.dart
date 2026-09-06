import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A decorative, non-interactive backdrop shared by the entry screens.
class LivingBackground extends StatefulWidget {
  const LivingBackground({super.key, required this.child, this.dark = false});

  final Widget child;
  final bool dark;

  @override
  State<LivingBackground> createState() => _LivingBackgroundState();
}

class _LivingBackgroundState extends State<LivingBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 20),
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
      fit: StackFit.passthrough,
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: ExcludeSemantics(
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: _LivingBackgroundPainter(
                    _controller,
                    dark: widget.dark,
                  ),
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
  final bool dark;

  _LivingBackgroundPainter(this.animation, {required this.dark})
    : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark
              ? const [Color(0xFF123621), Color(0xFF245A3C)]
              : const [Color(0xFFF0F7EF), Color(0xFFDFEEE7)],
        ).createShader(bounds),
    );

    final angle = animation.value * math.pi * 2;
    _drawGlow(
      canvas,
      Offset(
        size.width * (0.22 + math.sin(angle) * 0.18),
        size.height * (0.30 + math.cos(angle) * 0.18),
      ),
      size.longestSide * 0.38,
      const Color(0xFF75B887),
    );
    _drawGlow(
      canvas,
      Offset(
        size.width * (0.78 + math.cos(angle) * 0.16),
        size.height * (0.28 + math.sin(angle) * 0.18),
      ),
      size.longestSide * 0.30,
      dark ? const Color(0xFF83C9A1) : const Color(0xFFF0C987),
    );
    _drawGlow(
      canvas,
      Offset(
        size.width * (0.65 + math.sin(angle + 2) * 0.22),
        size.height * (0.72 + math.cos(angle + 2) * 0.20),
      ),
      size.longestSide * 0.36,
      const Color(0xFF8FB8B1),
    );

    _drawWaves(canvas, size, angle);

    // Travel a full screen per cycle; wrap outside the viewport with a fade.
    // Edge lanes keep bubbles visible around the opaque space cards.
    const lanes = [0.025, 0.975, 0.14, 0.87, 0.04, 0.96, 0.52];
    final count = dark ? 4 : lanes.length;
    for (var i = 0; i < count; i++) {
      final phase = (animation.value + i / count) % 1;
      final fade = (math.sin(phase * math.pi) * 3).clamp(0.0, 1.0);
      final radius = dark
          ? (size.height * 0.14).clamp(18.0, 32.0)
          : (size.width * 0.065).clamp(28.0, 58.0) + (i % 3) * 7;
      final lane = dark ? 0.64 + i * 0.10 : lanes[i];
      _drawFloatingBubble(
        canvas,
        Offset(
          size.width * lane + math.sin(angle + i * 1.7) * (dark ? 16 : 30),
          size.height + radius * 2 - phase * (size.height + radius * 4),
        ),
        radius * (1 + math.sin(angle * 2 + i) * 0.06),
        angle + i,
        fade,
      );
    }

    // Small drifting lights add movement in the gaps between larger shapes.
    for (var i = 0; i < (dark ? 8 : 16); i++) {
      final phase = (animation.value + i * 0.618) % 1;
      final opacity = math.sin(phase * math.pi) * (dark ? 0.18 : 0.24);
      canvas.drawCircle(
        Offset(
          size.width * ((i * 0.382) % 1) + math.sin(angle + i) * 18,
          size.height * (1 - phase),
        ),
        2 + (i % 3).toDouble(),
        Paint()
          ..color = (dark ? const Color(0xFFCEF3D5) : const Color(0xFF4A9470))
              .withValues(alpha: opacity),
      );
    }
  }

  void _drawWaves(Canvas canvas, Size size, double angle) {
    for (var layer = 0; layer < 3; layer++) {
      final path = Path();
      final baseline = size.height * (0.30 + layer * 0.25);
      for (var step = 0; step <= 40; step++) {
        final x = size.width * step / 40;
        final y =
            baseline +
            math.sin(step / 40 * math.pi * 2 + angle + layer * 1.8) *
                size.height *
                0.12;
        if (step == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
      path.close();
      canvas.drawPath(
        path,
        Paint()
          ..color = (dark ? const Color(0xFF97D9AE) : const Color(0xFF75BBA0))
              .withValues(alpha: dark ? 0.045 : 0.055),
      );
    }
  }

  void _drawGlow(Canvas canvas, Offset center, double radius, Color color) {
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: dark ? 0.12 : 0.38),
            color.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
  }

  void _drawFloatingBubble(
    Canvas canvas,
    Offset center,
    double radius,
    double rotation,
    double opacity,
  ) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(math.sin(rotation) * 0.14);

    final bubbleRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset.zero,
        width: radius * 2.15,
        height: radius * 1.45,
      ),
      Radius.circular(radius * 0.44),
    );
    final color = dark ? const Color(0xFFC5F0D3) : const Color(0xFF347854);
    canvas.drawRRect(
      bubbleRect,
      Paint()..color = color.withValues(alpha: opacity * 0.035),
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..color = color.withValues(alpha: opacity * (dark ? 0.16 : 0.24));
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
        Offset(
          index * radius * 0.36,
          math.sin(rotation * 4 - index * 0.8) * radius * 0.055,
        ),
        radius * 0.075,
        Paint()..color = color.withValues(alpha: opacity * 0.28),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LivingBackgroundPainter oldDelegate) {
    return oldDelegate.animation != animation || oldDelegate.dark != dark;
  }
}
