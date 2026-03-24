// lib/models/gold_prediction.dart
class GoldPrediction {
  final int daysAhead;
  final double prediction10g;     // only the Nth day
  final double predictionPavan;   // only the Nth day

  GoldPrediction({
    required this.daysAhead,
    required this.prediction10g,
    required this.predictionPavan,
  });

  /// Backend returns full lists e.g. predictions_10g: [d1, d2, ... dN]
  /// We only show the last (Nth) day to the user.
  factory GoldPrediction.fromJson(Map<String, dynamic> json, int daysAhead) {
    final list10g = (json['predictions_10g'] as List)
        .map((e) => (e as num).toDouble())
        .toList();
    final listPavan = (json['predictions_pavan'] as List)
        .map((e) => (e as num).toDouble())
        .toList();

    return GoldPrediction(
      daysAhead: daysAhead,
      prediction10g: list10g.last,
      predictionPavan: listPavan.last,
    );
  }
}