import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../theme/glass_card.dart';

class OgarmSlider extends StatelessWidget {
  final double value;
  final double min;
  final double max;
  final String label;
  final int index;
  final Color color;
  final ValueChanged<double> onChanged;

  const OgarmSlider({
    super.key,
    required this.value,
    this.min = 0,
    this.max = 180,
    required this.label,
    required this.index,
    this.color = OgarmColors.orange,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GlassCard(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      borderRadius: 16,
      backgroundColor: isDark ? const Color(0xFF161B2E) : Colors.white,
      borderColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Joint Label & Name
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'JOINT 0${index + 1}',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: color,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? OgarmColors.textPrimary : const Color(0xFF1A1A2E),
                    ),
                  ),
                ],
              ),
              // Big Angle Display
              Text(
                '${value.toStringAsFixed(1)}°',
                style: GoogleFonts.spaceGrotesk( // Using Inter instead of Orbitron for the massive clean industrial numbers
                  fontSize: 28,
                  fontWeight: FontWeight.w300,
                  color: color,
                  letterSpacing: -1,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),

          // Slider
          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 4,
                      activeTrackColor: color,
                      inactiveTrackColor: color.withValues(alpha: 0.15),
                      thumbColor: color, // Ensure solid color thumb
                      overlayColor: color.withValues(alpha: 0.1),
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                      trackShape: const RoundedRectSliderTrackShape(),
                    ),
                    child: Slider(
                      value: value,
                      min: min,
                      max: max,
                      onChanged: (v) {
                        if (v <= min + 1 || v >= max - 1) {
                          HapticFeedback.lightImpact();
                        }
                        onChanged(v);
                      },
                    ),
                  ),
                  
                  // Min/Max Labels
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${min.round()}° MIN',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isDark ? OgarmColors.textMuted : const Color(0xFF8A8A9E),
                          ),
                        ),
                        Text(
                          '${max.round()}° MAX',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isDark ? OgarmColors.textMuted : const Color(0xFF8A8A9E),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
