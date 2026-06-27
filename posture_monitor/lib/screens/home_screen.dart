import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../providers/posture_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PostureProvider>(context);

    // Theme Variables
    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (provider.postureStatus == 1) {
      statusColor = const Color(0xFFFBBF24); // Amber
      statusText = "WARNING";
      statusIcon = Icons.warning_rounded;
    } else if (provider.postureStatus == 2) {
      statusColor = const Color(0xFFEF4444); // Red
      statusText = "BAD";
      statusIcon = Icons.error_rounded;
    } else {
      statusColor = const Color(0xFF10B981); // Emerald
      statusText = "GOOD";
      statusIcon = Icons.check_circle_rounded;
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Posture Correction",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "Real-time tracking",
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF6B7280),
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    provider.connectionState == BluetoothConnectionState.connected 
                        ? Icons.bluetooth_connected_rounded 
                        : Icons.bluetooth_disabled_rounded,
                    color: provider.connectionState == BluetoothConnectionState.connected 
                        ? const Color(0xFF10B981) 
                        : const Color(0xFF9CA3AF),
                    size: 28,
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // Animated Circular Status Indicator
              Center(
                child: TweenAnimationBuilder(
                  tween: ColorTween(begin: statusColor, end: statusColor),
                  duration: const Duration(milliseconds: 500),
                  builder: (context, Color? color, child) {
                    return Container(
                      width: 280,
                      height: 280,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: SweepGradient(
                          colors: [
                            color!.withOpacity(0.1),
                            color.withOpacity(0.4),
                            color.withOpacity(0.8),
                            color.withOpacity(0.4),
                            color.withOpacity(0.1),
                          ],
                          stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.3),
                            blurRadius: 40,
                            spreadRadius: 10,
                          )
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            border: Border.all(
                              color: color.withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  statusIcon,
                                  color: color,
                                  size: 48,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  statusText,
                                  style: TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2,
                                    color: const Color(0xFF1F2937),
                                    shadows: [
                                      Shadow(
                                        color: color.withOpacity(0.3),
                                        blurRadius: 10,
                                      )
                                    ]
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 40),

              // Glassmorphic Info Cards Grid
              Row(
                children: [
                  _buildGlassCard(
                    context,
                    title: "Leaning",
                    value: "${provider.leaningAngle}°",
                    icon: Icons.rotate_right_rounded,
                    color: const Color(0xFF3B82F6),
                  ),
                  const SizedBox(width: 16),
                  _buildGlassCard(
                    context,
                    title: "Bad Posture",
                    value: "${provider.badPostureSeconds ~/ 60}m",
                    icon: Icons.timer_rounded,
                    color: const Color(0xFFEF4444),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Bento Grid Style Summary
              const Text(
                "Daily Summary",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.black.withOpacity(0.05)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _buildSummaryStat("Total Time", "${provider.totalSittingSeconds ~/ 3600}h ${(provider.totalSittingSeconds % 3600) ~/ 60}m")),
                        const SizedBox(width: 16),
                        Expanded(child: _buildSummaryStat("Leaning Time", "${(provider.warningPostureSeconds + provider.badPostureSeconds) ~/ 3600}h ${((provider.warningPostureSeconds + provider.badPostureSeconds) % 3600) ~/ 60}m")),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Divider(color: Colors.black12),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildProgress("Good", const Color(0xFF10B981), provider.goodPostureSeconds, provider.totalSittingSeconds),
                              const SizedBox(height: 12),
                              _buildProgress("Warning", const Color(0xFFFBBF24), provider.warningPostureSeconds, provider.totalSittingSeconds),
                              const SizedBox(height: 12),
                              _buildProgress("Bad", const Color(0xFFEF4444), provider.badPostureSeconds, provider.totalSittingSeconds),
                            ],
                          ),
                        ),
                        const SizedBox(width: 32),
                        SizedBox(
                          width: 80,
                          height: 80,
                          child: PieChart(
                            PieChartData(
                              sectionsSpace: 2,
                              centerSpaceRadius: 25,
                              sections: [
                                PieChartSectionData(color: const Color(0xFF10B981), value: provider.goodPostureSeconds.toDouble() + 1, radius: 10, showTitle: false),
                                PieChartSectionData(color: const Color(0xFFFBBF24), value: provider.warningPostureSeconds.toDouble(), radius: 12, showTitle: false),
                                PieChartSectionData(color: const Color(0xFFEF4444), value: provider.badPostureSeconds.toDouble(), radius: 14, showTitle: false),
                              ],
                            )
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }



  Widget _buildGlassCard(BuildContext context, {required String title, required String value, required IconData icon, required Color color, bool fullWidth = false}) {
    Widget cardContent = Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1F2937),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
        ],
      ),
    );

    return fullWidth ? cardContent : Expanded(child: cardContent);
  }

  Widget _buildSummaryStat(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Color(0xFF1F2937), fontWeight: FontWeight.w800, fontSize: 18)),
      ],
    );
  }

  Widget _buildProgress(String label, Color color, int value, int total) {
    double percentage = total == 0 ? 0 : (value / total);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
            Text("${(percentage * 100).toStringAsFixed(0)}%", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage,
            backgroundColor: Colors.black.withOpacity(0.05),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}
