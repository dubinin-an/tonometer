import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonometer_mvp/app.dart';
import 'package:tonometer_mvp/data/app_database.dart';
import 'package:tonometer_mvp/data/measurement_repository.dart';
import 'package:tonometer_mvp/data/reminder_repository.dart';
import 'package:tonometer_mvp/domain/reminder_draft.dart';
import 'package:tonometer_mvp/services/csv_export_service.dart';
import 'package:tonometer_mvp/services/reminder_notification_service.dart';
import 'package:tonometer_mvp/services/seven_segment_recognizer.dart';
import 'package:tonometer_mvp/ui/reminder_form_screen.dart';
import 'package:tonometer_mvp/ui/reminders_screen.dart';

import 'test_app_harness.dart';

class _Notifications extends ReminderNotificationService {
  List<Reminder> restored = [];
  int repairs = 0;
  int saves = 0;
  bool failNextSave = false;
  ReminderScheduleStatus status = const ReminderScheduleStatus.scheduled(7);

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> synchronize(
    Future<Iterable<Reminder>> Function() loadReminders,
  ) async {
    restored = (await loadReminders()).toList();
    repairs++;
    revision.value++;
  }

  @override
  Future<void> schedule(Reminder reminder) async {
    saves++;
    if (failNextSave) {
      failNextSave = false;
      throw StateError('Schedule failed');
    }
  }

  @override
  Future<ReminderScheduleStatus> statusFor(Reminder reminder) async => status;
}

void main() {
  late AppDatabase database;
  late ReminderRepository repository;
  late _Notifications notifications;

  setUp(() {
    database = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    repository = ReminderRepository(database);
    notifications = _Notifications();
  });

  tearDown(() async {
    notifications.revision.dispose();
    await database.close();
  });

  const draft = ReminderDraft(
    hour: 8,
    minute: 30,
    weekdaysMask: 127,
    enabled: true,
  );

  testWidgets('returning from settings repairs current saved reminders', (
    tester,
  ) async {
    await tester.pumpWidget(
      TonometerApp(
        repository: MeasurementRepository(database),
        reminderRepository: repository,
        notifications: notifications,
        recognizer: const SevenSegmentRecognizer(),
        csvExporter: const CsvExportService(),
      ),
    );
    await tester.pumpAndSettle();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.runAsync(() => repository.add(draft));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(notifications.repairs, 1);
    expect(notifications.restored.single.hour, 8);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('status refreshes after repair without a database change', (
    tester,
  ) async {
    await tester.runAsync(() => repository.add(draft));
    await tester.pumpWidget(
      localizedTestApp(
        child: RemindersScreen(
          repository: repository,
          notifications: notifications,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Added to schedule'), findsOneWidget);
    notifications.status = const ReminderScheduleStatus.notificationsBlocked();
    notifications.revision.value++;
    await tester.pumpAndSettle();
    expect(
      find.text('Notifications are disabled in phone settings'),
      findsOneWidget,
    );
    expect(find.text('Added to schedule'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'retrying a failed new reminder save does not create duplicates',
    (tester) async {
      notifications.failNextSave = true;
      await tester.pumpWidget(
        localizedTestApp(
          child: ReminderFormScreen(
            repository: repository,
            notifications: notifications,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save reminder'));
      await tester.pumpAndSettle();
      expect(notifications.saves, 1);
      expect((await tester.runAsync(repository.getAll))!, hasLength(1));
      await tester.tap(find.text('Save reminder'));
      await tester.pumpAndSettle();
      expect(notifications.saves, 2);
      expect((await tester.runAsync(repository.getAll))!, hasLength(1));
      await tester.pumpWidget(const SizedBox());
    },
  );
}
