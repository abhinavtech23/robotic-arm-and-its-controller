import 'dart:ui';
import 'package:flutter/material.dart';
import 'app_theme.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blurAmount;
  final Color? borderColor;
  final Color? backgroundColor;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 20,
    this.blurAmount = 15,
    this.borderColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final defaultBg = isLight ? Colors.white : OgarmColors.glassWhite;
    final defaultBorder = isLight ? Colors.black.withValues(alpha: 0.1) : OgarmColors.glassBorder;

    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurAmount, sigmaY: blurAmount),
          child: Container(
            padding: padding ?? const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: backgroundColor ?? defaultBg,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: borderColor ?? defaultBorder,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class GlowContainer extends StatelessWidget {
  final Widget child;
  final Color glowColor;
  final double glowRadius;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;

  const GlowContainer({
    super.key,
    required this.child,
    this.glowColor = OgarmColors.orange,
    this.glowRadius = 20,
    this.padding,
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: glowColor.withValues(alpha: 0.3),
            blurRadius: glowRadius,
            spreadRadius: 0,
          ),
        ],
      ),
      child: child,
    );
  }
}
