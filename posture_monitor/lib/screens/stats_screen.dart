import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/posture_provider.dart';
import '../models/posture_data.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PostureProvider>(context);

    // Limit history to the last 50 data points for performance and readability
    final dataPoints = provider.history.length > 50 
        ? provider.history.sublist(provider.history.length - 50) 
        : provider.history;

    final startTime = provider.history.isNotEmpty ? provider.history.first.timestamp : DateTime.now();

    List<FlSpot> flexSpots = [];
    List<FlSpot> mpuSpots = [];
    for (int i = 0; i < dataPoints.length; i++) {
      flexSpots.add(FlSpot(i.toDouble(), dataPoints[i].flexValue.toDouble()));
      mpuSpots.add(FlSpot(i.toDouble(), dataPoints[i].mpuAngle));
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Analytics",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Sensor History",
                        style: TextStyle(
                          fontSize: 16,
                          color: const Color(0xFF6B7280),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Clear Data'),
                              content: const Text('Are you sure you want to delete all historical data?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    provider.clearHistory();
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Data cleared'))
                                    );
                                  },
                                  child: const Text('Clear', style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.download_rounded, color: Color(0xFF3B82F6)),
                        onPressed: () async {
                          final result = await provider.exportData();
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result)));
                        },
                      ),
                    ],
                  )
                ],
              ),
              const SizedBox(height: 32),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    // Flex Sensor Chart
                    const Text("Flex Sensor (Bend Level)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 16),
                    Container(
                      height: 250,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.black.withOpacity(0.05)),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))
                        ],
                      ),
                      child: flexSpots.isEmpty
                          ? const Center(child: Text("No data yet", style: TextStyle(color: Color(0xFF6B7280))))
                          : _buildChart(flexSpots, const Color(0xFF3B82F6), "Flex Value", dataPoints, startTime),
                    ),
                    const SizedBox(height: 32),
                    
                    // MPU6050 Chart
                    const Text("Body Tilt Angle", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 16),
                    Container(
                      height: 250,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.black.withOpacity(0.05)),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))
                        ],
                      ),
                      child: mpuSpots.isEmpty
                          ? const Center(child: Text("No data yet", style: TextStyle(color: Color(0xFF6B7280))))
                          : _buildChart(mpuSpots, const Color(0xFF10B981), "Angle (°)", dataPoints, startTime),
                    ),
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

  Widget _buildChart(List<FlSpot> spots, Color color, String yLabel, List<PostureData> dataPoints, DateTime startTime) {
    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: color,
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(0.3),
                  color.withOpacity(0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            axisNameWidget: Text(yLabel, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
            axisNameSize: 20,
            sideTitles: SideTitles(
              showTitles: true, 
              reservedSize: 45,
              getTitlesWidget: (value, meta) {
                return Text(value.toInt().toString(), style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280)));
              },
            ),
          ),
          bottomTitles: AxisTitles(
            axisNameWidget: const Text("Time (Seconds)", style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
            axisNameSize: 20,
            sideTitles: SideTitles(
              showTitles: true, 
              reservedSize: 30,
              interval: 10,
              getTitlesWidget: (value, meta) {
                int index = value.toInt();
                if (index < 0 || index >= dataPoints.length) {
                  return const SizedBox.shrink();
                }
                int seconds = dataPoints[index].timestamp.difference(startTime).inSeconds;
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text("${seconds}s", style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280))),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: true, border: const Border(bottom: BorderSide(color: Colors.black12), left: BorderSide(color: Colors.black12))),
      ),
    );
  }
}
