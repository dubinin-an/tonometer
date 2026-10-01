import 'package:flutter/material.dart';

import 'app.dart';
import 'data/app_database.dart';
import 'data/measurement_repository.dart';
import 'data/reminder_repository.dart';
import 'data/tonometer_profile_repository.dart';
import 'services/csv_export_service.dart';
import 'services/locale_service.dart';
import 'services/reminder_notification_service.dart';
import 'services/seven_segment_recognizer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final database = AppDatabase();
  final localeService = LocaleService();
  final locale = await localeService.load() ?? const Locale('en');
  final reminderRepository = ReminderRepository(database);
  final notifications = ReminderNotificationService();
  final tonometerProfiles = TonometerProfileRepository();
  notifications.setLocale(locale.languageCode);
  await notifications.initialize();
  await notifications.rescheduleAll(await reminderRepository.getAll());
  runApp(
    TonometerApp(
      repository: MeasurementRepository(database),
      reminderRepository: reminderRepository,
      notifications: notifications,
      recognizer: SevenSegmentRecognizer(profileRepository: tonometerProfiles),
      tonometerProfiles: tonometerProfiles,
      csvExporter: const CsvExportService(),
      localeService: localeService,
      initialLocale: locale,
    ),
  );
}
