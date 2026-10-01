import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../data/app_database.dart';

class ReminderNotificationService {
  ReminderNotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const _payload = 'open_camera';
  static const _channelId = 'measurement_reminders';
  static const _notificationIdBase = 100000;

  final FlutterLocalNotificationsPlugin _plugin;
  String _languageCode = 'en';
  VoidCallback? onNotificationTap;
  bool launchedFromReminder = false;

  // All schedule mutations share one queue: lifecycle repairs must not overlap
  // a save, disable, or delete initiated by the user.
  Future<void> _pendingOperation = Future<void>.value();
  final ValueNotifier<int> revision = ValueNotifier(0);
  final Map<int, AndroidScheduleMode> _scheduleModes = {};
  final Set<int> _failedReminders = {};

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      'Measurement reminders',
      channelDescription: 'Regular blood pressure measurement reminders',
      importance: Importance.high,
      priority: Priority.high,
      category: AndroidNotificationCategory.reminder,
    ),
    iOS: DarwinNotificationDetails(),
  );

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  Future<T> _serialize<T>(Future<T> Function() operation) {
    final result = _pendingOperation.then((_) => operation());
    // A failed operation must not poison the queue for subsequent repairs.
    _pendingOperation = result.then<void>(
      (_) {
        revision.value++;
      },
      onError: (Object error, StackTrace stack) {
        revision.value++;
      },
    );
    return result;
  }

  Future<void> _refreshTimeZone() async {
    final timeZone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZone.identifier));
  }

  bool takeLaunchedFromReminder() {
    final launched = launchedFromReminder;
    launchedFromReminder = false;
    return launched;
  }

  void setLocale(String languageCode) {
    _languageCode = _NotificationTexts.supports(languageCode)
        ? languageCode
        : 'en';
  }

  _NotificationTexts get _texts => _NotificationTexts(_languageCode);

  Future<void> initialize() async {
    tz_data.initializeTimeZones();
    await _refreshTimeZone();

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('notification_icon'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: _handleResponse,
    );
    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    launchedFromReminder =
        (launchDetails?.didNotificationLaunchApp ?? false) &&
        launchDetails?.notificationResponse?.payload == _payload;
  }

  Future<bool> requestPermission() async {
    final android = _android;
    if (android != null) {
      if (!(await android.requestNotificationsPermission() ?? false)) {
        return false;
      }
      if (!await canScheduleExactly()) {
        // Exact timing is preferred, but declining it must not disable reminders.
        await android.requestExactAlarmsPermission();
      }
      return notificationsEnabled();
    }
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    return await ios?.requestPermissions(
          alert: true,
          badge: false,
          sound: true,
        ) ??
        true;
  }

  Future<bool> openNotificationSettings() async =>
      await _plugin.openAppNotificationSettings() ?? false;

  Future<bool> notificationsEnabled() async {
    final android = _android;
    if (android != null) {
      if (!(await android.areNotificationsEnabled() ?? false)) return false;
      final channels = await android.getNotificationChannels() ?? [];
      return !channels.any(
        (channel) =>
            channel.id == _channelId && channel.importance == Importance.none,
      );
    }
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    return (await ios?.checkPermissions())?.isEnabled ?? true;
  }

  Future<tz.TZDateTime> scheduleTestNotification() => _serialize(() async {
    if (!await notificationsEnabled()) {
      throw const NotificationPermissionException();
    }
    await _refreshTimeZone();
    final scheduledAt = tz.TZDateTime.now(tz.local)
        .add(const Duration(minutes: 1));
    const id = _notificationIdBase - 1;
    await _scheduleNotification(
      id: id,
      title: _texts.testTitle,
      body: _texts.testBody,
      scheduledAt: scheduledAt,
    );
    await _verifyScheduled({id});
    return scheduledAt;
  });

  Future<void> schedule(Reminder reminder) =>
      _serialize(() => _schedule(reminder));

  Future<void> _schedule(Reminder reminder) async {
    if (!reminder.enabled) {
      await _cancel(reminder.id);
      return;
    }
    try {
      final expectedIds = <int>{};
      for (
        var weekday = DateTime.monday;
        weekday <= DateTime.sunday;
        weekday++
      ) {
        if (!_includesWeekday(reminder.weekdaysMask, weekday)) continue;
        final id = _notificationId(reminder.id, weekday);
        expectedIds.add(id);
        // Reusing the ID replaces the alarm without first deleting the working
        // schedule (or a notification already visible in the notification tray).
        await _scheduleNotification(
          id: id,
          title: _texts.reminderTitle,
          body: _texts.reminderBody,
          scheduledAt: _nextWeekdayTime(
            weekday,
            reminder.hour,
            reminder.minute,
          ),
          repeat: true,
        );
      }
      await _verifyScheduled(expectedIds);
      // Remove deselected weekdays only after the new schedule is installed.
      for (
        var weekday = DateTime.monday;
        weekday <= DateTime.sunday;
        weekday++
      ) {
        if (_includesWeekday(reminder.weekdaysMask, weekday)) continue;
        final id = _notificationId(reminder.id, weekday);
        await _plugin.cancel(id: id);
        _scheduleModes.remove(id);
      }
      _failedReminders.remove(reminder.id);
    } catch (_) {
      _failedReminders.add(reminder.id);
      rethrow;
    }
  }

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledAt,
    bool repeat = false,
  }) async {
    var mode = await canScheduleExactly()
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
    Future<void> scheduleWithMode() => _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledAt,
      notificationDetails: _details,
      androidScheduleMode: mode,
      matchDateTimeComponents: repeat
          ? DateTimeComponents.dayOfWeekAndTime
          : null,
      payload: _payload,
    );
    try {
      await scheduleWithMode();
    } on PlatformException catch (error) {
      if (error.code != 'exact_alarms_not_permitted' ||
          mode != AndroidScheduleMode.exactAllowWhileIdle) {
        rethrow;
      }
      mode = AndroidScheduleMode.inexactAllowWhileIdle;
      await scheduleWithMode();
    }
    _scheduleModes[id] = mode;
  }

  Future<void> _verifyScheduled(Set<int> expectedIds) async {
    final pendingIds = {
      for (final request in await _plugin.pendingNotificationRequests())
        request.id,
    };
    final scheduledCount = expectedIds.where(pendingIds.contains).length;
    if (scheduledCount != expectedIds.length) {
      throw ReminderScheduleVerificationException(
        expectedIds.length,
        scheduledCount,
      );
    }
  }

  Future<bool> canScheduleExactly() async =>
      await _android?.canScheduleExactNotifications() ?? true;

  Future<ReminderScheduleStatus> statusFor(Reminder reminder) async {
    // Wait for a save/repair to finish so the UI cannot report transient gaps.
    await _pendingOperation;
    if (_failedReminders.contains(reminder.id)) {
      return const ReminderScheduleStatus.failed();
    }
    if (!reminder.enabled) return const ReminderScheduleStatus.disabled();
    if (!await notificationsEnabled()) {
      return const ReminderScheduleStatus.notificationsBlocked();
    }
    final expectedIds = {
      for (var weekday = DateTime.monday; weekday <= DateTime.sunday; weekday++)
        if (_includesWeekday(reminder.weekdaysMask, weekday))
          _notificationId(reminder.id, weekday),
    };
    final pendingIds = {
      for (final request in await _plugin.pendingNotificationRequests())
        request.id,
    };
    final scheduledCount = expectedIds.where(pendingIds.contains).length;
    if (scheduledCount != expectedIds.length || expectedIds.isEmpty) {
      return ReminderScheduleStatus.missing(
        expected: expectedIds.length,
        scheduled: scheduledCount,
      );
    }
    // Android returns the plugin's persisted requests, not AlarmManager state.
    // Exact-alarm revocation can leave that cache populated with canceled alarms.
    final exactAllowed = await canScheduleExactly();
    if (!exactAllowed &&
        expectedIds.any(
          (id) =>
              _scheduleModes[id] != AndroidScheduleMode.inexactAllowWhileIdle,
        )) {
      return const ReminderScheduleStatus.failed();
    }
    final approximate =
        !exactAllowed ||
        expectedIds.any(
          (id) =>
              _scheduleModes[id] == AndroidScheduleMode.inexactAllowWhileIdle,
        );
    return ReminderScheduleStatus.scheduled(
      scheduledCount,
      approximate: approximate,
    );
  }

  Future<void> cancel(int reminderId) => _serialize(() => _cancel(reminderId));

  Future<void> _cancel(int reminderId) async {
    try {
      for (
        var weekday = DateTime.monday;
        weekday <= DateTime.sunday;
        weekday++
      ) {
        final id = _notificationId(reminderId, weekday);
        await _plugin.cancel(id: id);
        _scheduleModes.remove(id);
      }
      _failedReminders.remove(reminderId);
    } catch (_) {
      _failedReminders.add(reminderId);
      rethrow;
    }
  }

  Future<void> rescheduleAll(Iterable<Reminder> reminders) =>
      _serialize(() => _rescheduleAll(reminders));

  Future<void> synchronize(
    Future<Iterable<Reminder>> Function() loadReminders,
  ) => _serialize(() async {
    // Read after earlier mutations finish, rather than queuing stale DB rows.
    await _rescheduleAll(await loadReminders());
  });

  Future<void> _rescheduleAll(Iterable<Reminder> reminders) async {
    await _refreshTimeZone();
    for (final reminder in reminders) {
      try {
        await _schedule(reminder);
      } catch (error, stack) {
        // Keep repairing other reminders; statusFor exposes individual failures.
        debugPrint(
          'Failed to reschedule reminder ${reminder.id}: $error\n$stack',
        );
      }
    }
  }

  void _handleResponse(NotificationResponse response) {
    if (response.payload == _payload) onNotificationTap?.call();
  }

  static bool _includesWeekday(int mask, int weekday) {
    return mask & (1 << (weekday - 1)) != 0;
  }

  static int _notificationId(int reminderId, int weekday) {
    return _notificationIdBase + reminderId * 10 + weekday;
  }

  static tz.TZDateTime _nextWeekdayTime(int weekday, int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var daysAhead = (weekday - now.weekday) % 7;
    var result = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day + daysAhead,
      hour,
      minute,
    );
    if (!result.isAfter(now)) {
      daysAhead += 7;
      result = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day + daysAhead,
        hour,
        minute,
      );
    }
    return result;
  }
}

