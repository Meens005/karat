// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import '../models/gold_current.dart';
import '../services/gold_api_service.dart';
import '../widgets/price_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  GoldCurrent? _current;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await GoldApiService.fetchCurrent();
      setState(() { _current = data; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gold Predictor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _load,
          )
        ],
      ),
      body: RefreshIndicator(
        color: AppTheme.gold,
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.gold))
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.wifi_off_rounded, color: Colors.grey, size: 48),
                        const SizedBox(height: 12),
                        Text(
                          'Could not reach server',
                          style: GoogleFonts.dmSans(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            'The server may be waking up from sleep.\nPlease wait a moment and retry.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.dmSans(color: Colors.grey, fontSize: 13, height: 1.5),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.gold, foregroundColor: Colors.black),
                          onPressed: _load,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        )
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      Text(
                        'Live Gold Rates',
                        style: GoogleFonts.playfairDisplay(
                          color: AppTheme.gold,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Rates updated from market data',
                        style: GoogleFonts.dmSans(color: Colors.grey, fontSize: 13),
                      ),
                      const SizedBox(height: 24),
                      PriceCard(
                        label: '24K Gold (per 10g)',
                        value: '₹${_current!.price10g24k.toStringAsFixed(2)}',
                        subtitle: 'International rate in INR',
                        icon: Icons.circle,
                        iconColor: AppTheme.gold,
                        highlight: true,
                      ),
                      const SizedBox(height: 16),
                      PriceCard(
                        label: 'Kerala Pavan (22K)',
                        value: '₹${_current!.pricePavan.toStringAsFixed(2)}',
                        subtitle: '8g • 91.6% purity',
                        icon: Icons.circle,
                        iconColor: const Color(0xFFFFD700),
                      ),
                      const SizedBox(height: 16),
                      PriceCard(
                        label: 'USD Index (DX=F)',
                        value: _current!.usdPrice.toStringAsFixed(3),
                        subtitle: 'US Dollar strength index',
                        icon: Icons.attach_money_rounded,
                        iconColor: Colors.greenAccent,
                      ),
                      const SizedBox(height: 32),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.gold.withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline_rounded, color: AppTheme.gold, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Gold pavan price = (10g price × 0.8 × 0.916)',
                                style: GoogleFonts.dmSans(color: Colors.grey, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}