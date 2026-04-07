import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/robot_service.dart';
import '../theme/app_theme.dart';
import '../theme/glass_card.dart';
import '../utils/sound_generator.dart';

class ConnectionScreen extends StatefulWidget {
  const ConnectionScreen({super.key});

  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen>
    with TickerProviderStateMixin {
  final _ipController = TextEditingController(text: '192.168.4.1');
  bool _isConnecting = false;
  String? _errorMessage;

  Offset? _touchPosition;

  // Background animation
  late AnimationController _bgAnimController;

  // Master sequence controller for the arm grab animation
  late AnimationController _seqController;

  // Idle arm bob after sequence completes
  late AnimationController _idleArmController;
  late Animation<double> _idleArmAnimation;

  // Button glow pulse after sequence
  late AnimationController _btnGlowController;

  // Audio
  final AudioPlayer _servoPlayer = AudioPlayer();
  final AudioPlayer _clampPlayer = AudioPlayer();
  final AudioPlayer _placePlayer = AudioPlayer();
  bool _soundsReady = false;
  String? _servoPath;
  String? _clampPath;
  String? _placePath;

  // ============================================================
  // ANIMATION TIMELINE (normalized 0.0 → 1.0 over 5 seconds)
  // ============================================================
  // 0.00–0.08 : Letters "GARMO" fade in. ARM is ALREADY VISIBLE
  //             at top-center with open claw, posed above the O.
  // 0.08–0.22 : Arm descends to the "O"              → servo
  // 0.22–0.30 : Claw closes, grabs "O"               → clamp
  // 0.30–0.46 : Arm lifts "O" up high
  // 0.46–0.66 : Arm swings left carrying "O"         → servo
  // 0.66–0.76 : Arm drops "O" into slot 0            → place
  // 0.76–0.84 : G,A,R,M slide right to slots 1–4
  // 0.84–0.92 : Arm rises to idle hover above text
  // 0.92–1.00 : Settle: arm bobs, button glows up
  // ============================================================

  bool _soundPlayed1 = false;
  bool _soundPlayed2 = false;
  bool _soundPlayed3 = false;
  bool _sequenceComplete = false;

  @override
  void initState() {
    super.initState();
    _bgAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _seqController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2700),
    );

    _idleArmController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _idleArmAnimation = Tween<double>(begin: -1.0, end: 1.0).animate(
      CurvedAnimation(parent: _idleArmController, curve: Curves.easeInOut),
    );

