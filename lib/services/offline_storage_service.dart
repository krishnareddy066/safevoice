import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class OfflineStorageService {
  static const String _key = "offline_reports";

  // SAVE
  static Future<void> saveOfflineReport(
      Map<String, dynamic> report) async {
    final prefs = await SharedPreferences.getInstance();

    final List<String> list =
        prefs.getStringList(_key) ?? [];

    // Ensure JSON-safe
    final safeData = Map<String, dynamic>.from(report);

    list.add(jsonEncode(safeData));

    await prefs.setStringList(_key, list);
  }

  // GET
  static Future<List<Map<String, dynamic>>>
  getOfflineReports() async {
    final prefs = await SharedPreferences.getInstance();

    final List<String> list =
        prefs.getStringList(_key) ?? [];

    return list.map((e) {
      final decoded = jsonDecode(e);

      return Map<String, dynamic>.from(decoded);
    }).toList();
  }

  // DELETE
  static Future<void> deleteOfflineReport(
      String reportId) async {
    final prefs = await SharedPreferences.getInstance();

    final List<String> list =
        prefs.getStringList(_key) ?? [];

    list.removeWhere((e) {
      final data = jsonDecode(e);
      return data['report_id'] == reportId;
    });

    await prefs.setStringList(_key, list);
  }
}