enum ReminderScheduleState {
  disabled,
  scheduled,
  approximate,
  notificationsBlocked,
  failed,
  missing,
}

class ReminderScheduleStatus {
  const ReminderScheduleStatus._(
    this.state, {
    this.expected = 0,
    this.scheduled = 0,
  });

  const ReminderScheduleStatus.disabled()
    : this._(ReminderScheduleState.disabled);

  const ReminderScheduleStatus.notificationsBlocked()
    : this._(ReminderScheduleState.notificationsBlocked);

  const ReminderScheduleStatus.failed() : this._(ReminderScheduleState.failed);

  const ReminderScheduleStatus.scheduled(int count, {bool approximate = false})
    : this._(
        approximate
            ? ReminderScheduleState.approximate
            : ReminderScheduleState.scheduled,
        expected: count,
        scheduled: count,
      );

  const ReminderScheduleStatus.missing({
    required int expected,
    required int scheduled,
  }) : this._(
         ReminderScheduleState.missing,
         expected: expected,
         scheduled: scheduled,
       );

  final ReminderScheduleState state;
  final int expected;
  final int scheduled;
}

class NotificationPermissionException implements Exception {
  const NotificationPermissionException();

  @override
  String toString() => 'Уведомления приложения или канал напоминаний отключены';
}

class ReminderScheduleVerificationException implements Exception {
  const ReminderScheduleVerificationException(this.expected, this.scheduled);

  final int expected;
  final int scheduled;

  @override
  String toString() => 'Запланировано $scheduled из $expected событий';
}

class _NotificationTexts {
  const _NotificationTexts(this.languageCode);

  final String languageCode;

  static bool supports(String code) => const {'ru', 'en', 'es'}.contains(code);

  String get testTitle => switch (languageCode) {
    'ru' => 'Проверка напоминания',
    'es' => 'Prueba de recordatorio',
    _ => 'Reminder test',
  };

  String get testBody => switch (languageCode) {
    'ru' => 'Напоминание Tonometer сработало.',
    'es' => 'El recordatorio de Tonometer funcionó.',
    _ => 'The Tonometer reminder worked.',
  };

  String get reminderTitle => switch (languageCode) {
    'ru' => 'Пора измерить давление',
    'es' => 'Es hora de medir la presión arterial',
    _ => 'Time to measure your blood pressure',
  };

  String get reminderBody => switch (languageCode) {
    'ru' => 'Откройте приложение и запишите результат.',
    'es' => 'Abre la aplicación y registra el resultado.',
    _ => 'Open the app and record the result.',
  };
}
