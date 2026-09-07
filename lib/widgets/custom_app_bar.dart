import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../app/theme.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBackButton;
  final bool centerTitle;
  final Color? backgroundColor;
  final double? elevation;
  final Widget? titleWidget;
  final VoidCallback? onBackPressed;
  final bool showDivider;
  final bool isTransparent;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.showBackButton = false,
    this.centerTitle = true,
    this.backgroundColor,
    this.elevation,
    this.titleWidget,
    this.onBackPressed,
    this.showDivider = false,
    this.isTransparent = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? (isTransparent ? Colors.transparent : AppTheme.primary),
        boxShadow: elevation != null && elevation! > 0
            ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ]
            : null,
        border: showDivider
            ? Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.06),
            width: 1,
          ),
        )
            : null,
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: kToolbarHeight + (showDivider ? 0 : 0),
          child: Row(
            children: [
              // Leading Widget
              if (showBackButton || leading != null) ...[
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  child: showBackButton
                      ? _buildBackButton(context)
                      : leading!,
                ),
              ],

              // Title
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: showBackButton || leading != null ? 8 : 16,
                  ),
                  child: titleWidget ??
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: isTransparent
                              ? Colors.white
                              : (isDark ? Colors.white : Colors.white),
                          letterSpacing: -0.5,
                        ),
                        textAlign: centerTitle ? TextAlign.center : TextAlign.start,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                ),
              ),

              // Actions
              if (actions != null && actions!.isNotEmpty)
                Row(
                  children: actions!.map((action) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      child: action,
                    );
                  }).toList(),
                )
              else
                const SizedBox(width: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
          width: 1,
        ),
      ),
      child: IconButton(
        icon: Icon(
          Icons.arrow_back_rounded,
          color: Colors.white.withOpacity(0.9),
          size: 22,
        ),
        onPressed: onBackPressed ?? () => Navigator.pop(context),
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(),
        splashRadius: 20,
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight + (showDivider ? 0 : 0));
}

// ============================================================
// PREMIUM ANIMATED APP BAR
// ============================================================

class PremiumAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBackButton;
  final bool centerTitle;
  final Widget? titleWidget;
  final VoidCallback? onBackPressed;
  final double scrollOffset;

  const PremiumAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showBackButton = false,
    this.centerTitle = true,
    this.titleWidget,
    this.onBackPressed,
    this.scrollOffset = 0,
  });

  @override
  State<PremiumAppBar> createState() => _PremiumAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(120);
}

class _PremiumAppBarState extends State<PremiumAppBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(
      begin: 0.6,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _glowController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final opacity = (widget.scrollOffset / 100).clamp(0.0, 1.0);
    final expandedHeight = 120 - (widget.scrollOffset * 0.3).clamp(0.0, 50.0);

    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        return Container(
          height: expandedHeight,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF38804f),
                const Color(0xFF1d3b27),
                const Color(0xFF1d3b27),
                const Color(0xFF38804f),
              ],
              stops: const [0.0, 0.35, 0.70, 1.0],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF49e8c3).withOpacity(0.1 * _glowAnimation.value),
                blurRadius: 30,
                spreadRadius: 10,
              ),
            ],
          ),
          child: SafeArea(
            bottom: false,
            child: Stack(
              children: [
                // Animated glow overlay
                Positioned(
                  top: -50,
                  right: -50,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF6C63FF).withOpacity(0.1 * _glowAnimation.value),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -50,
                  left: -50,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF4D96FF).withOpacity(0.08 * _glowAnimation.value),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          if (widget.showBackButton)
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.12 * (1 - opacity)),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.08 * (1 - opacity)),
                                  width: 1,
                                ),
                              ),
                              child: IconButton(
                                icon: Icon(
                                  Icons.arrow_back_rounded,
                                  color: Colors.white.withOpacity(0.9 * (1 - opacity)),
                                  size: 22,
                                ),
                                onPressed: widget.onBackPressed ?? () => Navigator.pop(context),
                                padding: const EdgeInsets.all(8),
                                constraints: const BoxConstraints(),
                                splashRadius: 20,
                              ),
                            ),
                          Expanded(
                            child: Center(
                              child: Opacity(
                                opacity: 1 - opacity,
                                child: Column(
                                  children: [
                                    Text(
                                      widget.title,
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      width: 40,
                                      height: 3,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFF49e8c3), Color(0xFF31b999)],
                                        ),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          if (widget.actions != null && widget.actions!.isNotEmpty)
                            Row(
                              children: widget.actions!.map((action) {
                                return Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.08 * (1 - opacity)),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.04 * (1 - opacity)),
                                      width: 1,
                                    ),
                                  ),
                                  child: action,
                                );
                              }).toList(),
                            )
                          else
                            const SizedBox(width: 48),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ============================================================
// GLASS MORPHISM APP BAR
// ============================================================

class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBackButton;
  final bool centerTitle;
  final Widget? titleWidget;
  final VoidCallback? onBackPressed;

  const GlassAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showBackButton = false,
    this.centerTitle = true,
    this.titleWidget,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.08),
            Colors.white.withOpacity(0.02),
          ],
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(24),
        ),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.06),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Container(
          height: kToolbarHeight,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              if (showBackButton)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.04),
                      width: 1,
                    ),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white.withOpacity(0.8),
                      size: 22,
                    ),
                    onPressed: onBackPressed ?? () => Navigator.pop(context),
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                    splashRadius: 20,
                  ),
                ),
              Expanded(
                child: Center(
                  child: titleWidget ??
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                        textAlign: centerTitle ? TextAlign.center : TextAlign.start,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                ),
              ),
              if (actions != null && actions!.isNotEmpty)
                Row(
                  children: actions!.map((action) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: action,
                    );
                  }).toList(),
                )
              else
                const SizedBox(width: 48),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}