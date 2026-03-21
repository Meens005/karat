// lib/widgets/gold_chart.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../models/gold_history.dart';

class GoldChart extends StatefulWidget {
  final List<GoldHistoryEntry> entries;
  final bool showPavan;

  const GoldChart({
    super.key,
    required this.entries,
    this.showPavan = true,
  });

  @override
  State<GoldChart> createState() => _GoldChartState();
}

class _GoldChartState extends State<GoldChart> {
  int? _touchedIndex;

  List<FlSpot> _spots(bool pavan) {
    return widget.entries.asMap().entries.map((e) {
      final val = pavan ? e.value.pricePavan : e.value.price10g24k;
      return FlSpot(e.key.toDouble(), val);
    }).toList();
  }

  double get _minY {
    final vals = widget.entries.map((e) => e.pricePavan < e.price10g24k ? e.pricePavan : e.price10g24k);
    return (vals.reduce((a, b) => a < b ? a : b) * 0.995);
  }

  double get _maxY {
    final vals = widget.entries.map((e) => e.price10g24k);
    return (vals.reduce((a, b) => a > b ? a : b) * 1.005);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.entries.isEmpty) {
      return const Center(child: Text('No data', style: TextStyle(color: Colors.grey)));
    }

    return Column(
      children: [
        // Legend row
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              _legendDot(AppTheme.gold, '24K / 10g'),
              if (widget.showPavan) ...[
                const SizedBox(width: 16),
                _legendDot(Colors.orangeAccent, 'Kerala Pavan'),
              ],
            ],
          ),
        ),
        Expanded(
          child: LineChart(
            LineChartData(
              minY: _minY,
              maxY: _maxY,
              clipData: const FlClipData.all(),
              lineTouchData: LineTouchData(
                touchCallback: (event, response) {
                  setState(() {
                    _touchedIndex = response?.lineBarSpots?.first.spotIndex;
                  });
                },
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => AppTheme.surface,
                  getTooltipItems: (spots) => spots.map((s) {
                    final isFirst = s.barIndex == 0;
                    return LineTooltipItem(
                      '${isFirst ? "24K" : "Pavan"}\n₹${s.y.toStringAsFixed(0)}',
                      GoogleFonts.dmSans(
                        color: isFirst ? AppTheme.gold : Colors.orangeAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  }).toList(),
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: true,
                getDrawingHorizontalLine: (_) =>
                    const FlLine(color: Color(0xFF222222), strokeWidth: 1),
                getDrawingVerticalLine: (_) =>
                    const FlLine(color: Color(0xFF222222), strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 60,
                    interval: (_maxY - _minY) / 4,
                    getTitlesWidget: (v, _) => Text(
                      '₹${(v / 1000).toStringAsFixed(1)}k',
                      style: GoogleFonts.dmSans(color: Colors.grey, fontSize: 10),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    interval: (widget.entries.length / 4).ceilToDouble(),
                    getTitlesWidget: (v, _) {
                      final idx = v.toInt();
                      if (idx < 0 || idx >= widget.entries.length) return const SizedBox();
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          DateFormat('d MMM').format(widget.entries[idx].date),
                          style: GoogleFonts.dmSans(color: Colors.grey, fontSize: 10),
                        ),
                      );
                    },
                  ),
                ),
              ),
              lineBarsData: [
                // 24K line
                LineChartBarData(
                  spots: _spots(false),
                  isCurved: true,
                  curveSmoothness: 0.3,
                  color: AppTheme.gold,
                  barWidth: 2.5,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, _, __, index) {
                      final isActive = index == _touchedIndex;
                      return FlDotCirclePainter(
                        radius: isActive ? 5 : 0,
                        color: AppTheme.gold,
                        strokeWidth: isActive ? 2 : 0,
                        strokeColor: Colors.white,
                      );
                    },
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppTheme.gold.withOpacity(0.18),
                        AppTheme.gold.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
                // Pavan line
                if (widget.showPavan)
                  LineChartBarData(
                    spots: _spots(true),
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: Colors.orangeAccent,
                    barWidth: 1.8,
                    dashArray: [6, 4],
                    dotData: const FlDotData(show: false),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _legendDot(Color color, String label) => Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(label, style: GoogleFonts.dmSans(color: Colors.grey, fontSize: 12)),
        ],
      );
}