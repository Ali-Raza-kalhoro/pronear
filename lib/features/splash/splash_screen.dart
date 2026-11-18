import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../provider/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _entranceController;
  late AnimationController _glowController;
  late AnimationController _ringController;
  late AnimationController _shimmerController;

  // Background animation controllers
  late AnimationController _pulseController;
  late AnimationController _floatingController;

  late Animation<double> _logoOpacity;
  late Animation<double> _logoScale;
  late Animation<Offset> _logoPosition;

  late Animation<double> _brandOpacity;
  late Animation<Offset> _brandPosition;

  late Animation<double> _taglineOpacity;
  late Animation<Offset> _taglinePosition;

  @override
  void initState() {
    super.initState();

    // ============================================================
    // ENTRANCE
    // ============================================================

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );

    // ============================================================
    // SOFT GLOW
    // ============================================================

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    // ============================================================
    // RING ROTATION
    // ============================================================

    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    // ============================================================
    // SHIMMER
    // ============================================================

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    // ============================================================
    // BACKGROUND ANIMATIONS
    // ============================================================

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    // ============================================================
    // LOGO ANIMATION
    // ============================================================

    _logoOpacity = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(
        0.0,
        0.28,
        curve: Curves.easeOut,
      ),
    );

    _logoScale = Tween<double>(
      begin: 0.68,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(
          0.0,
          0.48,
          curve: Curves.easeOutBack,
        ),
      ),
    );

    _logoPosition = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(
          0.0,
          0.45,
          curve: Curves.easeOutCubic,
        ),
      ),
    );

    // ============================================================
    // BRAND ANIMATION
    // ============================================================

    _brandOpacity = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(
        0.30,
        0.62,
        curve: Curves.easeOut,
      ),
    );

    _brandPosition = Tween<Offset>(
      begin: const Offset(0, 0.20),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(
          0.28,
          0.65,
          curve: Curves.easeOutCubic,
        ),
      ),
    );

    // ============================================================
    // TAGLINE
    // ============================================================

    _taglineOpacity = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(
        0.55,
        0.82,
        curve: Curves.easeOut,
      ),
    );

    _taglinePosition = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(
          0.52,
          0.82,
          curve: Curves.easeOutCubic,
        ),
      ),
    );

    _entranceController.forward();

    _checkAuth();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _glowController.dispose();
    _ringController.dispose();
    _shimmerController.dispose();
    _pulseController.dispose();
    _floatingController.dispose();

    super.dispose();
  }

  // ============================================================
  // AUTH CHECK - 8 SECONDS DELAY
  // ============================================================

  Future<void> _checkAuth() async {
    // Show splash screen for minimum 2.5 seconds
    await Future.delayed(const Duration(milliseconds: 2500));

    if (!mounted) return;

    final authProvider = context.read<AuthProvider>();
    final session = Supabase.instance.client.auth.currentSession;

    if (session != null) {
      try {
        // ✅ Load user profile from database
        await authProvider.loadUserProfile();

        if (!mounted) return;

        // ✅ Verify user exists in database
        final user = await Supabase.instance.client
            .from('users')
            .select('id, role')
            .eq('id', session.user.id)
            .maybeSingle();

        if (user == null) {
          // ❌ User not found in database - this shouldn't happen for real users
          // Sign out and go to role selection
          debugPrint('⚠️ User not found in database, signing out...');
          await authProvider.logout();
          if (mounted) {
            context.go('/role-selection');
          }
          return;
        }

        // ✅ User exists - get role
        String? role = user['role'] as String?;

        // If role is 'business', treat as 'provider'
        final isUnfinishedBusiness = role == 'business';
        if (role == 'business') {
          role = 'provider';
        }

        debugPrint('🔍 SplashScreen - User role: $role');

        // ✅ Navigate based on role
        if (role == 'provider') {
          final hasCV = await _checkProviderCV(session.user.id);
          if (!mounted) return;

          if (hasCV) {
            context.go('/provider/dashboard');
          } else if (isUnfinishedBusiness) {
            context.go('/business/type');
          } else {
            context.go('/provider/cv');
          }
        } else {
          // User role
          context.go('/user/home');
        }
      } catch (e) {
        debugPrint('❌ Error during auth check: $e');
        // On error, go to role selection
        if (mounted) {
          context.go('/role-selection');
        }
      }
    } else {
      // ❌ No session - go to role selection
      debugPrint('🔍 No session found - navigating to role selection');
      if (mounted) {
        context.go('/role-selection');
      }
    }
  }

  Future<bool> _checkProviderCV(String userId) async {
    try {
      final response = await Supabase
          .instance
          .client
          .from('providers')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      debugPrint('CV check error: $e');
      return false;
    }
  }
  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFF),
      body: Stack(
        children: [
          // ------------------------------------------------------
          // BACKGROUND (SAME AS ROLE SELECTION)
          // ------------------------------------------------------

          _buildBackground(size),

          // ------------------------------------------------------
          // MAIN CONTENT
          // ------------------------------------------------------

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: size.height -
                        MediaQuery.of(context).padding.vertical,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLogo(),

                      SizedBox(
                        height: size.height < 700 ? 24 : 34,
                      ),

                      _buildBrandName(),

                      const SizedBox(height: 16),

                      _buildTagline(),

                      SizedBox(
                        height: size.height < 700 ? 40 : 58,
                      ),

                      _buildLoading(),

                      const SizedBox(height: 28),

                      _buildBottomLabel(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BACKGROUND (SAME AS ROLE SELECTION)
  // ============================================================

  Widget _buildBackground(Size size) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            // Main gradient - Modern deep green
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF38804f),
                    Color(0xFF1d3b27),
                    Color(0xFF1d3b27),
                    Color(0xFF38804f),
                  ],
                  stops: [0.0, 0.35, 0.70, 1.0],
                ),
              ),
            ),

            // Top-right soft glow (pulsing)
            Positioned(
              top: -120,
              right: -100,
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final opacity = 0.15 + (0.08 * (1 + math.sin(
                    _pulseController.value * math.pi * 2,
                  )) / 2);
                  return Container(
                    width: 350,
                    height: 350,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF6C63FF).withOpacity(opacity),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Bottom-left glow (pulsing with offset)
            Positioned(
              bottom: -150,
              left: -120,
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final opacity = 0.12 + (0.06 * (1 + math.sin(
                    _pulseController.value * math.pi * 2 + 1.0,
                  )) / 2);
                  return Container(
                    width: 350,
                    height: 350,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF4D96FF).withOpacity(opacity),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Center subtle glow
            Positioned(
              top: size.height * 0.3,
              left: size.width * 0.2,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withOpacity(0.03),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.6],
                  ),
                ),
              ),
            ),

            // Floating accent circle - top-right
            AnimatedBuilder(
              animation: _floatingController,
              builder: (context, child) {
                final value = math.sin(
                  _floatingController.value * math.pi * 2,
                );
                return Positioned(
                  top: 140 + value * 15,
                  right: 30,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.04),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.06),
                        width: 1.5,
                      ),
                    ),
                  ),
                );
              },
            ),

            // Floating accent circle - bottom-left (mirrored)
            AnimatedBuilder(
              animation: _floatingController,
              builder: (context, child) {
                final value = math.sin(
                  _floatingController.value * math.pi * 2 + 1.0,
                );
                return Positioned(
                  bottom: 140 + value * 15,
                  left: 30,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.04),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.06),
                        width: 1.5,
                      ),
                    ),
                  ),
                );
              },
            ),

            // Small floating dot - bottom-left
            AnimatedBuilder(
              animation: _floatingController,
              builder: (context, child) {
                final value = math.cos(
                  _floatingController.value * math.pi * 2 + 1.5,
                );
                return Positioned(
                  bottom: 100 + value * 12,
                  left: 20,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.08),
                    ),
                  ),
                );
              },
            ),

            // Small floating dot - top-right
            AnimatedBuilder(
              animation: _floatingController,
              builder: (context, child) {
                final value = math.cos(
                  _floatingController.value * math.pi * 2 + 2.5,
                );
                return Positioned(
                  top: 100 + value * 12,
                  right: 20,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.08),
                    ),
                  ),
                );
              },
            ),

            // Small floating dot - center-right
            AnimatedBuilder(
              animation: _floatingController,
              builder: (context, child) {
                final value = math.sin(
                  _floatingController.value * math.pi * 2 + 0.5,
                );
                return Positioned(
                  top: size.height * 0.45 + value * 10,
                  right: 40,
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.05),
                    ),
                  ),
                );
              },
            ),

            // Small floating dot - center-left
            AnimatedBuilder(
              animation: _floatingController,
              builder: (context, child) {
                final value = math.cos(
                  _floatingController.value * math.pi * 2 + 2.0,
                );
                return Positioned(
                  top: size.height * 0.55 + value * 10,
                  left: 40,
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.05),
                    ),
                  ),
                );
              },
            ),

            // Dot pattern - top-right
            Positioned(
              top: 80,
              right: 20,
              child: _buildDotPattern(
                rows: 4,
                columns: 4,
                spacing: 18,
              ),
            ),

            // Dot pattern - bottom-left
            Positioned(
              bottom: 100,
              left: 16,
              child: _buildDotPattern(
                rows: 4,
                columns: 4,
                spacing: 18,
              ),
            ),

            // Dot pattern - bottom-right
            Positioned(
              bottom: 100,
              right: 16,
              child: _buildDotPattern(
                rows: 3,
                columns: 3,
                spacing: 16,
              ),
            ),

            // Dot pattern - top-left
            Positioned(
              top: 80,
              left: 20,
              child: _buildDotPattern(
                rows: 3,
                columns: 3,
                spacing: 16,
              ),
            ),

            // Decorative horizontal lines
            Positioned(
              top: size.height * 0.5,
              right: -50,
              child: Container(
                width: 200,
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                    colors: [
                      Colors.white.withOpacity(0.06),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            Positioned(
              top: size.height * 0.5,
              left: -50,
              child: Container(
                width: 200,
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.white.withOpacity(0.06),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDotPattern({
    required int rows,
    required int columns,
    required double spacing,
  }) {
    return SizedBox(
      width: columns * spacing,
      height: rows * spacing,
      child: Column(
        children: List.generate(
          rows,
              (row) {
            return Row(
              children: List.generate(
                columns,
                    (column) {
                  final isEven = (row + column) % 2 == 0;
                  return Container(
                    width: isEven ? 4 : 2.5,
                    height: isEven ? 4 : 2.5,
                    margin: EdgeInsets.only(
                      right: spacing - 4,
                      bottom: spacing - 4,
                    ),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(
                        isEven ? 0.35 : 0.055,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  // ============================================================
  // LOGO
  // ============================================================

  Widget _buildLogo() {
    return SlideTransition(
      position: _logoPosition,
      child: FadeTransition(
        opacity: _logoOpacity,
        child: ScaleTransition(
          scale: _logoScale,
          child: AnimatedBuilder(
            animation: Listenable.merge([
              _glowController,
              _ringController,
            ]),
            builder: (context, child) {
              final glow = 0.75 + (_glowController.value * 0.25);

              return SizedBox(
                width: 255,
                height: 255,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Soft shadow / glow
                    Container(
                      width: 185 * glow,
                      height: 185 * glow,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6D28D9)
                                .withOpacity(0.13),
                            blurRadius: 75,
                            spreadRadius: 18,
                          ),
                          BoxShadow(
                            color: const Color(0xFF2563EB)
                                .withOpacity(0.10),
                            blurRadius: 95,
                            spreadRadius: 12,
                          ),
                        ],
                      ),
                    ),

                    // Rotating ring
                    Transform.rotate(
                      angle: _ringController.value * math.pi * 2,
                      child: CustomPaint(
                        size: const Size(245, 245),
                        painter: PremiumRingPainter(),
                      ),
                    ),

                    // Second ring
                    Transform.rotate(
                      angle: -_ringController.value * math.pi * 2,
                      child: CustomPaint(
                        size: const Size(215, 215),
                        painter: SecondaryRingPainter(),
                      ),
                    ),

                    // Logo image
                    Container(
                      width: 185,
                      height: 185,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF111936)
                                .withOpacity(0.10),
                            blurRadius: 35,
                            offset: const Offset(0, 16),
                          ),
                          BoxShadow(
                            color: const Color(0xFF7048E8)
                                .withOpacity(0.08),
                            blurRadius: 20,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(100),
                          child: Image.asset(
                            'assets/logo.jpeg',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.location_on_rounded,
                                size: 75,
                                color: Color(0xFF7048E8),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BRAND NAME
  // ============================================================

  Widget _buildBrandName() {
    return SlideTransition(
      position: _brandPosition,
      child: FadeTransition(
        opacity: _brandOpacity,
        child: AnimatedBuilder(
          animation: _shimmerController,
          builder: (context, child) {
            final position = _shimmerController.value;

            return ShaderMask(
              shaderCallback: (bounds) {
                return LinearGradient(
                  begin: Alignment(-1.0 + position * 2, 0),
                  end: Alignment(1.0 + position * 2, 0),
                  colors: const [
                    Color(0xFF111936),
                    Color(0xFF111936),
                    Color(0xFF6D28D9),
                    Color(0xFF2563EB),
                    Color(0xFF111936),
                  ],
                  stops: const [
                    0.0,
                    0.30,
                    0.48,
                    0.62,
                    1.0,
                  ],
                ).createShader(bounds);
              },
              child: const Text(
                'ProNear',
                style: TextStyle(
                  fontSize: 45,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  height: 1,
                  color: Colors.white,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ============================================================
  // TAGLINE
  // ============================================================

  Widget _buildTagline() {
    return SlideTransition(
      position: _taglinePosition,
      child: FadeTransition(
        opacity: _taglineOpacity,
        child: Column(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _smallLine(),
                const SizedBox(width: 12),
                const Text(
                  'NEAR YOU',
                  style: TextStyle(
                    color: Color(0xFF5A6078),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.5,
                  ),
                ),
                const SizedBox(width: 12),
                _smallLine(),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'Trusted services. Right when you need them.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF747A90),
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.35,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _smallLine() {
    return Container(
      width: 28,
      height: 2,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF6D28D9),
            Color(0xFF2563EB),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // LOADING
  // ============================================================

  Widget _buildLoading() {
    return FadeTransition(
      opacity: _taglineOpacity,
      child: AnimatedBuilder(
        animation: _glowController,
        builder: (context, child) {
          return Column(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  3,
                      (index) {
                    final animation = math.sin(
                      (_glowController.value * math.pi * 2) + index * 1.4,
                    );

                    final scale = 0.75 + ((animation + 1) / 2) * 0.5;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Transform.scale(
                        scale: scale,
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF6D28D9),
                                Color(0xFF2563EB),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6D28D9)
                                    .withOpacity(0.20),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 13),
              const Text(
                'CONNECTING YOU',
                style: TextStyle(
                  color: Color(0xFF9A9EAF),
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.2,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ============================================================
  // BOTTOM LABEL
  // ============================================================

  Widget _buildBottomLabel() {
    return FadeTransition(
      opacity: _taglineOpacity,
      child: Column(
        children: [
          Text(
            'LOCAL SERVICES • TRUSTED PROFESSIONALS',
            style: TextStyle(
              color: const Color(0xFF171A3A).withOpacity(0.28),
              fontSize: 8,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'v1.0.0',
            style: TextStyle(
              color: const Color(0xFF171A3A).withOpacity(0.18),
              fontSize: 10,
              fontWeight: FontWeight.w500,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// PREMIUM OUTER RING
// ============================================================

class PremiumRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.43;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..shader = const SweepGradient(
        colors: [
          Colors.transparent,
          Color(0xFF6D28D9),
          Color(0xFF8B5CF6),
          Color(0xFF2563EB),
          Colors.transparent,
        ],
        stops: [0.0, 0.25, 0.48, 0.70, 1.0],
      ).createShader(rect);

    canvas.drawArc(rect, -0.65, math.pi * 1.55, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

// ============================================================
// SECONDARY RING
// ============================================================

class SecondaryRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.44;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF7048E8).withOpacity(0.16);

    canvas.drawArc(rect, 0.8, math.pi * 0.85, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}