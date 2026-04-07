import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class HeartbeatIndicator extends StatefulWidget {
  final bool isConnected;

  const HeartbeatIndicator({super.key, required this.isConnected});

  @override
  State<HeartbeatIndicator> createState() => _HeartbeatIndicatorState();
}

class _HeartbeatIndicatorState extends State<HeartbeatIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.6, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    if (widget.isConnected) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant HeartbeatIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isConnected && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isConnected && _controller.isAnimating) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isConnected ? OgarmColors.success : OgarmColors.critical;
    final label = widget.isConnected ? 'LINKED' : 'OFFLINE';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Pulsing ring
              if (widget.isConnected)
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: color.withValues(alpha: _opacityAnimation.value),
                            width: 2,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              // Core dot
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.5),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}
