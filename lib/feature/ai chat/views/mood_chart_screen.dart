import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../view-model/chat_provider.dart';

class MoodChartScreen extends StatefulWidget {
  const MoodChartScreen({super.key});

  @override
  State<MoodChartScreen> createState() => _MoodChartScreenState();
}

class _MoodChartScreenState extends State<MoodChartScreen> {
  int _selectedRangeDays = 7;

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);
    final moodCounts = chatProvider.moodCountsForLastDays(_selectedRangeDays);
    final happy = (moodCounts['Happy'] ?? 0).toDouble();
    final sad = (moodCounts['Sad'] ?? 0).toDouble();
    final anxious = (moodCounts['Anxious'] ?? 0).toDouble();
    final total = happy + sad + anxious;
    final maxY = [happy, sad, anxious, 4.0].reduce((a, b) => a > b ? a : b) + 1;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF06386A), Color(0xFF0E1C2F)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Mood Trends',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    _rangeToggle(),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.white.withOpacity(0.12)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.insights_rounded,
                              color: Colors.white,
                              size: 30,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                total == 0
                                    ? 'Start chatting to see mood trends.'
                                    : 'Based on ${total.toInt()} tracked mood entries in the last $_selectedRangeDays days.',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.92),
                                  fontSize: 14,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        height: 290,
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(14, 20, 18, 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: BarChart(
                          BarChartData(
                            maxY: maxY,
                            minY: 0,
                            alignment: BarChartAlignment.spaceAround,
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              horizontalInterval: 1,
                              getDrawingHorizontalLine:
                                  (_) => FlLine(
                                    color: Colors.grey.withOpacity(0.18),
                                    strokeWidth: 1,
                                  ),
                            ),
                            borderData: FlBorderData(show: false),
                            titlesData: FlTitlesData(
                              topTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 28,
                                  getTitlesWidget: (value, _) {
                                    final percentages = [
                                      total == 0 ? 0 : ((happy / total) * 100).round(),
                                      total == 0 ? 0 : ((sad / total) * 100).round(),
                                      total == 0 ? 0 : ((anxious / total) * 100).round(),
                                    ];
                                    if (value.toInt() < 0 || value.toInt() >= percentages.length) {
                                      return const SizedBox.shrink();
                                    }
                                    return Text(
                                      '${percentages[value.toInt()]}%',
                                      style: const TextStyle(
                                        color: Color(0xFF607080),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 30,
                                  interval: 1,
                                  getTitlesWidget:
                                      (value, _) => Text(
                                        value.toInt().toString(),
                                        style: const TextStyle(
                                          color: Color(0xFF607080),
                                          fontSize: 11,
                                        ),
                                      ),
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, _) {
                                    final labels = ['Happy', 'Sad', 'Anxious'];
                                    if (value.toInt() < 0 ||
                                        value.toInt() >= labels.length) {
                                      return const SizedBox.shrink();
                                    }
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        labels[value.toInt()],
                                        style: const TextStyle(
                                          color: Color(0xFF425466),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            barGroups: [
                              _barGroup(0, happy, const Color(0xFF22C55E)),
                              _barGroup(1, sad, const Color(0xFF3B82F6)),
                              _barGroup(2, anxious, const Color(0xFFEF4444)),
                            ],
                          ),
                          swapAnimationDuration: const Duration(milliseconds: 500),
                          swapAnimationCurve: Curves.easeOutCubic,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _moodChip('Happy', happy.toInt(), const Color(0xFF22C55E)),
                          _moodChip('Sad', sad.toInt(), const Color(0xFF3B82F6)),
                          _moodChip('Anxious', anxious.toInt(), const Color(0xFFEF4444)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  BarChartGroupData _barGroup(int x, double value, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: value,
          width: 30,
          color: color,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(8),
            topRight: Radius.circular(8),
          ),
        ),
      ],
    );
  }

  Widget _moodChip(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(radius: 5, backgroundColor: color),
          const SizedBox(width: 8),
          Text(
            '$label: $value',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _rangeToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _rangeButton(label: '7D', days: 7),
          _rangeButton(label: '30D', days: 30),
        ],
      ),
    );
  }

  Widget _rangeButton({required String label, required int days}) {
    final isSelected = _selectedRangeDays == days;
    return GestureDetector(
      onTap: () => setState(() => _selectedRangeDays = days),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF06386A) : Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
