// lib/services/gold_api_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import '../models/gold_current.dart';
import '../models/gold_history.dart';
import '../models/gold_prediction.dart';

class GoldApiService {
  // Render free tier needs a long timeout for cold starts
  static const _timeout = Duration(seconds: 60);

  static Future<http.Response> _get(String path) async {
    try {
      return await http
          .get(Uri.parse('$kBaseUrl$path'))
          .timeout(_timeout);
    } on SocketException {
      throw Exception('No internet connection');
    } catch (e) {
      throw Exception('Connection failed. Server may be waking up, please retry in a moment.');
    }
  }

  static Future<http.Response> _post(String path, Map<String, dynamic> body) async {
    try {
      return await http
          .post(
            Uri.parse('$kBaseUrl$path'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(_timeout);
    } on SocketException {
      throw Exception('No internet connection');
    } catch (e) {
      throw Exception('Connection failed. Server may be waking up, please retry in a moment.');
    }
  }

  // ── Auth ──────────────────────────────────────────────
  static Future<Map<String, dynamic>> login(String username, String password) async {
    final res = await _post('/login', {'username': username, 'password': password});
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) return body;
    throw Exception(body['detail'] ?? 'Login failed');
  }

  // ── Current price ─────────────────────────────────────
  static Future<GoldCurrent> fetchCurrent() async {
    final res = await _get('/current');
    if (res.statusCode == 200) return GoldCurrent.fromJson(jsonDecode(res.body));
    throw Exception('Failed to fetch current price');
  }

  // ── History ───────────────────────────────────────────
  static Future<List<GoldHistoryEntry>> fetchHistory(int days) async {
    final res = await _get('/history?days=$days');
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body)['history'] as List;
      return data.map((e) => GoldHistoryEntry.fromJson(e)).toList();
    }
    throw Exception('Failed to fetch history');
  }

  // ── Prediction ────────────────────────────────────────
  static Future<GoldPrediction> fetchPrediction(int daysAhead) async {
    final res = await _get('/predict?days_ahead=$daysAhead');
    if (res.statusCode == 200) {
      return GoldPrediction.fromJson(jsonDecode(res.body), daysAhead);
    }
    throw Exception('Failed to fetch prediction');
  }
}