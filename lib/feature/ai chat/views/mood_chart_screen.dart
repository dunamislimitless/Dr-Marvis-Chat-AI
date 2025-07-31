import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../view-model/chat_provider.dart';

class MoodChartScreen extends StatelessWidget {
  const MoodChartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final moodCounts = Provider.of<ChatProvider>(context).moodCounts;

    return Scaffold(
      backgroundColor: const Color.fromARGB(
        147,
        255,
        255,
        255,
      ).withOpacity(0.9),
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white24),
        title: const Text('Mood Trends', style: TextStyle(color: Colors.white)),
        backgroundColor: Color.fromARGB(255, 5, 56, 103),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, _) {
                    switch (value.toInt()) {
                      case 0:
                        return const Text('Happy');
                      case 1:
                        return const Text('Sad');
                      case 2:
                        return const Text('Anxious');
                      default:
                        return const Text('');
                    }
                  },
                ),
              ),
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
            ),
            borderData: FlBorderData(show: false),
            barGroups: [
              BarChartGroupData(
                x: 0,
                barRods: [
                  BarChartRodData(
                    toY: (moodCounts['Happy'] ?? 0).toDouble(),
                    color: Colors.green,
                  ),
                ],
              ),
              BarChartGroupData(
                x: 1,
                barRods: [
                  BarChartRodData(
                    toY: (moodCounts['Sad'] ?? 0).toDouble(),
                    color: Colors.blue,
                  ),
                ],
              ),
              BarChartGroupData(
                x: 2,
                barRods: [
                  BarChartRodData(
                    toY: (moodCounts['Anxious'] ?? 0).toDouble(),
                    color: Colors.red,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
