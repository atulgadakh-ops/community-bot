import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _sendWa = true;
  bool _logSheets = true;
  bool _notify = true;
  bool _credsSet = false;
  final _sheetCtrl = TextEditingController(text: 'Community Call Logs');
  final _credsCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _sendWa = prefs.getBool('send_wa') ?? true;
      _logSheets = prefs.getBool('log_sheets') ?? true;
      _notify = prefs.getBool('notify') ?? true;
      _credsSet = (prefs.getString('creds') ?? '').isNotEmpty;
      _sheetCtrl.text = prefs.getString('sheet_name') ?? 'Community Call Logs';
    });
  }

  Future<void> _toggle(String key, bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, val);
  }

  Future<void> _saveCreds() async {
    final text = _credsCtrl.text.trim();
    if (text.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('creds', text);
    await prefs.remove('sheet_id');
    setState(() => _credsSet = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Credentials saved!'), backgroundColor: Colors.green),
    );
  }

  Future<void> _saveSheet() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sheet_name', _sheetCtrl.text);
    await prefs.remove('sheet_id');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Sheet name saved!'), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('⚙️ Settings', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _header('Bot Options'),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(children: [
              SwitchListTile(
                secondary: const CircleAvatar(
                  backgroundColor: Color(0xFFE8F5E9),
                  child: Icon(Icons.chat_bubble, color: Colors.green),
                ),
                title: const Text('Send WhatsApp Message'),
                subtitle: const Text('Auto-send on missed call'),
                value: _sendWa,
                activeColor: const Color(0xFFE94560),
                onChanged: (v) { setState(() => _sendWa = v); _toggle('send_wa', v); },
              ),
              const Divider(height: 1, indent: 72),
              SwitchListTile(
                secondary: const CircleAvatar(
                  backgroundColor: Color(0xFFE3F2FD),
                  child: Icon(Icons.table_chart, color: Colors.blue),
                ),
                title: const Text('Log to Google Sheets'),
                subtitle: const Text('Save all missed calls'),
                value: _logSheets,
                activeColor: const Color(0xFFE94560),
                onChanged: (v) { setState(() => _logSheets = v); _toggle('log_sheets', v); },
              ),
              const Divider(height: 1, indent: 72),
              SwitchListTile(
                secondary: const CircleAvatar(
                  backgroundColor: Color(0xFFF3E5F5),
                  child: Icon(Icons.notifications, color: Colors.purple),
                ),
                title: const Text('Notifications'),
                subtitle: const Text('Show alert on missed call'),
                value: _notify,
                activeColor: const Color(0xFFE94560),
                onChanged: (v) { setState(() => _notify = v); _toggle('notify', v); },
              ),
            ]),
          ),
          const SizedBox(height: 16),

          _header('Google Sheets'),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(Icons.circle, size: 10, color: _credsSet ? Colors.green : Colors.red),
                  const SizedBox(width: 8),
                  Text(
                    _credsSet ? 'credentials.json ✅ Added' : 'credentials.json — Not added',
                    style: TextStyle(color: _credsSet ? Colors.green : Colors.red, fontWeight: FontWeight.w600),
                  ),
                ]),
                const SizedBox(height: 12),
                const Text('Paste credentials.json content:', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(
                  controller: _credsCtrl,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: '{"type":"service_account",...}',
                    filled: true,
                    fillColor: const Color(0xFFF5F5F5),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(onPressed: _saveCreds, child: const Text('Save Credentials')),
                ),
                const Divider(height: 24),
                const Text('Sheet Name:', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: TextField(
                    controller: _sheetCtrl,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF5F5F5),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                  )),
                  const SizedBox(width: 8),
                  ElevatedButton(onPressed: _saveSheet, child: const Text('Save')),
                ]),
              ]),
            ),
          ),
          const SizedBox(height: 16),

          _header('About'),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: const Padding(
              padding: EdgeInsets.all(20),
              child: Column(children: [
                CircleAvatar(radius: 30, backgroundColor: Color(0xFFE94560),
                  child: Text('🌸', style: TextStyle(fontSize: 28))),
                SizedBox(height: 10),
                Text('Community Bot', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('v1.0.0', style: TextStyle(color: Colors.grey)),
                SizedBox(height: 4),
                Text('Maratha Community', style: TextStyle(color: Colors.grey)),
              ]),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _header(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 8, left: 4),
    child: Text(t, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F3460))),
  );

  @override
  void dispose() { _sheetCtrl.dispose(); _credsCtrl.dispose(); super.dispose(); }
}
