// lib/screens/history_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import '../models/gold_history.dart';
import '../services/gold_api_service.dart';
import '../widgets/gold_chart.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<GoldHistoryEntry> _history = [];
  bool _loading = true;
  String? _error;
  int _selectedDays = 30;

  final List<int> _dayOptions = [7, 30, 90, 180];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await GoldApiService.fetchHistory(_selectedDays);
      setState(() { _history = data; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Price History')),
      body: Column(
        children: [
          // Day selector chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: _dayOptions.map((d) {
                final selected = d == _selectedDays;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text('$d days'),
                    selected: selected,
                    selectedColor: AppTheme.gold,
                    backgroundColor: AppTheme.surface,
                    labelStyle: GoogleFonts.dmSans(
                      color: selected ? Colors.black : Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                    onSelected: (_) {
                      setState(() => _selectedDays = d);
                      _load();
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.gold))
                : _error != null
                    ? Center(child: Text('Error: $_error', style: const TextStyle(color: Colors.red)))
                    : _history.isEmpty
                        ? const Center(child: Text('No data', style: TextStyle(color: Colors.grey)))
                        : Padding(
                            padding: const EdgeInsets.all(16),
                            child: GoldChart(entries: _history, showPavan: true),
                          ),
          ),
        ],
      ),
    );
  }
}