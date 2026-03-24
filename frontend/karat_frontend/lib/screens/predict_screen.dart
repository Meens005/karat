// lib/screens/predict_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import '../models/gold_prediction.dart';
import '../services/gold_api_service.dart';

class PredictScreen extends StatefulWidget {
  const PredictScreen({super.key});

  @override
  State<PredictScreen> createState() => _PredictScreenState();
}

class _PredictScreenState extends State<PredictScreen> {
  int _daysAhead = 7;
  GoldPrediction? _result;
  bool _loading = false;
  String? _error;

  Future<void> _predict() async {
    setState(() { _loading = true; _error = null; _result = null; });
    try {
      final data = await GoldApiService.fetchPrediction(_daysAhead);
      setState(() { _result = data; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Price Forecast')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'LSTM Prediction',
            style: GoogleFonts.playfairDisplay(
              color: AppTheme.gold,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Pick a day — we\'ll predict the gold price on that exact day',
            style: GoogleFonts.dmSans(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 28),

          // ── Slider card ──────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Days Ahead', style: GoogleFonts.dmSans(color: Colors.white70)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.gold,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Day $_daysAhead',
                        style: GoogleFonts.dmSans(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _daysAhead.toDouble(),
                  min: 1,
                  max: 60,
                  divisions: 59,
                  activeColor: AppTheme.gold,
                  inactiveColor: AppTheme.surface,
                  onChanged: (v) => setState(() => _daysAhead = v.toInt()),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Tomorrow', style: GoogleFonts.dmSans(color: Colors.grey, fontSize: 11)),
                    Text('60 days', style: GoogleFonts.dmSans(color: Colors.grey, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Forecast button ──────────────────────────
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.gold,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _loading ? null : _predict,
              icon: _loading
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_graph_rounded),
              label: Text(
                _loading ? 'Forecasting…' : 'Predict Day $_daysAhead Price',
                style: GoogleFonts.dmSans(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),

          // ── Error ────────────────────────────────────
          if (_error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_error!, style: GoogleFonts.dmSans(color: Colors.redAccent, fontSize: 13)),
                  ),
                ],
              ),
            ),
          ],

          // ── Result cards ─────────────────────────────
          if (_result != null) ...[
            const SizedBox(height: 32),

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.gold.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.gold.withOpacity(0.4)),
                  ),
                  child: Text(
                    'Day ${_result!.daysAhead} Forecast',
                    style: GoogleFonts.dmSans(
                      color: AppTheme.gold,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 24K card
            _resultCard(
              label: '24K Gold / 10g',
              value: '₹${_result!.prediction10g.toStringAsFixed(2)}',
              sublabel: 'International purity • predicted price',
              color: AppTheme.gold,
              icon: Icons.diamond_outlined,
            ),

            const SizedBox(height: 12),

            // Pavan card
            _resultCard(
              label: 'Kerala Pavan (22K)',
              value: '₹${_result!.predictionPavan.toStringAsFixed(2)}',
              sublabel: '8g • 91.6% purity • local rate',
              color: Colors.orangeAccent,
              icon: Icons.toll_rounded,
            ),

            const SizedBox(height: 20),

            // Disclaimer
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded, color: Colors.grey, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This is an LSTM model prediction and not financial advice. '
                      'Gold prices are influenced by many market factors.',
                      style: GoogleFonts.dmSans(color: Colors.grey, fontSize: 11, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _resultCard({
    required String label,
    required String value,
    required String sublabel,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.dmSans(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.playfairDisplay(
                    color: color,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(sublabel, style: GoogleFonts.dmSans(color: Colors.grey, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}