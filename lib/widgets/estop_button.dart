import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

class EStopButton extends StatefulWidget {
  final VoidCallback onPressed;

  const EStopButton({super.key, required this.onPressed});

  @override
  State<EStopButton> createState() => _EStopButtonState();
}

class _EStopButtonState extends State<EStopButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.4, end: 0.8).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return GestureDetector(
          onTap: () {
            HapticFeedback.heavyImpact();
            widget.onPressed();
          },
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: OgarmColors.critical,
              border: Border.all(
                color: OgarmColors.critical.withValues(alpha: 0.6),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: OgarmColors.critical.withValues(alpha: _pulseAnimation.value),
                  blurRadius: 24,
                  spreadRadius: 4,
                ),
                BoxShadow(
                  color: OgarmColors.critical.withValues(alpha: _pulseAnimation.value * 0.5),
                  blurRadius: 48,
                  spreadRadius: 8,
                ),
              ],
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.power_settings_new, color: Colors.white, size: 28),
                Text(
                  'E-STOP',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
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
