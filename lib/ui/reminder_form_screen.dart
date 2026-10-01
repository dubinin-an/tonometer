import 'package:flutter/material.dart';

import '../data/app_database.dart';
import '../data/reminder_repository.dart';
import '../domain/reminder_draft.dart';
import '../l10n/l10n.dart';
import '../services/reminder_notification_service.dart';

class ReminderFormScreen extends StatefulWidget {
  const ReminderFormScreen({
    required this.repository,
    required this.notifications,
    this.reminder,
    super.key,
  });

  final ReminderRepository repository;
  final ReminderNotificationService notifications;
  final Reminder? reminder;

  @override
  State<ReminderFormScreen> createState() => _ReminderFormScreenState();
}

class _ReminderFormScreenState extends State<ReminderFormScreen> {
  late TimeOfDay _time;
  late Set<int> _weekdays;
  late bool _enabled;
  var _saving = false;
  int? _savedId;

  @override
  void initState() {
    super.initState();
    final reminder = widget.reminder;
    _savedId = reminder?.id;
    _time = TimeOfDay(hour: reminder?.hour ?? 8, minute: reminder?.minute ?? 0);
    _weekdays = {
      for (var day = DateTime.monday; day <= DateTime.sunday; day++)
        if (reminder == null || reminder.weekdaysMask & (1 << (day - 1)) != 0)
          day,
    };
    _enabled = reminder?.enabled ?? true;
  }

  Future<void> _chooseTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: _time,
      helpText: context.l10n.reminderTime,
    );
    if (selected != null && mounted) setState(() => _time = selected);
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    if (_weekdays.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.selectWeekday)));
      return;
    }
    setState(() => _saving = true);
    try {
      if (_enabled && !await widget.notifications.requestPermission()) {
        if (!mounted) return;
        setState(() => _saving = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.permissionInstruction)));
        return;
      }
      final draft = ReminderDraft(
        hour: _time.hour,
        minute: _time.minute,
        weekdaysMask: _weekdays.fold(0, (mask, day) => mask | 1 << (day - 1)),
        enabled: _enabled,
      );
      final existingId = _savedId;
      final id = existingId ?? await widget.repository.add(draft);
      _savedId = id;
      if (existingId != null) {
        await widget.repository.updateReminder(existingId, draft);
      }
      final saved = await widget.repository.getById(id);
      await widget.notifications.schedule(saved);
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.reminderSaveFailed(error.toString()))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final formattedTime = _time.format(context);
    final weekdayNames = <int, String>{
      DateTime.monday: l10n.weekdayMon,
      DateTime.tuesday: l10n.weekdayTue,
      DateTime.wednesday: l10n.weekdayWed,
      DateTime.thursday: l10n.weekdayThu,
      DateTime.friday: l10n.weekdayFri,
      DateTime.saturday: l10n.weekdaySat,
      DateTime.sunday: l10n.weekdaySun,
    };
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.reminder == null ? l10n.newReminder : l10n.editReminder,
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            OutlinedButton(
              onPressed: _saving ? null : _chooseTime,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(96),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.time),
                  Text(
                    formattedTime,
                    style: Theme.of(context).textTheme.displaySmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(l10n.repeat, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var day = DateTime.monday; day <= DateTime.sunday; day++)
                  FilterChip(
                    label: Text(weekdayNames[day]!),
                    selected: _weekdays.contains(day),
                    onSelected: _saving
                        ? null
                        : (selected) {
                            setState(() {
                              if (selected) {
                                _weekdays.add(day);
                              } else {
                                _weekdays.remove(day);
                              }
                            });
                          },
                  ),
              ],
            ),
            const SizedBox(height: 20),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.reminderEnabled),
              subtitle: Text(l10n.reminderEnabledDetail),
              value: _enabled,
              onChanged: _saving
                  ? null
                  : (value) => setState(() => _enabled = value),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.notifications_active_outlined),
              label: Text(_saving ? l10n.saving : l10n.saveReminder),
            ),
          ],
        ),
      ),
    );
  }
}
