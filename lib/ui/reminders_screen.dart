import 'package:flutter/material.dart';

import '../data/app_database.dart';
import '../data/reminder_repository.dart';
import '../l10n/l10n.dart';
import '../services/reminder_notification_service.dart';
import 'reminder_form_screen.dart';

class RemindersScreen extends StatelessWidget {
  const RemindersScreen({
    required this.repository,
    required this.notifications,
    super.key,
  });

  final ReminderRepository repository;
  final ReminderNotificationService notifications;

  Future<void> _openForm(BuildContext context, [Reminder? reminder]) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ReminderFormScreen(
          repository: repository,
          notifications: notifications,
          reminder: reminder,
        ),
      ),
    );
  }

  Future<void> _setEnabled(
    BuildContext context,
    Reminder reminder,
    bool enabled,
  ) async {
    try {
      if (enabled && !await notifications.requestPermission()) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.permissionInstruction)),
        );
        return;
      }
      await repository.setEnabled(reminder.id, enabled);
      final updated = await repository.getById(reminder.id);
      await notifications.schedule(updated);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.reminderChangeFailed(error.toString())),
        ),
      );
    }
  }

  Future<void> _testNotification(BuildContext context) async {
    try {
      if (!await notifications.requestPermission()) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.permissionInstruction)),
        );
        return;
      }
      final scheduledAt = await notifications.scheduleTestNotification();
      if (!context.mounted) return;
      final time = TimeOfDay.fromDateTime(scheduledAt).format(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.testScheduled(time)),
          duration: const Duration(seconds: 8),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.notificationTestFailed(error.toString())),
        ),
      );
    }
  }

  Future<void> _delete(BuildContext context, Reminder reminder) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.deleteReminderTitle),
        content: Text(
          context.l10n.deleteReminderMessage(_formatTime(context, reminder)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(context.l10n.doNotDelete),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(context.l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      // A concurrent lifecycle repair must not resurrect a deleted reminder.
      // Keep a disabled row if cancellation fails so the next repair can retry.
      await repository.setEnabled(reminder.id, false);
      await notifications.cancel(reminder.id);
      await repository.deleteReminder(reminder.id);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.deleteReminderFailed(error.toString())),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.reminders)),
      body: ValueListenableBuilder<int>(
        valueListenable: notifications.revision,
        builder: (context, revision, child) => StreamBuilder<List<Reminder>>(
          stream: repository.watchAll(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    l10n.remindersOpenFailed(snapshot.error.toString()),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final reminders = snapshot.data!;
            if (reminders.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.notifications_none, size: 64),
                      const SizedBox(height: 16),
                      Text(
                        l10n.noReminders,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(l10n.noRemindersDetail, textAlign: TextAlign.center),
                    ],
                  ),
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              itemCount: reminders.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final reminder = reminders[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 12, 6, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _formatTime(context, reminder),
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 4),
                              Text(_formatDays(context, reminder.weekdaysMask)),
                              const SizedBox(height: 4),
                              _ReminderStatus(
                                status: notifications.statusFor(reminder),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: reminder.enabled,
                          onChanged: (value) =>
                              _setEnabled(context, reminder, value),
                        ),
                        PopupMenuButton<_ReminderAction>(
                          tooltip: l10n.reminderActions,
                          onSelected: (action) async {
                            switch (action) {
                              case _ReminderAction.edit:
                                await _openForm(context, reminder);
                                break;
                              case _ReminderAction.delete:
                                await _delete(context, reminder);
                                break;
                            }
                          },
                          itemBuilder: (_) => [
                            PopupMenuItem(
                              value: _ReminderAction.edit,
                              child: ListTile(
                                leading: const Icon(Icons.edit_outlined),
                                title: Text(l10n.edit),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                            PopupMenuItem(
                              value: _ReminderAction.delete,
                              child: ListTile(
                                leading: const Icon(Icons.delete_outline),
                                title: Text(l10n.delete),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton.icon(
              onPressed: () => _openForm(context),
              icon: const Icon(Icons.add_alert_outlined),
              label: Text(l10n.addReminder),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => _testNotification(context),
              icon: const Icon(Icons.notification_add_outlined),
              label: Text(l10n.testInOneMinute),
            ),
            TextButton.icon(
              onPressed: () => _openNotificationSettings(context),
              icon: const Icon(Icons.settings_outlined),
              label: Text(l10n.notificationSettings),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openNotificationSettings(BuildContext context) async {
    try {
      if (await notifications.openNotificationSettings()) return;
    } catch (error) {
      debugPrint('Failed to open notification settings: $error');
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.permissionInstruction)));
  }
}

class _ReminderStatus extends StatelessWidget {
  const _ReminderStatus({required this.status});

  final Future<ReminderScheduleStatus> status;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ReminderScheduleStatus>(
      future: status,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text(
            context.l10n.reminderStatusFailed,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          );
        }
        if (!snapshot.hasData) {
          return const SizedBox(height: 20);
        }
        final value = snapshot.data!;
        final l10n = context.l10n;
        final (icon, text, color) = switch (value.state) {
          ReminderScheduleState.disabled => (
            Icons.notifications_off_outlined,
            l10n.disabled,
            Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          ReminderScheduleState.scheduled => (
            Icons.check_circle_outline,
            l10n.exactlyScheduled,
            Theme.of(context).colorScheme.primary,
          ),
          ReminderScheduleState.approximate => (
            Icons.schedule,
            l10n.approximatelyScheduled,
            Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          ReminderScheduleState.notificationsBlocked => (
            Icons.error_outline,
            l10n.notificationsBlocked,
            Theme.of(context).colorScheme.error,
          ),
          ReminderScheduleState.failed => (
            Icons.error_outline,
            l10n.reminderStatusFailed,
            Theme.of(context).colorScheme.error,
          ),
          ReminderScheduleState.missing => (
            Icons.error_outline,
            l10n.scheduledCount(value.scheduled, value.expected),
            Theme.of(context).colorScheme.error,
          ),
        };
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                text,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: color),
              ),
            ),
          ],
        );
      },
    );
  }
}

String _formatTime(BuildContext context, Reminder reminder) {
  return TimeOfDay(
    hour: reminder.hour,
    minute: reminder.minute,
  ).format(context);
}

String _formatDays(BuildContext context, int mask) {
  final l10n = context.l10n;
  if (mask == 127) return l10n.everyDay;
  if (mask == 31) return l10n.weekdays;
  final names = [
    l10n.weekdayMon,
    l10n.weekdayTue,
    l10n.weekdayWed,
    l10n.weekdayThu,
    l10n.weekdayFri,
    l10n.weekdaySat,
    l10n.weekdaySun,
  ];
  return [
    for (var index = 0; index < names.length; index++)
      if (mask & (1 << index) != 0) names[index],
  ].join(', ');
}

enum _ReminderAction { edit, delete }
