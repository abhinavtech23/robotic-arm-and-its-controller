import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/robot_service.dart';
import '../theme/app_theme.dart';
import '../theme/glass_card.dart';
import '../widgets/heartbeat_indicator.dart';

class KeyframeScreen extends StatelessWidget {
  const KeyframeScreen({super.key});

  void _doneRecording(BuildContext context, RobotService service) {
    if (service.recordingFrameCount == 0) {
      service.cancelRecording();
      return;
    }
    
    final TextEditingController nameController = TextEditingController(text: 'Movement ${service.sequences.length + 1}');
    
    final isLight = Theme.of(context).brightness == Brightness.light;
    final textColor = isLight ? const Color(0xFF1A1A2E) : OgarmColors.textPrimary;
    final mutedColor = isLight ? const Color(0xFF5A5A6E) : OgarmColors.textMuted;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isLight ? Colors.white : OgarmColors.backgroundLight,
          title: Text(
            'SAVE MOVEMENT',
            style: GoogleFonts.spaceGrotesk(color: textColor),
          ),
          content: TextField(
            controller: nameController,
            style: GoogleFonts.spaceGrotesk(color: textColor),
            decoration: InputDecoration(
              hintText: 'Enter name',
              hintStyle: TextStyle(color: mutedColor),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: OgarmColors.orange)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: OgarmColors.orange, width: 2)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                service.cancelRecording();
              },
              child: Text('CANCEL', style: GoogleFonts.spaceGrotesk(color: mutedColor)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                service.stopRecordingAndSave(nameController.text.trim());
              },
              child: Text('SAVE', style: GoogleFonts.spaceGrotesk(color: OgarmColors.orange)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<RobotService>();
    final isRecording = service.isRecording;
    final sequences = service.sequences;
    final currentPlayIndex = service.currentPlayIndex;
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
                    'KEYFRAMES',
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
                    ],
                  ),
                ],
              ),
            ),

            // Controls bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GlassCard(
                margin: EdgeInsets.zero,
                padding: const EdgeInsets.all(12),
                borderRadius: 14,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Record button
                    _ControlButton(
                      icon: isRecording ? Icons.fiber_manual_record : Icons.fiber_manual_record_outlined,
                      label: isRecording ? 'RECORDING...' : 'RECORD',
                      color: OgarmColors.critical,
                      onTap: () {
                        if (!isRecording) {
                          service.startRecording();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Recording started. Switch to Control to move and save frames.',
                                style: GoogleFonts.spaceGrotesk(),
                              ),
                              backgroundColor: OgarmColors.orangeDark,
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        }
                      },
                    ),
                    if (isRecording)
                      _ControlButton(
                        icon: Icons.check,
                        label: 'DONE',
                        color: OgarmColors.success,
                        onTap: () => _doneRecording(context, service),
                      ),
                    if (!isRecording) ...[
                      // Loop toggle
                      _ControlButton(
                        icon: Icons.loop,
                        label: 'LOOP',
                        color: service.playLoop ? OgarmColors.orange : mutedColor,
                        onTap: () => service.setPlayLoop(!service.playLoop),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            
            // Only show recording indicator and frames array if recording
            if (isRecording)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GlassCard(
                  padding: const EdgeInsets.all(12),
                  borderRadius: 12,
                  borderColor: OgarmColors.critical.withValues(alpha: 0.5),
                  child: Row(
                    children: [
                      Icon(Icons.fiber_manual_record, color: OgarmColors.critical, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'RECORDING: ${service.recordingFrameCount} FRAMES',
                        style: GoogleFonts.spaceGrotesk(
                          color: OgarmColors.critical,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),



            // Keyframe count
            if (!isRecording)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Row(
                  children: [
                    Text(
                      '${sequences.length} MOVEMENTS',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 11,
                        color: mutedColor,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),

            // Keyframe timeline
            Expanded(
              child: sequences.isEmpty && !isRecording
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.motion_photos_auto_outlined,
                            size: 64,
                            color: OgarmColors.textMuted.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No movements recorded yet',
                            style: GoogleFonts.spaceGrotesk(
                              color: mutedColor,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Press RECORD to capture a new sequence',
                            style: GoogleFonts.spaceGrotesk(
                              color: OgarmColors.textMuted.withValues(alpha: 0.5),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ReorderableListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      itemCount: sequences.length,
                      onReorder: (oldIdx, newIdx) => service.reorderSequence(oldIdx, newIdx),
                      itemBuilder: (context, index) {
                        final seq = sequences[index];
                        final isActive = index == currentPlayIndex;

                        return GlassCard(
                          key: ValueKey('seq_${seq.timestamp.millisecondsSinceEpoch}'),
                          borderColor: isActive
                              ? OgarmColors.orange
                              : (isLight ? Colors.black.withValues(alpha: 0.1) : OgarmColors.glassBorder),
                          backgroundColor: isActive
                              ? OgarmColors.orange.withValues(alpha: 0.1)
                              : null,
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              // Play Button
                              GestureDetector(
                                onTap: isActive ? service.stopSequence : () => service.playSequence(index),
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isActive
                                        ? OgarmColors.amber
                                        : OgarmColors.glassWhite,
                                  ),
                                  child: Icon(
                                    isActive ? Icons.stop : Icons.play_arrow,
                                    color: isActive ? Colors.black : textColor,
                                    size: 20,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      seq.name,
                                      style: GoogleFonts.spaceGrotesk(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: textColor,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${seq.frames.length} frames',
                                      style: GoogleFonts.spaceGrotesk(
                                        fontSize: 11,
                                        color: mutedColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Delete
                              IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                color: mutedColor,
                                onPressed: () => service.deleteSequence(index),
                              ),
                              // Drag handle
                              const Icon(
                                Icons.drag_handle,
                                color: Color(0xFF8A8A9E),
                                size: 20,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.15),
              border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.2),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: color,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}
