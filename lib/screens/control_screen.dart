import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/robot_service.dart';
import '../theme/app_theme.dart';
import '../theme/glass_card.dart';
import '../widgets/ogarm_slider.dart';
import '../widgets/estop_button.dart';
import '../widgets/heartbeat_indicator.dart';

class ControlScreen extends StatefulWidget {
  const ControlScreen({super.key});

  @override
  State<ControlScreen> createState() => _ControlScreenState();
}

class _ControlScreenState extends State<ControlScreen> {
  final List<double> _angles = List.filled(6, 90.0);
  bool _lockJoints = false;

  static const List<String> _jointLabels = [
    'BASE',
    'Shoulder',
    'Elbow',
    'Wrist-P',
    'Wrist-R',
    'GRIP',
  ];

  static const List<Color> _jointColors = [
    OgarmColors.orange,
    Color(0xFF00E5FF),
    Color(0xFF40C4FF),
    Color(0xFF80D8FF),
    OgarmColors.amber,
    Color(0xFFFFD54F),
  ];

  void _onAngleChanged(int index, double value) {
    setState(() {
      _angles[index] = value;

      // Lock joints: J0 ↔ J3 inverse coupling
      if (_lockJoints) {
        if (index == 0) {
          _angles[3] = 180 - value;
          context.read<RobotService>().sendSingleServo(4, _angles[3].round());
        } else if (index == 3) {
          _angles[0] = 180 - value;
          context.read<RobotService>().sendSingleServo(1, _angles[0].round());
        }
        if (index == 1) {
          _angles[4] = 180 - value;
          context.read<RobotService>().sendSingleServo(5, _angles[4].round());
        } else if (index == 4) {
          _angles[1] = 180 - value;
          context.read<RobotService>().sendSingleServo(2, _angles[1].round());
        }
      }
    });

    // Send the primary servo (1-indexed)
    context.read<RobotService>().sendSingleServo(index + 1, value.round());
  }

  void _onEStop() {
    setState(() {
      for (int i = 0; i < 6; i++) {
        _angles[i] = 90.0;
      }
    });
    context.read<RobotService>().emergencyStop();
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<RobotService>();
    final isLight = Theme.of(context).brightness == Brightness.light;
    final textColor = isLight ? const Color(0xFF1A1A2E) : OgarmColors.textPrimary;
    final mutedColor = isLight ? const Color(0xFF5A5A6E) : OgarmColors.textMuted;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isLight 
            ? [Colors.white, const Color(0xFFF5F5F7)]
            : [OgarmColors.background, OgarmColors.backgroundLight],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'CONTROL OG-ARM',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                      letterSpacing: 3,
                    ),
                  ),
                  Row(
                    children: [
                      HeartbeatIndicator(isConnected: service.isConnected),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.settings_outlined, size: 22),
                        color: textColor,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => Navigator.pushNamed(context, '/settings'),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Lock Joints Toggle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GlassCard(
                margin: EdgeInsets.zero,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                borderRadius: 12,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.link,
                          color: _lockJoints ? OgarmColors.amber : mutedColor,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'LOCK JOINTS',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _lockJoints ? OgarmColors.amber : mutedColor,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                    Switch(
                      value: _lockJoints,
                      onChanged: (v) => setState(() => _lockJoints = v),
                      activeThumbColor: OgarmColors.amber,
                      activeTrackColor: OgarmColors.amber.withValues(alpha: 0.3),
                      inactiveThumbColor: mutedColor,
                      inactiveTrackColor: isLight ? Colors.black12 : OgarmColors.glassWhite,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // 6 Joint Control Cards in Grid
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  int columns = constraints.maxWidth > 600 ? 2 : 1;
                  return GridView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      childAspectRatio: columns == 2 ? 1.4 : 2.2,
                      crossAxisSpacing: 4,
                      mainAxisSpacing: 4,
                    ),
                    itemCount: 6,
                    itemBuilder: (context, index) {
                      return OgarmSlider(
                        value: _angles[index],
                        label: _jointLabels[index],
                        index: index,
                        color: _jointColors[index],
                        onChanged: (v) => _onAngleChanged(index, v),
                      );
                    },
                  );
                },
              ),
            ),

            // E-Stop or Record Frame Button
            if (service.isRecording)
              Padding(
                padding: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    service.addFrame();
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle, color: OgarmColors.background),
                            const SizedBox(width: 8),
                            Text(
                              'FRAME ADDED (${service.recordingFrameCount})',
                              style: GoogleFonts.spaceGrotesk(
                                fontWeight: FontWeight.bold,
                                color: OgarmColors.background,
                              ),
                            ),
                          ],
                        ),
                        duration: const Duration(milliseconds: 600),
                        backgroundColor: OgarmColors.orange,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  },
                  child: GlassCard(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    borderRadius: 16,
                    backgroundColor: OgarmColors.critical.withValues(alpha: 0.2),
                    borderColor: OgarmColors.critical,
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo, color: Colors.white),
                          const SizedBox(width: 12),
                          Text(
                            'ADD FRAME',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: EStopButton(onPressed: _onEStop),
              ),
          ],
        ),
      ),
    );
  }
}
