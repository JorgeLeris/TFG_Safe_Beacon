import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:safe_beacon/core/language/l10n/app_localizations.dart';

/// Possible states of the panic button.
enum PanicButtonState {
  /// Normal: ready to be triggered.
  normal,

  /// Disabled: non-interactable.
  disabled,

  /// Active: showing the deactivate option.
  active,
}

/// Reusable panic button widget with animations and visual states.
class PanicButton extends StatefulWidget {
  final PanicButtonState state;
  final VoidCallback? onPressed;

  /// Button diameter. Defaults to 175.
  final double size;

  const PanicButton({
    super.key,
    required this.state,
    this.onPressed,
    this.size = 175,
  });

  @override
  State<PanicButton> createState() => _PanicButtonState();
}

class _PanicButtonState extends State<PanicButton>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _ringController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _ringAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _ringAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ringController, curve: Curves.easeOut));

    _updateAnimations();
  }

  @override
  void didUpdateWidget(PanicButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      _updateAnimations();
    }
  }

  /// Starts or stops animations depending on the current state.
  void _updateAnimations() {
    if (widget.state == PanicButtonState.active) {
      _pulseController.repeat(reverse: true);
      _ringController.repeat();
    } else {
      _pulseController.stop();
      _pulseController.reset();
      _ringController.stop();
      _ringController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _ringController.dispose();
    super.dispose();
  }

  /// Returns the color set for the current state.
  _ButtonColors _colors(bool isDark) {
    switch (widget.state) {
      case PanicButtonState.normal:
        return _ButtonColors(
          outerRing: const Color(0xFFFF1744),
          outerRingGlow: const Color(0xFFFF1744).withValues(alpha: 0.15),
          middleRing: const Color(0xFFD50000),
          innerButton: const Color(0xFFB71C1C),
          innerButtonCenter: const Color(0xFFFF1744),
          contentColor: Colors.white,
          shadowColor: const Color(0xFFFF1744).withValues(alpha: 0.5),
          borderGlow: const Color(
            0xFFFF6D6D,
          ).withValues(alpha: isDark ? 0.2 : 1.0),
        );
      case PanicButtonState.disabled:
        return _ButtonColors(
          outerRing: const Color(0xFF9E9E9E),
          outerRingGlow: Colors.transparent,
          middleRing: const Color(0xFF757575),
          innerButton: const Color(0xFF616161),
          innerButtonCenter: const Color(0xFF757575),
          contentColor: const Color(0xFFBDBDBD),
          shadowColor: Colors.transparent,
          borderGlow: const Color(
            0xFF9E9E9E,
          ).withValues(alpha: isDark ? 0.5 : 1.0),
        );
      case PanicButtonState.active:
        return _ButtonColors(
          outerRing: const Color(0xFFFF6D00),
          outerRingGlow: const Color(0xFFFF6D00).withValues(alpha: 0.3),
          middleRing: const Color(0xFFE65100),
          innerButton: const Color(0xFFBF360C),
          innerButtonCenter: const Color(0xFFFF6D00),
          contentColor: Colors.white,
          shadowColor: const Color(0xFFFF6D00).withValues(alpha: 0.6),
          borderGlow: const Color(
            0xFFFFAB40,
          ).withValues(alpha: isDark ? 0.2 : 1.0),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = _colors(isDark);
    final isDisabled = widget.state == PanicButtonState.disabled;
    final isActive = widget.state == PanicButtonState.active;
    final s = widget.size;

    return GestureDetector(
      onTap: isDisabled ? null : widget.onPressed,
      child: AnimatedBuilder(
        animation: Listenable.merge([_pulseAnimation, _ringAnimation]),
        builder: (context, child) {
          return SizedBox(
            width: s * 1.45,
            height: s * 1.45,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Expanding ring animation — only visible when active
                if (isActive)
                  _ExpandingRing(
                    progress: _ringAnimation.value,
                    size: s,
                    color: colors.outerRing,
                  ),

                // Soft outer glow halo
                Container(
                  width: s * 1.4,
                  height: s * 1.4,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        colors.outerRingGlow,
                        colors.outerRingGlow.withValues(alpha: 0.0),
                      ],
                      stops: const [0.55, 1.0],
                    ),
                  ),
                ),

                // Decorative outer ring with tick marks
                _DecorativeOuterRing(
                  size: s * 1.15,
                  color: colors.outerRing,
                  glowColor: colors.borderGlow,
                  isActive: isActive,
                ),

                // Button body — scales with pulse animation
                Transform.scale(
                  scale: isDisabled ? 1.0 : _pulseAnimation.value,
                  child: _ButtonBody(
                    size: s,
                    colors: colors,
                    state: widget.state,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// MARK: - Internal helper widgets and classes for PanicButton

class _ButtonColors {
  final Color outerRing;
  final Color outerRingGlow;
  final Color middleRing;
  final Color innerButton;
  final Color innerButtonCenter;
  final Color contentColor;
  final Color shadowColor;
  final Color borderGlow;

  const _ButtonColors({
    required this.outerRing,
    required this.outerRingGlow,
    required this.middleRing,
    required this.innerButton,
    required this.innerButtonCenter,
    required this.contentColor,
    required this.shadowColor,
    required this.borderGlow,
  });
}

class _DecorativeOuterRing extends StatelessWidget {
  final double size;
  final Color color;
  final Color glowColor;
  final bool isActive;

  const _DecorativeOuterRing({
    required this.size,
    required this.color,
    required this.glowColor,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _RingPainter(
        color: color,
        glowColor: glowColor,
        isActive: isActive,
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final Color color;
  final Color glowColor;
  final bool isActive;

  _RingPainter({
    required this.color,
    required this.glowColor,
    required this.isActive,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Outer glow / blur shadow
    final glowPaint = Paint()
      ..color = glowColor
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(center, radius - 3, glowPaint);

    // Main border stroke
    final borderPaint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius - 2, borderPaint);

    // Decorative clock-style tick marks
    final tickPaint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 12; i++) {
      final angle = (i * 30) * (math.pi / 180);
      final isLong = i % 3 == 0;
      final tickLength = isLong ? 10.0 : 6.0;
      final outer =
          center + Offset(math.cos(angle), math.sin(angle)) * (radius - 7);
      final inner =
          center +
          Offset(math.cos(angle), math.sin(angle)) * (radius - 7 - tickLength);
      canvas.drawLine(inner, outer, tickPaint);
    }
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.isActive != isActive;
}

class _ExpandingRing extends StatelessWidget {
  final double progress;
  final double size;
  final Color color;

  const _ExpandingRing({
    required this.progress,
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size * 1.45, size * 1.45),
      painter: _ExpandingRingPainter(progress: progress, color: color),
    );
  }
}

class _ExpandingRingPainter extends CustomPainter {
  final double progress;
  final Color color;

  _ExpandingRingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;
    final currentRadius = maxRadius * 0.5 + (maxRadius * 0.5) * progress;
    final alpha = (1.0 - progress).clamp(0.0, 1.0);

    final paint = Paint()
      ..color = color.withValues(alpha: alpha * 0.4)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, currentRadius, paint);
  }

  @override
  bool shouldRepaint(_ExpandingRingPainter old) => old.progress != progress;
}

class _ButtonBody extends StatelessWidget {
  final double size;
  final _ButtonColors colors;
  final PanicButtonState state;

  const _ButtonBody({
    required this.size,
    required this.colors,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: colors.middleRing, width: 1.5),
        boxShadow: [
          BoxShadow(color: colors.shadowColor, blurRadius: 24, spreadRadius: 4),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
            spreadRadius: -4,
          ),
        ],
        gradient: RadialGradient(
          center: const Alignment(-0.3, -0.4),
          radius: 0.85,
          colors: [
            colors.innerButtonCenter,
            colors.innerButton,
            colors.innerButton.withRed(
              ((colors.innerButton.r * 255.0) * 0.75).round().clamp(0, 255),
            ),
          ],
          stops: const [0.0, 0.55, 1.0],
        ),
      ),
      child: Center(
        child: _ButtonContent(state: state, color: colors.contentColor),
      ),
    );
  }
}

class _ButtonContent extends StatelessWidget {
  final PanicButtonState state;
  final Color color;

  const _ButtonContent({required this.state, required this.color});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    // Active state
    if (state == PanicButtonState.active) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.pause_circle_filled_rounded, color: color, size: 50),
          const SizedBox(height: 6),
          Text(
            l10n.deactivate.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.5,
            ),
          ),
        ],
      );
    }

    // Normal or disabled
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.sos.toUpperCase(),
          style: TextStyle(
            color: color,
            fontSize: 46,
            fontWeight: FontWeight.w900,
            letterSpacing: 4,
            height: 1,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 50,
          height: 2,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(1),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          state == PanicButtonState.disabled
              ? l10n.notAvailable.toUpperCase()
              : l10n.emergency.toUpperCase(),
          style: TextStyle(
            color: color.withValues(alpha: 0.85),
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }
}
