import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../core/services/notification_service.dart';

final _notificationsEnabledProvider = StateProvider<bool>((ref) => true);

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  late int _hour;
  late int _minute;

  @override
  void initState() {
    super.initState();
    final storage = ref.read(localStorageServiceProvider);
    _hour = storage.getNotificationHour();
    _minute = storage.getNotificationMinute();
  }

  String _formatTime(int hour, int minute) {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _hour, minute: _minute),
    );
    if (picked != null) {
      final storage = ref.read(localStorageServiceProvider);
      await storage.setNotificationTime(picked.hour, picked.minute);
      setState(() {
        _hour = picked.hour;
        _minute = picked.minute;
      });

      final enabled = ref.read(_notificationsEnabledProvider);
      if (enabled) {
        await NotificationService.cancelAll();
        await NotificationService.scheduleDailyMotivation(
          id: 0,
          hour: picked.hour,
          minute: picked.minute,
          body: 'Time to check in with yourself.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled = ref.watch(_notificationsEnabledProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Notification Settings')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Daily Reminder'),
            subtitle: const Text('Get a daily notification to check in'),
            value: enabled,
            onChanged: (value) async {
              ref.read(_notificationsEnabledProvider.notifier).state = value;
              if (value) {
                await NotificationService.scheduleDailyMotivation(
                  id: 0,
                  hour: _hour,
                  minute: _minute,
                  body: 'Time to check in with yourself.',
                );
              } else {
                await NotificationService.cancelAll();
              }
            },
          ),
          ListTile(
            enabled: enabled,
            leading: const Icon(Icons.access_time),
            title: const Text('Reminder Time'),
            subtitle: Text(_formatTime(_hour, _minute)),
            trailing: const Icon(Icons.chevron_right),
            onTap: enabled ? _pickTime : null,
          ),
        ],
      ),
    );
  }
}
