import 'dart:async';

import 'package:flutter/material.dart';

import 'l10n/app_localizations.dart';

import 'data/measurement_repository.dart';
import 'data/reminder_repository.dart';
import 'data/tonometer_profile_repository.dart';
import 'services/csv_export_service.dart';
import 'services/locale_service.dart';
import 'services/reminder_notification_service.dart';
import 'services/seven_segment_recognizer.dart';
import 'ui/camera_screen.dart';
import 'ui/history_screen.dart';

class TonometerApp extends StatefulWidget {
  const TonometerApp({
    required this.repository,
    required this.reminderRepository,
    required this.notifications,
    required this.recognizer,
    required this.csvExporter,
    this.tonometerProfiles,
    this.localeService,
    this.initialLocale = const Locale('en'),
    super.key,
  });

  final MeasurementRepository repository;
  final ReminderRepository reminderRepository;
  final ReminderNotificationService notifications;
  final SevenSegmentRecognizer recognizer;
  final CsvExportService csvExporter;
  final TonometerProfileRepository? tonometerProfiles;
  final LocaleService? localeService;
  final Locale initialLocale;

  @override
  State<TonometerApp> createState() => _TonometerAppState();
}

class _TonometerAppState extends State<TonometerApp>
    with WidgetsBindingObserver {
  final _navigatorKey = GlobalKey<NavigatorState>();
  late Locale _locale;
  var _cameraOpenOrPending = false;
  var _repairingReminders = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _locale = widget.initialLocale;
    widget.notifications.setLocale(_locale.languageCode);
    widget.notifications.onNotificationTap = _requestOpenCamera;
    if (widget.notifications.takeLaunchedFromReminder()) {
      _requestOpenCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.notifications.onNotificationTap = null;
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_repairReminders());
    }
  }

  Future<void> _repairReminders() async {
    if (_repairingReminders) return;
    _repairingReminders = true;
    try {
      await widget.notifications.synchronize(widget.reminderRepository.getAll);
    } catch (error, stack) {
      debugPrint('Failed to restore reminders: $error\n$stack');
    } finally {
      _repairingReminders = false;
    }
  }

  void _requestOpenCamera() {
    if (_cameraOpenOrPending) return;
    _cameraOpenOrPending = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_openCameraAfterFrame());
    });
  }

  Future<void> _openCameraAfterFrame() async {
    await Future<void>.delayed(Duration.zero);
    if (!mounted) {
      _cameraOpenOrPending = false;
      return;
    }
    final navigator = _navigatorKey.currentState;
    if (navigator == null) {
      _cameraOpenOrPending = false;
      return;
    }
    try {
      await navigator.push<void>(
        MaterialPageRoute(
          builder: (_) => CameraScreen(
            repository: widget.repository,
            recognizer: widget.recognizer,
          ),
        ),
      );
    } finally {
      _cameraOpenOrPending = false;
    }
  }

  Future<void> _changeLocale(Locale locale) async {
    if (_locale == locale) return;
    setState(() => _locale = locale);
    widget.notifications.setLocale(locale.languageCode);
    await widget.localeService?.save(locale);
    await widget.notifications.synchronize(widget.reminderRepository.getAll);
  }

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF075EA8);
    return MaterialApp(
      navigatorKey: _navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Tonometer',
      locale: _locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: seed),
        scaffoldBackgroundColor: const Color(0xFFF7F9FC),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          filled: true,
          fillColor: Colors.white,
        ),
        cardTheme: const CardThemeData(
          margin: EdgeInsets.zero,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
            side: BorderSide(color: Color(0xFFD9E1EA)),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size(64, 56),
            textStyle: const TextStyle(
              inherit: false,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: HistoryScreen(
        repository: widget.repository,
        reminderRepository: widget.reminderRepository,
        notifications: widget.notifications,
        recognizer: widget.recognizer,
        csvExporter: widget.csvExporter,
        tonometerProfiles: widget.tonometerProfiles,
        locale: _locale,
        onLocaleChanged: _changeLocale,
      ),
    );
  }
}
