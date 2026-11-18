import '../legal/legal_screen.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _floatingController;
  late AnimationController _pulseController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _fadeAnimation = CurvedAnimation(
      parent: _mainController,
      curve: Curves.easeOut,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.94,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: Curves.easeOutBack,
      ),
    );

    _mainController.forward();
  }

  @override
  void dispose() {
    _mainController.dispose();
    _floatingController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0A2A),
      body: AnimatedBuilder(
        animation: _floatingController,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Stack(
                children: [
                  // FULL SCREEN BACKGROUND
                  Positioned.fill(
                    child: _buildBackground(size),
                  ),

                  // CONTENT
                  SafeArea(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: size.height,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 20),

                              // LOGO
                              _buildLogo(),

                              const SizedBox(height: 38),

                              // WELCOME
                              _buildWelcome(),

                              const SizedBox(height: 28),

                              // CUSTOMER
                              _buildRoleCard(
                                icon: Icons.person_outline_rounded,
                                title: 'Customer',
                                subtitle:
                                'Find trusted services &\nbook professionals',
                                gradient: const [
                                  Color(0xFF6BCB77),
                                  Color(0xFF2ECC71),
                                ],
                                glowColor: const Color(0xFF6BCB77),
                                delay: 0,
                                onTap: () {
                                  context.push(
                                    '/login',
                                    extra: {'role': 'user'},
                                  );
                                },
                              ),

                              const SizedBox(height: 14),

                              // SERVICE PROVIDER
                              _buildRoleCard(
                                icon: Icons.work_outline_rounded,
                                title: 'Service Provider',
                                subtitle:
                                'Offer your services &\ngrow your business',
                                gradient: const [
                                  Color(0xFF4D96FF),
                                  Color(0xFF6C63FF),
                                ],
                                glowColor: const Color(0xFF6C63FF),
                                delay: 120,
                                onTap: () {
                                  context.push(
                                    '/login',
                                    extra: {'role': 'provider'},
                                  );
                                },
                              ),

                              const SizedBox(height: 14),

                              // BUSINESS OWNER
                              _buildRoleCard(
                                icon: Icons.storefront_outlined,
                                title: 'Business Owner',
                                subtitle:
                                'Register your business &\nsell products',
                                gradient: const [
                                  Color(0xFFFF6B6B),
                                  Color(0xFFFF8E8E),
                                ],
                                glowColor: const Color(0xFFFF6B6B),
                                delay: 240,
                                onTap: () {
                                  context.push(
                                    '/login',
                                    extra: {'role': 'business'},
                                  );
                                },
                              ),

                              const SizedBox(height: 28),

                              // BOTTOM
                              _buildBottomSection(),

                              const SizedBox(height: 8),
                              const LegalLinksRow(),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );  }

  // ---------------------------------------------------------------------------
  // BACKGROUND
  // ---------------------------------------------------------------------------

  Widget _buildBackground(Size size) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            // Main gradient - Modern deep blue-purple
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

            // Top-right soft glow
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



            // Bottom-left glow
            Positioned(
              bottom: -150,
              left: -120,
              child: Container(
                width: 350,
                height: 350,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF4D96FF).withOpacity(0.12),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Floating accent circles
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
            AnimatedBuilder(
              animation: _floatingController,
              builder: (context, child) {
                final value = math.sin(
                  _floatingController.value * math.pi * 2,
                );

                return Positioned(
                  bottom: 50 + value * 15, // Mirrored: bottom instead of top
                  left: 30,                 // Mirrored: left instead of right
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

            // Small floating dot
            AnimatedBuilder(
              animation: _floatingController,
              builder: (context, child) {
                final value = math.cos(
                  _floatingController.value * math.pi * 2 + 1.5,
                );
                return Positioned(
                  bottom: 120 + value * 12,
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

            // Dot pattern top-right
            Positioned(
              top: 80,
              right: 20,
              child: _buildDotPattern(
                rows: 4,
                columns: 4,
                spacing: 18,
              ),
            ),

            Positioned(
              bottom: 100,
              right: 16,
              child: _buildDotPattern(
                rows: 4,
                columns: 4,
                spacing: 18,
              ),
            ),


            // Dot pattern bottom-left
            Positioned(
              bottom: 100,
              left: 16,
              child: _buildDotPattern(
                rows: 4,
                columns: 4,
                spacing: 18,
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

  // ---------------------------------------------------------------------------
  // LOGO
  // ---------------------------------------------------------------------------

  Widget _buildLogo() {
    return Row(
      children: [
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.12),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              'assets/icon.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.location_on_rounded,
                  color: Colors.white,
                  size: 32,
                );
              },
            ),
          ),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ProNear',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                shadows: [
                  Shadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Local Services, Near You',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12.5,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // WELCOME
  // ---------------------------------------------------------------------------

  Widget _buildWelcome() {
    return

      Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Welcome!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 38,
                fontWeight: FontWeight.w800,
                letterSpacing: -1.2,
                height: 1.05,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '👋',
              style: TextStyle(
                fontSize: 32,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'Choose how you want to get started',
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 16.5,
            fontWeight: FontWeight.w400,
            height: 1.45,
            letterSpacing: 0.1,
          ),
        ),
        Text(
          'with ProNear',
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 16.5,
            fontWeight: FontWeight.w400,
            height: 1.45,
            letterSpacing: 0.1,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // ROLE CARD
  // ---------------------------------------------------------------------------

  Widget _buildRoleCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> gradient,
    required Color glowColor,
    required int delay,
    required VoidCallback onTap,
  }) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + delay),
      curve: Curves.easeOutBack,
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 25 * (1 - value)),
          child: Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: _RoleCard(
        icon: icon,
        title: title,
        subtitle: subtitle,
        gradient: gradient,
        glowColor: glowColor,
        onTap: onTap,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // BOTTOM
  // ---------------------------------------------------------------------------

  Widget _buildBottomSection() {
    return Column(
      children: [
        // === DIVIDER WITH TEXT ===
        Row(
          children: [
            Expanded(
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.white.withOpacity(0.12),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Text(
              'Already have an account?',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 13,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.12),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // === SIGN IN BUTTON (Animated) ===
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: StatefulBuilder(
            builder: (context, setState) {
              bool _isHovered = false;
              bool _isPressed = false;

              return GestureDetector(
                onTapDown: (_) => setState(() => _isPressed = true),
                onTapCancel: () => setState(() => _isPressed = false),
                onTapUp: (_) {
                  setState(() => _isPressed = false);
                  context.push('/login');
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  transform: Matrix4.identity()
                    ..scale(_isPressed ? 0.96 : 1.0)
                    ..translate(0.0, _isHovered ? -2.0 : 0.0), // ✅ Fixed: added .0 to make them doubles
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF49e8c3),
                        Color(0xFF31b999),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF49e8c3).withOpacity(0.3),
                        blurRadius: _isHovered ? 30 : 20,
                        spreadRadius: _isHovered ? 4 : 0,
                        offset: Offset(0, _isHovered ? 8 : 6),
                      ),
                      BoxShadow(
                        color: const Color(0xFF49e8c3).withOpacity(0.1),
                        blurRadius: 60,
                        spreadRadius: 10,
                      ),
                    ],
                    border: Border.all(
                      color: Colors.white.withOpacity(_isHovered ? 0.2 : 0.05),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Sign In',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 10),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        transform: Matrix4.identity()
                          ..translate(_isHovered ? 4.0 : 0.0, 0.0), // ✅ Fixed: added .0 to make them doubles
                        child: const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 8),

        // === SUBTLE ANIMATED DECORATIVE DOTS ===
        AnimatedBuilder(
          animation: _floatingController,
          builder: (context, child) {
            final opacity = 0.3 + (0.15 * (1 + math.sin(
              _floatingController.value * math.pi * 2 + 0.5,
            )) / 2);
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                final delay = index * 0.3;
                final scale = 0.6 + (0.4 * (1 + math.sin(
                  _floatingController.value * math.pi * 2 + delay,
                )) / 2);
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6 + index * 2),
                  child: Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(opacity),
                      ),
                    ),
                  ),
                );
              }),
            );
          },
        ),
      ],
    );
  }}

// =============================================================================
// ROLE CARD WIDGET
// =============================================================================
class _RoleCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final Color glowColor;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.glowColor,
    required this.onTap,
  });

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? 0.975 : 1.0,
      duration: const Duration(milliseconds: 120),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap();
        },
        child: Container(
          height: 100, // Fixed professional height
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.12),
                Colors.white.withOpacity(0.04),
              ],
            ),
            border: Border.all(
              color: widget.glowColor.withOpacity(0.25),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: widget.glowColor.withOpacity(0.08),
                blurRadius: 20,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon Container
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: widget.gradient,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.glowColor.withOpacity(0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  widget.icon,
                  color: Colors.white,
                  size: 28,
                ),
              ),

              const SizedBox(width: 14),

              // Text Content
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow Button
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: widget.gradient,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.glowColor.withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}