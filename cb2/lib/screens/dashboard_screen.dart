import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/db_service.dart';
import '../services/call_handler.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _botActive = false;
  bool _sheetsReady = false;
  int _totalCalls = 0;
  int _todayCalls = 0;
  String _lastCaller = 'None';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final logs = await DbService.getLogs();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    setState(() {
      _botActive = prefs.getBool('bot_active') ?? false;
      _sheetsReady = (prefs.getString('creds') ?? '').isNotEmpty;
      _totalCalls = logs.length;
      _todayCalls = logs.where((l) => (l['date'] ?? '').startsWith(today)).length;
      _lastCaller = logs.isNotEmpty ? (logs.last['phone'] ?? 'None') : 'None';
    });
  }

  Future<void> _toggleBot() async {
    final prefs = await SharedPreferences.getInstance();
    final granted = await CallHandler.requestPermissions();
    if (!granted && !_botActive) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone permission required'), backgroundColor: Colors.red),
      );
      return;
    }
    final next = !_botActive;
    await prefs.setBool('bot_active', next);
    setState(() => _botActive = next);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(next ? '✅ Bot is now active!' : '⏸ Bot paused'),
        backgroundColor: next ? Colors.green : Colors.orange,
      ),
    );
  }

  Future<void> _testCall() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Testing with +919999999999...'), backgroundColor: Colors.blue),
    );
    await CallHandler.handle('+919999999999');
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('🌸 Community Bot', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Bot toggle
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Auto Handler', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(
                        _botActive ? '● Active — watching calls' : '○ Paused',
                        style: TextStyle(color: _botActive ? Colors.green : Colors.grey, fontSize: 13),
                      ),
                    ]),
                    Switch(
                      value: _botActive,
                      onChanged: (_) => _toggleBot(),
                      activeColor: const Color(0xFFE94560),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Stats
            Row(children: [
              Expanded(child: _statCard('Total', _totalCalls, Icons.call, const Color(0xFF0F3460))),
              const SizedBox(width: 12),
              Expanded(child: _statCard('Today', _todayCalls, Icons.today, const Color(0xFFE94560))),
            ]),
            const SizedBox(height: 12),

            // Last caller
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE94560),
                  child: Icon(Icons.phone_missed, color: Colors.white),
                ),
                title: const Text('Last Missed Call', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(_lastCaller),
                trailing: _lastCaller != 'None'
                  ? IconButton(
                      icon: const Icon(Icons.open_in_new, color: Colors.green),
                      onPressed: () => CallHandler.openWhatsApp(_lastCaller),
                    )
                  : null,
              ),
            ),
            const SizedBox(height: 12),

            // Status
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    _statusRow('Bot Active', _botActive),
                    _statusRow('Google Sheets Ready', _sheetsReady),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Test button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.bug_report),
                label: const Text('Test Bot (Simulate Missed Call)'),
                onPressed: _testCall,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, int value, IconData icon, Color color) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text('$value', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ]),
      ),
    );
  }

  Widget _statusRow(String label, bool ok) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        Icon(ok ? Icons.check_circle : Icons.cancel, color: ok ? Colors.green : Colors.red, size: 20),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      ]),
    );
  }
}
