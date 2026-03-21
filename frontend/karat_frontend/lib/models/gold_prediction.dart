// lib/models/gold_prediction.dart
class GoldPrediction {
  final int daysAhead;
  final double prediction10g24k;
  final double predictionPavan;

  GoldPrediction({
    required this.daysAhead,
    required this.prediction10g24k,
    required this.predictionPavan,
  });

  factory GoldPrediction.fromJson(Map<String, dynamic> json) => GoldPrediction(
        daysAhead: (json['days_ahead'] as num).toInt(),
        prediction10g24k: (json['prediction_10g_24k'] as num).toDouble(),
        predictionPavan: (json['prediction_pavan'] as num).toDouble(),
      );
}