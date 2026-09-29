import 'package:flutter/material.dart';
import 'package:melo/auth/auth.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  late Animation<double> _logoFade;
  late Animation<double> _logoScale;
  late Animation<double> _textFade;

  @override
  void initState() {
    super.initState();

    // =========================
    // ANIMATION CONTROLLER
    // =========================

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    // =========================
    // LOGO FADE
    // =========================

    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.45, curve: Curves.easeIn),
      ),
    );

    // =========================
    // LOGO SCALE
    // =========================

    _logoScale = Tween<double>(begin: 0.70, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOutCubic),
      ),
    );

    // =========================
    // TEXT FADE
    // =========================

    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.40, 1.0, curve: Curves.easeIn),
      ),
    );

    _startAnimation();
  }

  // =========================
  // START SPLASH
  // =========================

  Future<void> _startAnimation() async {
    // Play logo + text animation
    await _controller.forward();

    // Keep the completed splash on screen
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    // =========================
    // GO TO AUTH PAGE
    // =========================

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const AuthPage()),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,

      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // =========================
              // LOGO
              // =========================
              FadeTransition(
                opacity: _logoFade,
                child: ScaleTransition(
                  scale: _logoScale,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Image.asset(
                      'assets/logo.jpg',

                      width: 180,
                      height: 180,

                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // =========================
              // TEXT
              // =========================
              FadeTransition(
                opacity: _textFade,
                child: Column(
                  children: [
                    Text(
                      'M E L O',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 7,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      'Developed by Siddharth Alok',
                      style: TextStyle(
                        fontSize: 14,
                        letterSpacing: 0.5,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
