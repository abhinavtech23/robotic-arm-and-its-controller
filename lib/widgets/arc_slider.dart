import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

class ArcSlider extends StatefulWidget {
  final double value;
  final double min;
  final double max;
  final String label;
  final Color color;
  final ValueChanged<double> onChanged;

  const ArcSlider({
    super.key,
    required this.value,
    this.min = 0,
    this.max = 180,
    required this.label,
    this.color = OgarmColors.orange,
    required this.onChanged,
  });

  @override
  State<ArcSlider> createState() => _ArcSliderState();
}

class _ArcSliderState extends State<ArcSlider> with SingleTickerProviderStateMixin {
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  void _handlePanUpdate(DragUpdateDetails details, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final position = details.localPosition;
    final angle = atan2(position.dy - center.dy, position.dx - center.dx);

    // Convert from radian angle to our 0-180 range
    // Arc starts at 210° (bottom-left) and sweeps 300°
    double degrees = (angle * 180 / pi + 360) % 360;

    // Map the arc angle range (210° to 150° clockwise = 300° sweep) to value range
    double normalizedAngle = (degrees - 210 + 360) % 360;
    if (normalizedAngle > 300) {
      // Outside the arc — clamp
      normalizedAngle = normalizedAngle > 330 ? 0 : 300;
    }
    double newValue = widget.min + (normalizedAngle / 300) * (widget.max - widget.min);
    newValue = newValue.clamp(widget.min, widget.max);

    // Haptic at limits
    if ((newValue <= widget.min + 1 || newValue >= widget.max - 1)) {
      HapticFeedback.heavyImpact();
    }

    widget.onChanged(newValue);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final size = Size(constraints.maxWidth, constraints.maxWidth);
      return GestureDetector(
        onPanUpdate: (d) => _handlePanUpdate(d, size),
        child: AnimatedBuilder(
          animation: _glowController,
          builder: (context, child) {
            return CustomPaint(
              size: size,
              painter: _ArcSliderPainter(
                value: widget.value,
                min: widget.min,
                max: widget.max,
                label: widget.label,
                color: widget.color,
                glowOpacity: 0.3 + 0.2 * _glowController.value,
              ),
            );
          },
        ),
      );
    });
  }
}

class _ArcSliderPainter extends CustomPainter {
  final double value;
  final double min;
  final double max;
  final String label;
  final Color color;
  final double glowOpacity;

  _ArcSliderPainter({
    required this.value,
    required this.min,
    required this.max,
    required this.label,
    required this.color,
    required this.glowOpacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.38;
    const startAngle = 210 * pi / 180; // Start at bottom-left
    const sweepAngle = 300 * pi / 180; // Almost full circle

    // Track background
    final trackPaint = Paint()
      ..color = color.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      trackPaint,
    );

    // Active arc with gradient
    final fraction = (value - min) / (max - min);
    final activeSweep = sweepAngle * fraction;

    final gradientPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: startAngle,
        endAngle: startAngle + sweepAngle,
        colors: [
          color.withValues(alpha: 0.5),
          color,
          color.withValues(alpha: 0.8),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      activeSweep,
      false,
      gradientPaint,
    );

    // Thumb knob
    final thumbAngle = startAngle + activeSweep;
    final thumbPos = Offset(
      center.dx + radius * cos(thumbAngle),
      center.dy + radius * sin(thumbAngle),
    );

    // Thumb glow
    final glowPaint = Paint()
      ..color = color.withValues(alpha: glowOpacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(thumbPos, 14, glowPaint);

    // Thumb solid
    final thumbPaint = Paint()..color = color;
    canvas.drawCircle(thumbPos, 8, thumbPaint);

    // Inner white dot
    canvas.drawCircle(thumbPos, 3, Paint()..color = Colors.white);

    // Centre value text
    final valuePainter = TextPainter(
      text: TextSpan(
        text: '${value.round()}°',
        style: TextStyle(
          color: color,
          fontSize: size.width * 0.14,
          fontWeight: FontWeight.w700,
          fontFamily: 'Space Grotesk',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    valuePainter.paint(
      canvas,
      center - Offset(valuePainter.width / 2, valuePainter.height / 2 + 4),
    );

    // Label below value
    final labelPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: color.withValues(alpha: 0.7),
          fontSize: size.width * 0.08,
          fontWeight: FontWeight.w500,
          letterSpacing: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    labelPainter.paint(
      canvas,
      center - Offset(labelPainter.width / 2, -valuePainter.height / 2 + 2),
    );

    // Min / Max labels
    final minPainter = TextPainter(
      text: TextSpan(
        text: '${min.round()}°',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.3),
          fontSize: 10,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final minPos = Offset(
      center.dx + radius * cos(startAngle) - minPainter.width / 2,
      center.dy + radius * sin(startAngle) + 12,
    );
    minPainter.paint(canvas, minPos);

    final maxPainter = TextPainter(
      text: TextSpan(
        text: '${max.round()}°',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.3),
          fontSize: 10,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final endAngle = startAngle + sweepAngle;
    final maxPos = Offset(
      center.dx + radius * cos(endAngle) - maxPainter.width / 2,
      center.dy + radius * sin(endAngle) + 12,
    );
    maxPainter.paint(canvas, maxPos);
  }

  @override
  bool shouldRepaint(covariant _ArcSliderPainter oldDelegate) {
    return oldDelegate.value != value || oldDelegate.glowOpacity != glowOpacity;
  }
}
