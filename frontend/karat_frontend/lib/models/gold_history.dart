// lib/models/gold_history.dart
class GoldHistoryEntry {
  final DateTime date;
  final double price10g24k;
  final double pricePavan;

  GoldHistoryEntry({
    required this.date,
    required this.price10g24k,
    required this.pricePavan,
  });

  factory GoldHistoryEntry.fromJson(Map<String, dynamic> json) =>
      GoldHistoryEntry(
        date: DateTime.parse(json['date']),
        price10g24k: (json['gold_price_10g_24k'] as num).toDouble(),
        pricePavan: (json['kerala_gold_pavan_22k'] as num).toDouble(),
      );
}