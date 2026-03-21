// lib/models/gold_current.dart
class GoldCurrent {
  final double price10g24k;
  final double pricePavan;
  final double usdPrice;

  GoldCurrent({
    required this.price10g24k,
    required this.pricePavan,
    required this.usdPrice,
  });

  factory GoldCurrent.fromJson(Map<String, dynamic> json) => GoldCurrent(
        price10g24k: (json['gold_price_10g_24k'] as num).toDouble(),
        pricePavan: (json['kerala_gold_pavan_22k'] as num).toDouble(),
        usdPrice: (json['usd_price'] as num).toDouble(),
      );
}