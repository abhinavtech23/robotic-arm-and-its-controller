import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';
import '../theme/glass_card.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsService = context.watch<SettingsService>();
    final isDark = settingsService.isDarkMode;
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color ?? OgarmColors.textPrimary;
    final mutedColor = theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5) ?? OgarmColors.textMuted;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('SETTINGS', style: theme.appBarTheme.titleTextStyle),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: theme.appBarTheme.iconTheme?.color ?? textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          children: [
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Dark Mode Toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isDark ? Icons.dark_mode : Icons.light_mode,
                            color: isDark ? OgarmColors.amber : OgarmColors.orangeDark,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'DARK MODE',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                      Switch(
                        value: isDark,
                        onChanged: (v) => settingsService.toggleTheme(),
                        activeTrackColor: OgarmColors.amber.withValues(alpha: 0.3),
                      ),
                    ],
                  ),
                  Divider(height: 32, color: theme.dividerColor.withValues(alpha: 0.1)),
                  
                  // Contact Support
                  InkWell(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                         SnackBar(
                           content: Text(
                             'Contact support at support@ogarm.dev',
                             style: GoogleFonts.spaceGrotesk(color: Colors.white),
                           ),
                           backgroundColor: OgarmColors.orangeDark,
                         )
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Icon(Icons.support_agent, color: theme.primaryColor, size: 24),
                          const SizedBox(width: 12),
                          Text(
                            'CONTACT SUPPORT',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                              letterSpacing: 1,
                            ),
                          ),
                          const Spacer(),
                          Icon(Icons.arrow_forward_ios, size: 16, color: mutedColor),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            Center(
              child: Column(
                children: [
                  Text(
                    'OGARM',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: mutedColor,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Version 0.1.0+1',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      color: mutedColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
