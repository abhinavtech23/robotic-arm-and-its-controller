import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/robot_service.dart';
import '../theme/app_theme.dart';
import '../theme/glass_card.dart';
import '../widgets/heartbeat_indicator.dart';

class TelemetryScreen extends StatefulWidget {
  const TelemetryScreen({super.key});

  @override
  State<TelemetryScreen> createState() => _TelemetryScreenState();
}

class _TelemetryScreenState extends State<TelemetryScreen> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      context.read<RobotService>().fetchTelemetry();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<RobotService>();
    final history = service.telemetryHistory;

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
                    'TELEMETRY',
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

            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                children: [
                  // Stats Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        _StatTile(
                          label: 'TEMP',
                          value: '${service.telemetry.temperature.toStringAsFixed(1)}°C',
                          icon: Icons.thermostat,
                          color: service.telemetry.temperature > 70
                              ? OgarmColors.critical
                              : OgarmColors.orange,
                        ),
                        const SizedBox(width: 10),
                        _StatTile(
                          label: 'LATENCY',
                          value: '${service.telemetry.latencyMs.round()} ms',
                          icon: Icons.speed,
                          color: service.telemetry.latencyMs > 100
                              ? OgarmColors.amber
                              : OgarmColors.success,
                        ),
                        const SizedBox(width: 10),
                        _StatTile(
                          label: 'HEAP',
                          value: '${(service.telemetry.heapFree / 1024).toStringAsFixed(0)} KB',
                          icon: Icons.memory,
                          color: OgarmColors.amber,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Uptime
                  GlassCard(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    child: Row(
                      children: [
                        const Icon(Icons.timer_outlined, color: OgarmColors.textMuted, size: 18),
                        const SizedBox(width: 10),
                        Text(
                          'UPTIME',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 11,
                            color: mutedColor,
                            letterSpacing: 2,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _formatUptime(service.telemetry.uptime),
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 14,
                            color: textColor,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Temperature Chart
                  _ChartCard(
                    title: 'TEMPERATURE',
                    unit: '°C',
                    color: OgarmColors.orange,
                    data: history.map((t) => t.temperature).toList(),
                  ),

                  // Latency Chart
                  _ChartCard(
                    title: 'LATENCY',
                    unit: 'ms',
                    color: OgarmColors.amber,
                    data: history.map((t) => t.latencyMs).toList(),
                  ),

                  // Heap Chart
                  _ChartCard(
                    title: 'FREE HEAP',
                    unit: 'KB',
                    color: OgarmColors.success,
                    data: history.map((t) => t.heapFree / 1024).toList(),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatUptime(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

// --- Stat Tile ---

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GlassCard(
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.all(14),
        borderRadius: 14,
        borderColor: color.withValues(alpha: 0.2),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: mutedColor,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Chart Card ---

class _ChartCard extends StatelessWidget {
  final String title;
  final String unit;
  final Color color;
  final List<double> data;

  const _ChartCard({
    required this.title,
    required this.unit,
    required this.color,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  boxShadow: [
                    BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 6),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                  letterSpacing: 2,
                ),
              ),
              const Spacer(),
              if (data.isNotEmpty)
                Text(
                  '${data.last.toStringAsFixed(1)} $unit',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).brightness == Brightness.light ? const Color(0xFF1A1A2E) : OgarmColors.textPrimary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: data.length < 2
                ? Center(
                    child: Text(
                      'Awaiting data…',
                      style: TextStyle(color: Theme.of(context).brightness == Brightness.light ? const Color(0xFF5A5A6E) : OgarmColors.textMuted, fontSize: 12),
                    ),
                  )
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: _calcInterval(),
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: OgarmColors.glassHighlight,
                          strokeWidth: 0.5,
                        ),
                      ),
                      titlesData: const FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: data
                              .asMap()
                              .entries
                              .map((e) => FlSpot(e.key.toDouble(), e.value))
                              .toList(),
                          isCurved: true,
                          color: color,
                          barWidth: 2,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: color.withValues(alpha: 0.08),
                          ),
                        ),
                      ],
                      lineTouchData: const LineTouchData(enabled: false),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  double _calcInterval() {
    if (data.isEmpty) return 10;
    final maxVal = data.reduce((a, b) => a > b ? a : b);
    if (maxVal <= 0) return 10;
    return (maxVal / 4).ceilToDouble().clamp(1, 1000);
  }
}
