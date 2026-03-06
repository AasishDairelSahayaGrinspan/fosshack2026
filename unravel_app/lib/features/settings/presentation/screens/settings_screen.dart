import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../core/services/health_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late bool _noAdviceMode;
  late int _notifHour;
  late int _notifMinute;

  @override
  void initState() {
    super.initState();
    final storage = ref.read(localStorageServiceProvider);
    _noAdviceMode = storage.getNoAdviceMode();
    _notifHour = storage.getNotificationHour();
    _notifMinute = storage.getNotificationMinute();
  }

  String _formatTime(int hour, int minute) {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _pickNotificationTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _notifHour, minute: _notifMinute),
    );
    if (picked != null) {
      final storage = ref.read(localStorageServiceProvider);
      await storage.setNotificationTime(picked.hour, picked.minute);
      setState(() {
        _notifHour = picked.hour;
        _notifMinute = picked.minute;
      });
    }
  }

  Future<void> _requestHealthPermissions() async {
    final healthService = ref.read(healthServiceProvider);
    final granted = await healthService.requestPermissions();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(granted
              ? 'Health permissions granted'
              : 'Health permissions denied'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('No Advice Mode'),
            subtitle: const Text(
                'Hides breathing exercises and music recommendations'),
            value: _noAdviceMode,
            onChanged: (value) async {
              final storage = ref.read(localStorageServiceProvider);
              await storage.setNoAdviceMode(value);
              ref.read(noAdviceModeProvider.notifier).state = value;
              setState(() => _noAdviceMode = value);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Notification Time'),
            subtitle: Text(_formatTime(_notifHour, _notifMinute)),
            trailing: const Icon(Icons.chevron_right),
            onTap: _pickNotificationTime,
          ),
          ListTile(
            leading: const Icon(Icons.health_and_safety),
            title: const Text('Health Permissions'),
            subtitle: const Text('Connect wearable health data'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _requestHealthPermissions,
          ),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('Community & Friends'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/community'),
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('About Unravel'),
            subtitle: Text('Version 1.0.0'),
          ),
        ],
      ),
    );
  }
}