    _btnGlowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _seqController.addListener(_handleSoundTriggers);
    _seqController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _sequenceComplete = true);
        _btnGlowController.repeat(reverse: true);
      }
    });

    _initSounds();

    // Longer delay so the app fully renders before animation plays
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) _seqController.forward();
    });
  }

  Future<void> _initSounds() async {
    try {
      _servoPath = await SoundGenerator.generateServoSound();
      _clampPath = await SoundGenerator.generateClampSound();
      _placePath = await SoundGenerator.generatePlaceSound();
      _soundsReady = true;
    } catch (_) {}
  }

  void _handleSoundTriggers() {
    final v = _seqController.value;
    if (!_soundsReady) return;

    if (v >= 0.08 && !_soundPlayed1) {
      _soundPlayed1 = true;
      HapticFeedback.mediumImpact();
      _servoPlayer.play(DeviceFileSource(_servoPath!), volume: 0.7);
    }
    if (v >= 0.22 && !_soundPlayed2) {
      _soundPlayed2 = true;
      HapticFeedback.heavyImpact();
      _clampPlayer.play(DeviceFileSource(_clampPath!), volume: 0.9);
    }
    if (v >= 0.66 && !_soundPlayed3) {
      _soundPlayed3 = true;
      HapticFeedback.heavyImpact();
      _placePlayer.play(DeviceFileSource(_placePath!), volume: 0.85);
    }
  }

  @override
  void dispose() {
    _ipController.dispose();
    _bgAnimController.dispose();
    _seqController.dispose();
    _idleArmController.dispose();
    _btnGlowController.dispose();
    _servoPlayer.dispose();
    _clampPlayer.dispose();
    _placePlayer.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    setState(() {
      _isConnecting = true;
      _errorMessage = null;
    });

    final service = context.read<RobotService>();
    final errorStr = await service.connect(_ipController.text.trim());

    if (mounted) {
      setState(() => _isConnecting = false);
      if (errorStr == null) {
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        setState(
            () => _errorMessage = 'Failed: $errorStr\n(IP: ${_ipController.text})');
      }
    }
  }

  // ===================== ANIMATION HELPERS =====================

  double _subAnim(double master, double start, double end) {
    return ((master - start) / (end - start)).clamp(0.0, 1.0);
  }

  double _eased(double master, double start, double end, Curve curve) {
    return curve.transform(_subAnim(master, start, end));
  }

  // ===================== BUILD =====================

  @override
  Widget build(BuildContext context) {
    final isLightMode = Theme.of(context).brightness == Brightness.light;
    final textColor = isLightMode ? const Color(0xFF1A1A2E) : OgarmColors.textPrimary;
    final textMutedColor = isLightMode ? const Color(0xFF8A8A9E) : OgarmColors.textMuted;
    

    return Scaffold(
      body: AnimatedBuilder(
        animation: _bgAnimController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isLightMode
                    ? [
                        Colors.white,
                        const Color(0xFFF5F5F7),
                        HSLColor.fromAHSL(
                          1,
                          220 + 20 * sin(_bgAnimController.value * 2 * pi),
                          0.6,
                          0.95,
                        ).toColor(),
                      ]
                    : [
                        OgarmColors.background,
                        OgarmColors.backgroundLight,
                        HSLColor.fromAHSL(
                          1,
                          220 + 20 * sin(_bgAnimController.value * 2 * pi),
                          0.6,
                          0.08,
                        ).toColor(),
                      ],
              ),
            ),
            child: child,
          );
        },
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // === ARM + LETTERS ===
                  _buildArmAnimation(textColor),
                  const SizedBox(height: 8),
                  Text(
                    '6-DOF MANIPULATOR CONTROLLER',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: textMutedColor,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // IP Input Card
                  _buildIpCard(textColor, isLightMode),
                  const SizedBox(height: 24),

                  // Connect button with glow
                  _buildConnectButton(),
                  const SizedBox(height: 32),

                  // Hint
                  Text(
                    'Connect to "OGARM" Wi-Fi (pass: iloveogdeck)',
                    style: GoogleFonts.spaceGrotesk(
                      color: textMutedColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ===================== IP CARD =====================

  Widget _buildIpCard(Color textColor, bool isLightMode) {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: OgarmColors.amber,
                boxShadow: [
                  BoxShadow(
                    color: OgarmColors.amber.withValues(alpha: 0.5),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'DEVICE ADDRESS',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: OgarmColors.amber,
                letterSpacing: 2,
              ),
            ),
          ]),
          const SizedBox(height: 16),
          TextField(
            controller: _ipController,
            style: GoogleFonts.spaceGrotesk(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: '192.168.4.1',
              hintStyle: TextStyle(
                color: isLightMode ? const Color(0xFF8A8A9E) : OgarmColors.textMuted,
              ),
              prefixIcon: Icon(
                Icons.wifi,
                color: OgarmColors.orange.withValues(alpha: 0.6),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isLightMode
                      ? Colors.grey.withValues(alpha: 0.3)
                      : OgarmColors.glassBorder,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                    color: OgarmColors.orange, width: 1.5),
              ),
              filled: true,
              fillColor: isLightMode ? Colors.white : OgarmColors.glassHighlight,
            ),
            keyboardType: TextInputType.url,
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              style: const TextStyle(color: OgarmColors.critical, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }

  // ===================== CONNECT BUTTON WITH GLOW =====================

  Widget _buildConnectButton() {
    return AnimatedBuilder(
      animation: _btnGlowController,
      builder: (context, _) {
        // Glow intensity: 0 before sequence, pulsing 0.3–1.0 after
        final glowIntensity = _sequenceComplete
            ? 0.3 + 0.7 * _btnGlowController.value
            : 0.0;

        return GestureDetector(
          onTap: _isConnecting ? null : _connect,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _isConnecting
                    ? [OgarmColors.orangeDark, OgarmColors.orangeDark]
                    : [OgarmColors.orange, OgarmColors.orangeDark],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: OgarmColors.orange
                      .withValues(alpha: 0.15 + glowIntensity * 0.55),
                  blurRadius: 20 + glowIntensity * 30,
                  spreadRadius: glowIntensity * 8,
                  offset: const Offset(0, 4),
                ),
                if (_sequenceComplete)
                  BoxShadow(
                    color: OgarmColors.orange
                        .withValues(alpha: glowIntensity * 0.3),
                    blurRadius: 60,
                    spreadRadius: glowIntensity * 4,
                  ),
              ],
            ),
            child: Center(
              child: _isConnecting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Text(
                      'ESTABLISH LINK',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 3,
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }

  // ===================== ARM + LETTERS COMPOSITE =====================

  Widget _buildArmAnimation(Color textColor) {
    const double areaWidth = 320;
    const double areaHeight = 260; // Shorter area
    const double letterSize = 38.0; // Scaled down slightly to fit 6 characters
    const double letterGap = 5.0;
    const double totalLetterWidth = 6 * letterSize + 5 * letterGap;
    const double lettersStartX = (areaWidth - totalLetterWidth) / 2;
    const double lettersY = 200.0; // Moved up to fill gap

    // Arm idle hover position (above center of text)
    const double idleArmX = areaWidth / 2;
    const double idleArmY = 130.0; // Pushed down to be closer to text

    return SizedBox(
      width: areaWidth,
      height: areaHeight,
      child: GestureDetector(
        onPanStart: (details) {
          if (_sequenceComplete) setState(() => _touchPosition = details.localPosition);
        },
        onPanUpdate: (details) {
          if (_sequenceComplete) setState(() => _touchPosition = details.localPosition);
        },
        onPanEnd: (details) {
          if (_sequenceComplete) setState(() => _touchPosition = null);
        },
        child: AnimatedBuilder(
          animation: Listenable.merge(
              [_seqController, _bgAnimController, _idleArmController]),
          builder: (context, _) {
            final t = _seqController.value;
            final bgTime = _bgAnimController.value * 2 * pi;
            final idleBob = _idleArmAnimation.value;

            // ── Letter Fade In ──
            final lettersFadeIn = _eased(t, 0.0, 0.08, Curves.easeOut);

            // ── Letter shift (G,-,A,R,M slide right after O is placed) ──
            final shiftProgress = _eased(t, 0.76, 0.84, Curves.easeInOut);

            // Letter X positions for G(0), -(1), A(2), R(3), M(4)
            List<double> staticLetterX = [];
            for (int i = 0; i < 5; i++) {
              final slotX = lettersStartX +
                  (i + shiftProgress) * (letterSize + letterGap);
              staticLetterX.add(slotX);
            }

            // ── "O" position ──
            final oSlot5X = lettersStartX + 5 * (letterSize + letterGap);
            final oSlot0X = lettersStartX;

            double oX, oY;
            double oScale = 1.0;
            double oGlow = 0.0;

            if (t < 0.22) {
              // O sits in slot 5
              oX = oSlot5X;
              oY = lettersY;
            } else if (t < 0.30) {
              // Claw grabs — O lifts slightly
              final grab = _eased(t, 0.22, 0.30, Curves.easeIn);
              oX = oSlot5X;
              oY = lettersY - grab * 25;
              oScale = 1.0 + grab * 0.2;
              oGlow = grab;
            } else if (t < 0.46) {
              // Lift O high
              final lift = _eased(t, 0.30, 0.46, Curves.easeOut);
              oX = oSlot5X;
              oY = lettersY - 25 - lift * 140;
              oScale = 1.2;
              oGlow = 1.0;
            } else if (t < 0.66) {
              // Swing O left
              final swing = _eased(t, 0.46, 0.66, Curves.easeInOut);
              oX = oSlot5X + (oSlot0X - oSlot5X) * swing;
              oY = lettersY - 165 + sin(swing * pi) * 25; // arc
              oScale = 1.2 - swing * 0.2;
              oGlow = 1.0;
          } else if (t < 0.76) {
            // Drop O into slot 0
            final drop = _eased(t, 0.66, 0.76, Curves.bounceOut);
            oX = oSlot0X;
            oY = (lettersY - 165) + drop * 165;
            oScale = 1.0;
            oGlow = 1.0 - drop * 0.5;
          } else {
            // Settled
            oX = oSlot0X;
            oY = lettersY;
            oScale = 1.0;
            oGlow = 0.3 + 0.2 * sin(bgTime * 2);
          }

            // ── ARM TIP POSITION ──
            double armTipX, armTipY;
            double clawOpen = 1.0;

            if (t < 0.08) {
              // ARM IS VISIBLE from the start — hovering above O's slot with open claw
              final showIn = _eased(t, 0.0, 0.08, Curves.easeOut);
              armTipX = oSlot5X + letterSize / 2;
              armTipY = 30 + showIn * 40; // starts at y=30, eases to y=70
              clawOpen = 1.0;
            } else if (t < 0.22) {
              // Arm descends toward O
              final descend = _eased(t, 0.08, 0.22, Curves.easeInOut);
              armTipX = oSlot5X + letterSize / 2;
              armTipY = 70 + descend * (lettersY - 12 - 70);
              clawOpen = 1.0 - descend * 0.3; // starts closing slightly
            } else if (t < 0.30) {
              // Claw closes on O
              final close = _eased(t, 0.22, 0.30, Curves.easeInOut);
              armTipX = oSlot5X + letterSize / 2;
              armTipY = lettersY - 12 - close * 25;
              clawOpen = 0.7 - close * 0.7;
          } else if (t < 0.76) {
            // Arm follows O
            armTipX = oX + letterSize / 2;
            armTipY = oY - 12;
            clawOpen = 0.0;
          } else if (t < 0.84) {
            // Claw opens, arm rises to idle hover
            final rise = _eased(t, 0.76, 0.84, Curves.easeInOut);
            armTipX = oSlot0X + letterSize / 2 +
                (idleArmX - oSlot0X - letterSize / 2) * rise;
            armTipY = lettersY - 12 - rise * (lettersY - 12 - idleArmY);
            clawOpen = rise;
            } else {
              // Idle hover above center of text, tracking touch if active
              if (_touchPosition != null) {
                // Follow the user's finger!
                armTipX = _touchPosition!.dx;
                armTipY = _touchPosition!.dy;
                clawOpen = 0.7 + idleBob * 0.2; // Wiggle dynamically while dragged!
              } else {
                armTipX = idleArmX + idleBob * 8;
                armTipY = idleArmY + idleBob * 6;
                clawOpen = 0.6 + idleBob * 0.15;
              }
            }

          // After sequence, add idle bob to letters
          final letterBob = t >= 0.92 ? idleBob * 2 : 0.0;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              // === ORBIT RINGS (behind everything) ===
              if (t >= 0.84)
                _buildOrbitRings(areaWidth, bgTime,
                    _eased(t, 0.84, 1.0, Curves.easeOut)),

              // === ROBOTIC ARM (always visible) ===
              Positioned.fill(
                child: CustomPaint(
                  painter: _RoboticArmPainter(
                    tipX: armTipX,
                    tipY: armTipY,
                    clawOpen: clawOpen,
                    color: OgarmColors.orange,
                    areaWidth: areaWidth,
                  ),
                ),
              ),

                // === STATIC LETTERS (G, -, A, R, M) ===
                for (int i = 0; i < 5; i++)
                  Positioned(
                    left: staticLetterX[i],
                    top: lettersY + letterBob,
                    child: Opacity(
                      opacity: lettersFadeIn,
                      child: _buildLetter('G-ARM'[i], letterSize, false, 0.0, textColor),
                    ),
                  ),

                // === ANIMATED "O" ===
                Positioned(
                  left: oX,
                  top: oY + (t >= 0.92 ? letterBob : 0),
                  child: Opacity(
                    opacity: lettersFadeIn,
                    child: Transform.scale(
                      scale: oScale,
                      child: _buildLetter('O', letterSize, true, oGlow, textColor),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildOrbitRings(double areaWidth, double bgTime, double opacity) {
    return Positioned(
      left: areaWidth / 2 - 110,
      top: 30,
      child: Opacity(
        opacity: opacity * 0.45,
        child: SizedBox(
          width: 220,
          height: 220,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateX(1.1)
                  ..rotateZ(bgTime * 2),
                alignment: Alignment.center,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: OgarmColors.orange.withValues(alpha: 0.15),
                      width: 2,
                    ),
                  ),
                ),
              ),
              Transform(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateY(1.1)
                  ..rotateZ(-bgTime * 1.5),
                alignment: Alignment.center,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: OgarmColors.orange.withValues(alpha: 0.25),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLetter(String char, double size, bool isSpecial, double glow, Color textColor) {
    return SizedBox(
      width: size,
      height: size + 8,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (isSpecial && glow > 0)
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: OgarmColors.orange.withValues(alpha: glow * 0.6),
                    blurRadius: 25,
                    spreadRadius: 5,
                  ),
                ],
              ),
            ),
          Text(
            char,
            style: GoogleFonts.spaceGrotesk(
              fontSize: size - 4,
              fontWeight: FontWeight.w800,
              color: isSpecial ? OgarmColors.orange : textColor,
              letterSpacing: 2,
              shadows: isSpecial
                  ? [
                      Shadow(
                        color: OgarmColors.orange.withValues(alpha: 0.7),
                        blurRadius: 12,
                      ),
                    ]
                  : [
                      Shadow(
                        color: OgarmColors.orange.withValues(alpha: 0.3),
                        blurRadius: 8,
                      ),
                    ],
            ),
          ),
        ],
      ),
    );
  }
}

// ===================== ROBOTIC ARM PAINTER =====================

class _RoboticArmPainter extends CustomPainter {
  final double tipX;
  final double tipY;
  final double clawOpen;
  final Color color;
  final double areaWidth;

  _RoboticArmPainter({
    required this.tipX,
    required this.tipY,
    required this.clawOpen,
    required this.color,
    required this.areaWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final baseX = areaWidth / 2;
    const baseY = 0.0;

    final dx = tipX - baseX;
    final dy = tipY - baseY;
    final dist = sqrt(dx * dx + dy * dy);
    if (dist < 1) return; // avoid division by zero

    // 2-segment arm: base → elbow → tip
    final midX = (baseX + tipX) / 2;
    final midY = (baseY + tipY) / 2;

    // Perpendicular offset for natural elbow bend
    final perpX = -(dy) / dist * dist * 0.25;
    final perpY = (dx) / dist * dist * 0.25;

    final elbowX = midX + perpX;
    final elbowY = midY + perpY;

    // === Draw arm segments ===

    // Glow layer
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..strokeWidth = 24
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    canvas.drawLine(Offset(baseX, baseY), Offset(elbowX, elbowY), glowPaint);
    canvas.drawLine(Offset(elbowX, elbowY), Offset(tipX, tipY), glowPaint);

    // Outer shell
    final shellPaint = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(baseX, baseY), Offset(elbowX, elbowY), shellPaint);
    canvas.drawLine(Offset(elbowX, elbowY), Offset(tipX, tipY), shellPaint);

    // Inner core (bright)
    final corePaint = Paint()
      ..color = color.withValues(alpha: 0.95)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(baseX, baseY), Offset(elbowX, elbowY), corePaint);
    canvas.drawLine(Offset(elbowX, elbowY), Offset(tipX, tipY), corePaint);

    // === JOINTS ===
    final jointPaint = Paint()..color = color;
    final jointGlowPaint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7);
    final whiteDot = Paint()..color = Colors.white;

    // Base
    canvas.drawCircle(Offset(baseX, baseY), 12, jointGlowPaint);
    canvas.drawCircle(Offset(baseX, baseY), 8, jointPaint);
    canvas.drawCircle(Offset(baseX, baseY), 3, whiteDot);

    // Elbow
    canvas.drawCircle(Offset(elbowX, elbowY), 10, jointGlowPaint);
    canvas.drawCircle(Offset(elbowX, elbowY), 6.5, jointPaint);
    canvas.drawCircle(Offset(elbowX, elbowY), 2.5, whiteDot);

    // Wrist (tip)
    canvas.drawCircle(Offset(tipX, tipY), 8, jointGlowPaint);
    canvas.drawCircle(Offset(tipX, tipY), 5, jointPaint);

    // === CLAW / GRIPPER ===
    final clawAngle = pi / 5 * clawOpen;
    const clawLength = 30.0;

    final leftClawEnd = Offset(
      tipX - clawLength * sin(clawAngle) - 5,
      tipY + clawLength * cos(clawAngle),
    );
    final rightClawEnd = Offset(
      tipX + clawLength * sin(clawAngle) + 5,
      tipY + clawLength * cos(clawAngle),
    );

    final clawPaint = Paint()
      ..color = color
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final clawGlowPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    canvas.drawLine(Offset(tipX, tipY), leftClawEnd, clawGlowPaint);
    canvas.drawLine(Offset(tipX, tipY), rightClawEnd, clawGlowPaint);
    canvas.drawLine(Offset(tipX, tipY), leftClawEnd, clawPaint);
    canvas.drawLine(Offset(tipX, tipY), rightClawEnd, clawPaint);

    // Claw tips
    canvas.drawCircle(leftClawEnd, 5, jointPaint);
    canvas.drawCircle(rightClawEnd, 5, jointPaint);

    // === BASE MOUNT ===
    final mountPaint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    final mountPath = Path()
      ..moveTo(baseX - 20, baseY)
      ..lineTo(baseX + 20, baseY)
      ..lineTo(baseX + 12, baseY + 9)
      ..lineTo(baseX - 12, baseY + 9)
      ..close();
    canvas.drawPath(mountPath, mountPaint);

    // Base rail
    final railPaint = Paint()
      ..color = color.withValues(alpha: 0.25)
      ..strokeWidth = 2;
    canvas.drawLine(
        Offset(baseX - 60, 0), Offset(baseX + 60, 0), railPaint);

    // Inner rail detail
    final innerRailPaint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..strokeWidth = 1;
    canvas.drawLine(
        Offset(baseX - 30, 0), Offset(baseX + 30, 0), innerRailPaint);
  }

  @override
  bool shouldRepaint(covariant _RoboticArmPainter oldDelegate) {
    return oldDelegate.tipX != tipX ||
        oldDelegate.tipY != tipY ||
        oldDelegate.clawOpen != clawOpen;
  }
}
