import 'package:flutter/material.dart';
import '../services/db_service.dart';

class CallsScreen extends StatefulWidget {
  const CallsScreen({super.key});

  @override
  State<CallsScreen> createState() => _CallsScreenState();
}

class _CallsScreenState extends State<CallsScreen> {
  List<Map<String, dynamic>> _logs = [];
  bool _loading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final logs = await DbService.getLogs();
    setState(() {
      _logs = logs.reversed.toList();
      _loading = false;
    });
  }

  List<Map<String, dynamic>> get _filtered =>
    _query.isEmpty ? _logs : _logs.where((l) => (l['phone'] ?? '').contains(_query)).toList();

  int get _todayCount {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    return _logs.where((l) => (l['date'] ?? '').startsWith(today)).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('📋 Call Logs', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.delete_outline), onPressed: _confirmClear),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search number...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(color: const Color(0xFF0F3460), borderRadius: BorderRadius.circular(12)),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _chip('Total', _logs.length),
            _chip('Today', _todayCount),
          ]),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _filtered.isEmpty
              ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.call_missed, size: 60, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('No calls yet', style: TextStyle(color: Colors.grey)),
                ]))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _filtered.length,
                    itemBuilder: (_, i) {
                      final log = _filtered[i];
                      final waSent = log['wa_sent'] == 1;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFFE94560).withOpacity(0.1),
                            child: const Icon(Icons.phone_missed, color: Color(0xFFE94560)),
                          ),
                          title: Text(log['phone'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${log['date'] ?? ''} ${log['time'] ?? ''}',
                            style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          trailing: Icon(
                            Icons.check_circle,
                            color: waSent ? Colors.green : Colors.grey.shade300,
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ]),
    );
  }

  Widget _chip(String label, int count) {
    return Column(children: [
      Text('$count', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
    ]);
  }

  Future<void> _confirmClear() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Logs?'),
        content: const Text('All call history will be deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Clear')),
        ],
      ),
    );
    if (ok == true) { await DbService.clearLogs(); _load(); }
  }
}
