import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class SheetsService {
  static Future<void> log(String phone, String date, String time, bool waSent) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final credsJson = prefs.getString('creds');
      if (credsJson == null || credsJson.isEmpty) return;

      final creds = json.decode(credsJson);
      final token = await _getToken(creds);
      if (token == null) return;

      final sheetName = prefs.getString('sheet_name') ?? 'Community Call Logs';
      String? sheetId = prefs.getString('sheet_id');

      if (sheetId == null) {
        sheetId = await _findOrCreateSheet(token, sheetName);
        if (sheetId != null) await prefs.setString('sheet_id', sheetId);
      }

      if (sheetId == null) return;

      await http.post(
        Uri.parse('https://sheets.googleapis.com/v4/spreadsheets/$sheetId/values/Sheet1:append?valueInputOption=RAW'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: json.encode({'values': [[phone, date, time, 'Missed Call', waSent ? 'Yes' : 'No']]}),
      );
    } catch (e) {
      print('Sheets error: $e');
    }
  }

  static Future<String?> _getToken(Map creds) async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final payload = {
        'iss': creds['client_email'],
        'scope': 'https://www.googleapis.com/auth/spreadsheets https://www.googleapis.com/auth/drive',
        'aud': 'https://oauth2.googleapis.com/token',
        'exp': now + 3600,
        'iat': now,
      };
      // JWT signing would go here — simplified for now
      // In production use googleapis_auth package
      return null;
    } catch (_) { return null; }
  }

  static Future<String?> _findOrCreateSheet(String token, String name) async {
    try {
      final res = await http.get(
        Uri.parse('https://www.googleapis.com/drive/v3/files?q=name%3D%27$name%27%20and%20mimeType%3D%27application%2Fvnd.google-apps.spreadsheet%27'),
        headers: {'Authorization': 'Bearer $token'},
      );
      final data = json.decode(res.body);
      if (data['files'] != null && (data['files'] as List).isNotEmpty) {
        return data['files'][0]['id'];
      }
      return null;
    } catch (_) { return null; }
  }
}
