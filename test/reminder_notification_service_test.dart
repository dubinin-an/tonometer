import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:tonometer_mvp/data/app_database.dart';
import 'package:tonometer_mvp/services/reminder_notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('dexterous.com/flutter/local_notifications');
  const timezoneChannel = MethodChannel('flutter_timezone');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late ReminderNotificationService service;
  late List<MethodCall> calls;
  late Map<int, Map<String, dynamic>> pending;
  late bool exactAllowed;
  late bool notificationsAllowed;
  late bool channelBlocked;
  late bool rejectExactSchedule;
  late String timezone;
  int? failId;
  int? failCancelId;
  int? omitId;
  Completer<void>? scheduleGate;

  Reminder reminder({int id = 1, int mask = 127, bool enabled = true}) =>
      Reminder(
        id: id,
        hour: 8,
        minute: 30,
        weekdaysMask: mask,
        enabled: enabled,
        createdAt: DateTime(2026),
      );

  List<MethodCall> schedules() =>
      calls.where((call) => call.method == 'zonedSchedule').toList();

  setUp(() async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    calls = [];
    pending = {};
    exactAllowed = true;
    notificationsAllowed = true;
    channelBlocked = false;
    rejectExactSchedule = false;
    timezone = 'America/Montevideo';
    failId = null;
    failCancelId = null;
    omitId = null;
    scheduleGate = null;
    messenger.setMockMethodCallHandler(timezoneChannel, (_) async => timezone);
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      switch (call.method) {
        case 'initialize':
        case 'openAppNotificationSettings':
          return true;
        case 'getNotificationAppLaunchDetails':
          return null;
        case 'canScheduleExactNotifications':
        case 'requestExactAlarmsPermission':
          return exactAllowed;
        case 'requestNotificationsPermission':
        case 'areNotificationsEnabled':
          return notificationsAllowed;
        case 'getNotificationChannels':
          return channelBlocked
              ? [
                  {
                    'id': 'measurement_reminders',
                    'name': 'Measurement reminders',
                    'importance': 0,
                    'bypassDnd': false,
                    'showBadge': true,
                    'playSound': false,
                    'enableLights': false,
                    'enableVibration': false,
                    'ledColor': 0,
                    'audioAttributesUsage': 5,
                  },
                ]
              : [];
        case 'zonedSchedule':
          final args = Map<String, dynamic>.from(call.arguments as Map);
          final id = args['id'] as int;
          if (rejectExactSchedule &&
              args['platformSpecifics']['scheduleMode'] ==
                  'exactAllowWhileIdle') {
            throw PlatformException(code: 'exact_alarms_not_permitted');
          }
          if (id == failId) throw PlatformException(code: 'schedule_failed');
          await scheduleGate?.future;
          if (id != omitId) pending[id] = args;
          return null;
        case 'pendingNotificationRequests':
          return pending.values
              .map(
                (args) => {
                  'id': args['id'],
                  'title': args['title'],
                  'body': args['body'],
                  'payload': args['payload'],
                },
              )
              .toList();
        case 'cancel':
          final id = (call.arguments as Map)['id'];
          if (id == failCancelId) {
            throw PlatformException(code: 'cancel_failed');
          }
          pending.remove(id);
          return null;
        default:
          throw StateError('Unexpected method ${call.method}');
      }
    });
    service = ReminderNotificationService();
    await service.initialize();
    calls.clear();
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
    messenger.setMockMethodCallHandler(timezoneChannel, null);
    debugDefaultTargetPlatformOverride = null;
    service.revision.dispose();
  });

  test('notification launch flag can only be consumed once', () {
    service.launchedFromReminder = true;
    expect(service.takeLaunchedFromReminder(), isTrue);
    expect(service.takeLaunchedFromReminder(), isFalse);
  });

  test(
    'denying exact access still permits and schedules all weekdays',
    () async {
      exactAllowed = false;
      expect(await service.requestPermission(), isTrue);
      await service.schedule(reminder());
      expect(
        pending.keys,
        unorderedEquals([
          100011,
          100012,
          100013,
          100014,
          100015,
          100016,
          100017,
        ]),
      );
      for (final args in pending.values) {
        expect(
          args['platformSpecifics']['scheduleMode'],
          'inexactAllowWhileIdle',
        );
        expect(
          args['matchDateTimeComponents'],
          DateTimeComponents.dayOfWeekAndTime.index,
        );
      }
      expect(
        (await service.statusFor(reminder())).state,
        ReminderScheduleState.approximate,
      );
    },
  );

  test(
    'exact scheduling uses local future weekday times and preserves IDs',
    () async {
      final now = DateTime.now();
      await service.schedule(reminder(mask: 5)); // Monday and Wednesday.
      expect(pending.keys, unorderedEquals([100011, 100013]));
      for (final entry in pending.entries) {
        final args = entry.value;
        final time = tz.TZDateTime.parse(
          tz.local,
          args['scheduledDateTime'] as String,
        );
        expect(time.isAfter(now), isTrue);
        expect(time.weekday, entry.key % 10);
        expect(time.hour, 8);
        expect(time.minute, 30);
        expect(args['timeZoneName'], 'America/Montevideo');
        expect(
          args['platformSpecifics']['scheduleMode'],
          'exactAllowWhileIdle',
        );
      }
      expect(
        (await service.statusFor(reminder(mask: 5))).state,
        ReminderScheduleState.scheduled,
      );
    },
  );

  test('exact native rejection retries using inexact mode', () async {
    rejectExactSchedule = true;
    await service.schedule(reminder(mask: 1));
    expect(schedules(), hasLength(2));
    expect(
      pending[100011]!['platformSpecifics']['scheduleMode'],
      'inexactAllowWhileIdle',
    );
    expect(
      (await service.statusFor(reminder(mask: 1))).state,
      ReminderScheduleState.approximate,
    );
  });

  test('app permission denial is visible even with cached requests', () async {
    await service.schedule(reminder());
    notificationsAllowed = false;
    expect(await service.requestPermission(), isFalse);
    expect(
      (await service.statusFor(reminder())).state,
      ReminderScheduleState.notificationsBlocked,
    );
    await expectLater(
      service.scheduleTestNotification(),
      throwsA(isA<NotificationPermissionException>()),
    );
  });

  test(
    'blocked reminder channel is detected independently of app permission',
    () async {
      channelBlocked = true;
      expect(await service.requestPermission(), isFalse);
      expect(
        (await service.statusFor(reminder())).state,
        ReminderScheduleState.notificationsBlocked,
      );
    },
  );

  test(
    'native scheduling failure preserves old events and is reported',
    () async {
      await service.schedule(reminder());
      calls.clear();
      failId = 100013;
      await expectLater(
        service.schedule(reminder(mask: 5)),
        throwsA(isA<PlatformException>()),
      );
      expect(pending, hasLength(7));
      expect(calls.where((call) => call.method == 'cancel'), isEmpty);
      expect(
        (await service.statusFor(reminder())).state,
        ReminderScheduleState.failed,
      );
      failId = null;
      await service.schedule(reminder(mask: 5));
      expect(pending.keys, unorderedEquals([100011, 100013]));
      expect(
        (await service.statusFor(reminder(mask: 5))).state,
        ReminderScheduleState.scheduled,
      );
    },
  );

  test(
    'missing persisted request is rejected instead of reporting success',
    () async {
      omitId = 100013;
      await expectLater(
        service.schedule(reminder()),
        throwsA(isA<ReminderScheduleVerificationException>()),
      );
      expect(
        (await service.statusFor(reminder())).state,
        ReminderScheduleState.failed,
      );
    },
  );

  test(
    'resume repair recovers revoked access and refreshes timezone',
    () async {
      await service.schedule(reminder());
      exactAllowed =
          false; // Android cancels exact alarms but retains plugin cache.
      expect(
        (await service.statusFor(reminder())).state,
        ReminderScheduleState.failed,
      );
      timezone = 'Europe/Madrid';
      await service.synchronize(() async => [reminder()]);
      expect(tz.local.name, 'Europe/Madrid');
      expect(
        pending.values.every((args) => args['timeZoneName'] == 'Europe/Madrid'),
        isTrue,
      );
      expect(
        (await service.statusFor(reminder())).state,
        ReminderScheduleState.approximate,
      );
      exactAllowed = true;
      await service.synchronize(() async => [reminder()]);
      expect(
        (await service.statusFor(reminder())).state,
        ReminderScheduleState.scheduled,
      );
    },
  );

  test(
    'one failing reminder does not prevent repair or cancellation of others',
    () async {
      await service.schedule(reminder(id: 3));
      failId = 100011;
      await service.rescheduleAll([
        reminder(),
        reminder(id: 2),
        reminder(id: 3, enabled: false),
      ]);
      expect(
        pending.keys,
        unorderedEquals([
          100021,
          100022,
          100023,
          100024,
          100025,
          100026,
          100027,
        ]),
      );
      expect(
        (await service.statusFor(reminder())).state,
        ReminderScheduleState.failed,
      );
    },
  );

  test('queued cancellation wins over an in-progress repair', () async {
    scheduleGate = Completer<void>();
    final started = Completer<void>();
    final repair = service.synchronize(() async {
      started.complete();
      return [reminder()];
    });
    await started.future;
    final cancel = service.cancel(1);
    scheduleGate!.complete();
    await Future.wait([repair, cancel]);
    expect(pending, isEmpty);
    expect(service.revision.value, 2);
  });

  test(
    'failed cancellation is visible and retried for a disabled reminder',
    () async {
      await service.schedule(reminder());
      failCancelId = 100011;
      await expectLater(service.cancel(1), throwsA(isA<PlatformException>()));
      expect(
        (await service.statusFor(reminder(enabled: false))).state,
        ReminderScheduleState.failed,
      );
      failCancelId = null;
      await service.synchronize(() async => [reminder(enabled: false)]);
      expect(pending, isEmpty);
      expect(
        (await service.statusFor(reminder(enabled: false))).state,
        ReminderScheduleState.disabled,
      );
    },
  );

  test(
    'test notification works without exact permission and is not repeating',
    () async {
      exactAllowed = false;
      final before = DateTime.now();
      final scheduledAt = await service.scheduleTestNotification();
      expect(
        scheduledAt.difference(before).inSeconds,
        inInclusiveRange(59, 61),
      );
      final args = pending[99999]!;
      expect(
        args['platformSpecifics']['scheduleMode'],
        'inexactAllowWhileIdle',
      );
      expect(args.containsKey('matchDateTimeComponents'), isFalse);
      expect(args['payload'], 'open_camera');
    },
  );

  test(
    'notification settings delegates to the supported platform API',
    () async {
      expect(await service.openNotificationSettings(), isTrue);
      expect(calls.last.method, 'openAppNotificationSettings');
    },
  );
}
