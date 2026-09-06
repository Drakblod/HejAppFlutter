import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late final AnimationController _backgroundController;

  @override
  void initState() {
    super.initState();
    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) {
      _backgroundController.stop();
      _backgroundController.value = 0;
    } else if (!_backgroundController.isAnimating) {
      _backgroundController.repeat();
    }
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password')),
      );
      return;
    }

    await ref.read(authControllerProvider.notifier).login(email, password);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<void>>(authControllerProvider, (previous, next) {
      next.whenOrNull(
        error: (error, _) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(error.toString())));
        },
      );
    });

    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _backgroundController,
              builder: (context, _) => CustomPaint(
                painter: _LivingBackgroundPainter(
                  progress: _backgroundController.value,
                ),
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 880;
                return Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1040),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x26173F28),
                              blurRadius: 54,
                              offset: Offset(0, 22),
                            ),
                          ],
                        ),
                        child: isWide
                            ? Row(
                                children: [
                                  const Expanded(child: _LoginStory()),
                                  Expanded(
                                    child: _buildForm(context, isLoading),
                                  ),
                                ],
                              )
                            : _buildForm(context, isLoading),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(BuildContext context, bool isLoading) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 42, vertical: 48),
      child: AutofillGroup(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFF225C32),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.chat_bubble_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Hej',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            Text(
              'Welcome back',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.8,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Sign in to open your spaces.',
              style: TextStyle(color: Colors.black54, fontSize: 16),
            ),
            const SizedBox(height: 28),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.mail_outline_rounded),
              ),
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              textInputAction: TextInputAction.next,
              enabled: !isLoading,
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                prefixIcon: Icon(Icons.lock_outline_rounded),
              ),
              obscureText: true,
              autofillHints: const [AutofillHints.password],
              textInputAction: TextInputAction.done,
              onSubmitted: isLoading ? null : (_) => _onLogin(),
              enabled: !isLoading,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: isLoading ? null : _onLogin,
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Sign in'),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: isLoading ? null : () => context.push('/register'),
              child: const Text('New to Hej? Create an account'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LivingBackgroundPainter extends CustomPainter {
  final double progress;

  const _LivingBackgroundPainter({required this.progress});

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

    final angle = progress * math.pi * 2;
    _drawGlow(
      canvas,
      Offset(
        size.width * (0.12 + math.sin(angle) * 0.035),
        size.height * (0.22 + math.cos(angle * 0.8) * 0.05),
      ),
      size.shortestSide * 0.34,
      const Color(0xFF75B887),
    );
    _drawGlow(
      canvas,
      Offset(
        size.width * (0.88 + math.cos(angle * 0.7) * 0.035),
        size.height * (0.20 + math.sin(angle * 0.9) * 0.045),
      ),
      size.shortestSide * 0.27,
      const Color(0xFFF0C987),
    );
    _drawGlow(
      canvas,
      Offset(
        size.width * (0.80 + math.sin(angle * 0.65) * 0.045),
        size.height * (0.84 + math.cos(angle * 0.75) * 0.04),
      ),
      size.shortestSide * 0.31,
      const Color(0xFF8FB8B1),
    );

    _drawFloatingBubble(
      canvas,
      Offset(
        size.width * (0.06 + math.sin(angle * 0.55) * 0.018),
        size.height * (0.72 + math.cos(angle * 0.6) * 0.035),
      ),
      46,
      angle,
    );
    _drawFloatingBubble(
      canvas,
      Offset(
        size.width * (0.91 + math.cos(angle * 0.5) * 0.02),
        size.height * (0.57 + math.sin(angle * 0.55) * 0.035),
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
          colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0)],
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
    return oldDelegate.progress != progress;
  }
}

class _LoginStory extends StatelessWidget {
  const _LoginStory();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 620),
      padding: const EdgeInsets.all(50),
      decoration: const BoxDecoration(
        color: Color(0xFF173F28),
        borderRadius: BorderRadius.horizontal(left: Radius.circular(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'YOUR SPACE. YOUR WAY.',
              style: TextStyle(
                color: Color(0xFFD8F3DC),
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
              ),
            ),
          ),
          const SizedBox(height: 26),
          Text(
            'One flexible home for every group.',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              height: 1.08,
              letterSpacing: -1.5,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Choose the modules you need, shape the look, and keep your community focused on what matters.',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.white70, height: 1.5),
          ),
          const SizedBox(height: 38),
          const Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _FeatureChip(
                icon: Icons.chat_bubble_outline_rounded,
                label: 'Chat',
              ),
              _FeatureChip(icon: Icons.calendar_month_outlined, label: 'Plans'),
              _FeatureChip(icon: Icons.folder_open_rounded, label: 'Files'),
              _FeatureChip(
                icon: Icons.photo_library_outlined,
                label: 'Memories',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeatureChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        border: Border.all(color: Colors.white12),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFFD8F3DC), size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
