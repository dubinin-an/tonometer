import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonometer_mvp/app.dart';
import 'package:tonometer_mvp/data/app_database.dart';
import 'package:tonometer_mvp/data/measurement_repository.dart';
import 'package:tonometer_mvp/data/reminder_repository.dart';
import 'package:tonometer_mvp/services/csv_export_service.dart';
import 'package:tonometer_mvp/services/reminder_notification_service.dart';
import 'package:tonometer_mvp/services/seven_segment_recognizer.dart';

void main() {
  testWidgets('empty history visual reference', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final database = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    addTearDown(database.close);

    await tester.pumpWidget(
      RepaintBoundary(
        key: const ValueKey('visual-reference'),
        child: TonometerApp(
          repository: MeasurementRepository(database),
          reminderRepository: ReminderRepository(database),
          notifications: ReminderNotificationService(),
          recognizer: const SevenSegmentRecognizer(),
          csvExporter: const CsvExportService(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(const ValueKey('visual-reference')),
      matchesGoldenFile('goldens/empty_history.png'),
    );
  });
}
