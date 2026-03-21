// lib/services/gold_api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import '../models/gold_current.dart';
import '../models/gold_history.dart';
import '../models/gold_prediction.dart';

class GoldApiService {
  // ── Auth ──────────────────────────────────────────────
  static Future<Map<String, dynamic>> login(String username, String password) async {
    final res = await http.post(
      Uri.parse('$kBaseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) return body;
    throw Exception(body['detail'] ?? 'Login failed');
  }

  // ── Current price ─────────────────────────────────────
  static Future<GoldCurrent> fetchCurrent() async {
    final res = await http.get(Uri.parse('$kBaseUrl/current'));
    if (res.statusCode == 200) return GoldCurrent.fromJson(jsonDecode(res.body));
    throw Exception('Failed to fetch current price');
  }

  // ── History ───────────────────────────────────────────
  static Future<List<GoldHistoryEntry>> fetchHistory(int days) async {
    final res = await http.get(Uri.parse('$kBaseUrl/history?days=$days'));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body)['history'] as List;
      return data.map((e) => GoldHistoryEntry.fromJson(e)).toList();
    }
    throw Exception('Failed to fetch history');
  }

  // ── Prediction (single target day) ───────────────────
  static Future<GoldPrediction> fetchPrediction(int daysAhead) async {
    final res = await http.get(Uri.parse('$kBaseUrl/predict?days_ahead=$daysAhead'));
    if (res.statusCode == 200) return GoldPrediction.fromJson(jsonDecode(res.body));
    throw Exception('Failed to fetch prediction');
  }
}