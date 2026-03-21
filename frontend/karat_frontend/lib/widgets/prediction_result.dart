// lib/widgets/prediction_result.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import '../models/gold_prediction.dart';

class PredictionResult extends StatefulWidget {
  final GoldPrediction prediction;
  final double? basePrice; // last known price for trend comparison

  const PredictionResult({
    super.key,
    required this.prediction,
    this.basePrice,
  });

  @override
  State<PredictionResult> createState() => _PredictionResultState();
}

class _PredictionResultState extends State<PredictionResult>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  bool _show24k = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<double> get _activePrices =>
      _show24k ? widget.prediction.predictions10g24k : widget.prediction.predictionsPavan;

  double get _minVal => _activePrices.reduce((a, b) => a < b ? a : b) * 0.997;
  double get _maxVal => _activePrices.reduce((a, b) => a > b ? a : b) * 1.003;

  bool get _isBullish =>
      _activePrices.last > _activePrices.first;

  double get _changePercent {
    if (_activePrices.length < 2) return 0;
    return ((_activePrices.last - _activePrices.first) / _activePrices.first) * 100;
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Toggle 24K / Pavan
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                _toggleBtn('24K / 10g', true),
                _toggleBtn('Kerala Pavan', false),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Summary row
          Row(
            children: [
              Expanded(
                child: _summaryTile(
                  'Day 1 Forecast',
                  '₹${_activePrices.first.toStringAsFixed(0)}',
                  Icons.today_rounded,
                  AppTheme.gold,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _summaryTile(
                  'Day ${_activePrices.length} Forecast',
                  '₹${_activePrices.last.toStringAsFixed(0)}',
                  Icons.event_rounded,
                  Colors.blueAccent,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Trend badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: (_isBullish ? Colors.green : Colors.red).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: (_isBullish ? Colors.green : Colors.red).withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _isBullish ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                  color: _isBullish ? Colors.greenAccent : Colors.redAccent,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  _isBullish ? 'Bullish trend over forecast window' : 'Bearish trend over forecast window',
                  style: GoogleFonts.dmSans(
                    color: _isBullish ? Colors.greenAccent : Colors.redAccent,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_isBullish ? "+" : ""}${_changePercent.toStringAsFixed(2)}%',
                  style: GoogleFonts.dmSans(
                    color: _isBullish ? Colors.greenAccent : Colors.redAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Chart
          Text(
            'Forecast Trend',
            style: GoogleFonts.dmSans(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                minY: _minVal,
                maxY: _maxVal,
                gridData: FlGridData(
                  show: true,
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
                      reservedSize: 58,
                      getTitlesWidget: (v, _) => Text(
                        '₹${(v / 1000).toStringAsFixed(1)}k',
                        style: GoogleFonts.dmSans(color: Colors.grey, fontSize: 10),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) => Text(
                        'D${v.toInt() + 1}',
                        style: GoogleFonts.dmSans(color: Colors.grey, fontSize: 10),
                      ),
                    ),
                  ),
                ),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => AppTheme.surface,
                    getTooltipItems: (spots) => spots
                        .map((s) => LineTooltipItem(
                              'Day ${s.spotIndex + 1}\n₹${s.y.toStringAsFixed(0)}',
                              GoogleFonts.dmSans(
                                color: AppTheme.gold,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ))
                        .toList(),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: _activePrices
                        .asMap()
                        .entries
                        .map((e) => FlSpot(e.key.toDouble(), e.value))
                        .toList(),
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: AppTheme.gold,
                    barWidth: 2.5,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                        radius: 3,
                        color: AppTheme.gold,
                        strokeWidth: 1.5,
                        strokeColor: Colors.white,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppTheme.gold.withOpacity(0.2),
                          AppTheme.gold.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Day-by-day table
          Text(
            'Day-by-day Breakdown',
            style: GoogleFonts.dmSans(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.cardBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.prediction.predictions10g24k.length,
              separatorBuilder: (_, __) => Divider(
                color: AppTheme.surface,
                height: 1,
                indent: 16,
                endIndent: 16,
              ),
              itemBuilder: (context, i) {
                final p24k = widget.prediction.predictions10g24k[i];
                final pPavan = widget.prediction.predictionsPavan[i];
                final isUp = i == 0
                    ? true
                    : p24k >= widget.prediction.predictions10g24k[i - 1];

                return ListTile(
                  leading: CircleAvatar(
                    radius: 16,
                    backgroundColor: AppTheme.gold.withOpacity(0.12),
                    child: Text(
                      '${i + 1}',
                      style: GoogleFonts.dmSans(
                        color: AppTheme.gold,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    '₹${p24k.toStringAsFixed(2)}',
                    style: GoogleFonts.dmSans(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: Text(
                    '24K / 10g',
                    style: GoogleFonts.dmSans(color: Colors.grey, fontSize: 11),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${pPavan.toStringAsFixed(2)}',
                        style: GoogleFonts.dmSans(
                          color: Colors.orangeAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isUp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                            size: 12,
                            color: isUp ? Colors.greenAccent : Colors.redAccent,
                          ),
                          Text(
                            'Pavan',
                            style: GoogleFonts.dmSans(color: Colors.grey, fontSize: 10),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _toggleBtn(String label, bool is24k) {
    final selected = _show24k == is24k;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _show24k = is24k),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppTheme.gold : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              color: selected ? Colors.black : Colors.grey,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _summaryTile(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.dmSans(color: Colors.grey, fontSize: 11)),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: GoogleFonts.playfairDisplay(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}