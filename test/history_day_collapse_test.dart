import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonometer_mvp/app.dart';
import 'package:tonometer_mvp/data/app_database.dart';
import 'package:tonometer_mvp/data/measurement_repository.dart';
import 'package:tonometer_mvp/data/reminder_repository.dart';
import 'package:tonometer_mvp/domain/measurement_draft.dart';
import 'package:tonometer_mvp/services/csv_export_service.dart';
import 'package:tonometer_mvp/services/reminder_notification_service.dart';
import 'package:tonometer_mvp/services/seven_segment_recognizer.dart';

void main() {
  testWidgets('past days collapse to averages and can be expanded', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final database = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    addTearDown(database.close);
    final repository = MeasurementRepository(database);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day, 9);
    final yesterday = today.subtract(const Duration(days: 1));

    await repository.add(
      MeasurementDraft(
        systolic: 120,
        diastolic: 80,
        pulse: 70,
        measuredAt: yesterday,
      ),
    );
    await repository.add(
      MeasurementDraft(
        systolic: 140,
        diastolic: 90,
        pulse: 80,
        measuredAt: yesterday.add(const Duration(hours: 1)),
      ),
    );
    await repository.add(
      MeasurementDraft(
        systolic: 125,
        diastolic: 82,
        pulse: 72,
        measuredAt: today,
      ),
    );

    await tester.pumpWidget(
      TonometerApp(
        repository: repository,
        reminderRepository: ReminderRepository(database),
        notifications: ReminderNotificationService(),
        recognizer: const SevenSegmentRecognizer(),
        csvExporter: const CsvExportService(),
      ),
    );
    await tester.pumpAndSettle();

    final todayKey = _dayKey(today);
    final yesterdayKey = _dayKey(yesterday);
    expect(find.byKey(ValueKey('day_contents_$todayKey')), findsOneWidget);
    expect(find.byKey(ValueKey('day_contents_$yesterdayKey')), findsNothing);
    expect(find.text('130'), findsOneWidget);
    expect(find.text('85'), findsOneWidget);
    expect(find.text('75'), findsOneWidget);

    await tester.tap(find.byKey(ValueKey('day_toggle_$yesterdayKey')));
    await tester.pumpAndSettle();
    expect(find.byKey(ValueKey('day_contents_$yesterdayKey')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('toggle_all_days')));
    await tester.pumpAndSettle();
    expect(find.byKey(ValueKey('day_contents_$todayKey')), findsOneWidget);
    expect(find.byKey(ValueKey('day_contents_$yesterdayKey')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('toggle_all_days')));
    await tester.pumpAndSettle();
    expect(find.byKey(ValueKey('day_contents_$todayKey')), findsOneWidget);
    expect(find.byKey(ValueKey('day_contents_$yesterdayKey')), findsNothing);
  });
}

String _dayKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';
