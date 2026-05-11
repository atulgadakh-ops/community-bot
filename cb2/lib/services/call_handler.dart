import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'db_service.dart';
import 'sheets_service.dart';

class CallHandler {
  static Future<bool> requestPermissions() async {
    final s = await [Permission.phone, Permission.notification].request();
    return s.values.every((e) => e.isGranted);
  }

  static Future<void> handle(String phone) async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool('bot_active') ?? false)) return;

    final now = DateTime.now();
    final date = '${now.year}-${now.month.toString().padLeft(2,'0')}-${now.day.toString().padLeft(2,'0')}';
    final time = '${now.hour.toString().padLeft(2,'0')}:${now.minute.toString().padLeft(2,'0')}';

    bool waSent = false;

    if (prefs.getBool('send_wa') ?? true) {
      final msg = prefs.getString('welcome_msg') ?? _defaultMsg;
      waSent = await openWhatsApp(phone, msg);
    }

    if (prefs.getBool('log_sheets') ?? true) {
      await SheetsService.log(phone, date, time, waSent);
    }

    await DbService.insert(phone, date, time, waSent);
  }

  static Future<bool> openWhatsApp(String phone, [String? msg]) async {
    try {
      final clean = phone.replaceAll(RegExp(r'[^\d]'), '');
      final text = msg != null ? '?text=${Uri.encodeComponent(msg)}' : '';
      final url = Uri.parse('https://wa.me/$clean$text');
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        return true;
      }
    } catch (_) {}
    return false;
  }

  static const _defaultMsg = '👋 Hello! Welcome to *Maratha Community*.\n\n'
    'Thank you for reaching out. We received your missed call.\n\n'
    '📌 Please save our number!\n\n🙏 Regards,\nMaratha Community Team';
}
