// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Tonometer';

  @override
  String get showTable => 'Show table';

  @override
  String get showChart => 'Show chart';

  @override
  String get appMenu => 'Menu';

  @override
  String get reminders => 'Reminders';

  @override
  String get exportCsv => 'Export CSV';

  @override
  String get language => 'Language';

  @override
  String get russian => 'Русский';

  @override
  String get english => 'English';

  @override
  String get spanish => 'Español';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get doNotDelete => 'Keep';

  @override
  String get saving => 'Saving…';

  @override
  String get optional => 'Optional';

  @override
  String get comment => 'Comment';

  @override
  String get retry => 'Try again';

  @override
  String get time => 'Time';

  @override
  String get average => 'Average';

  @override
  String get pulse => 'Pulse';

  @override
  String get leftArm => 'Left arm';

  @override
  String get rightArm => 'Right arm';

  @override
  String get arm => 'Arm';

  @override
  String get deleteMeasurementTitle => 'Delete measurement?';

  @override
  String deleteMeasurementMessage(int systolic, int diastolic, int pulse) {
    return '$systolic/$diastolic, pulse $pulse. This cannot be undone.';
  }

  @override
  String deleteEntryFailed(String error) {
    return 'Could not delete the entry: $error';
  }

  @override
  String get deleteSeriesTitle => 'Delete the entire series?';

  @override
  String deleteSeriesMessage(int count) {
    return 'All $count measurements in the series will be deleted.';
  }

  @override
  String get nothingToExport => 'There is nothing to export yet';

  @override
  String exportFailed(String error) {
    return 'Could not export: $error';
  }

  @override
  String get historyOpenFailed => 'Could not open history';

  @override
  String get noMeasurements => 'No measurements yet';

  @override
  String get noMeasurementsDetail =>
      'Photograph the blood pressure monitor or enter the values manually.';

  @override
  String get startSeries => 'Start a measurement series';

  @override
  String get photograph => 'Photograph';

  @override
  String get manualEntry => 'Enter a measurement manually';

  @override
  String get seriesActions => 'Series actions';

  @override
  String get deleteSeries => 'Delete series';

  @override
  String get measurementActions => 'Measurement actions';

  @override
  String get collapse => 'Collapse';

  @override
  String get expand => 'Expand';

  @override
  String get collapseAllDays => 'Collapse all days';

  @override
  String get expandAllDays => 'Expand all days';

  @override
  String measurementCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count measurements',
      one: '$count measurement',
    );
    return '$_temp0';
  }

  @override
  String seriesSemantics(
    String time,
    String count,
    int systolic,
    int diastolic,
    int pulse,
    String action,
  ) {
    return 'Series, last measurement at $time. $count. Averages: blood pressure $systolic over $diastolic, pulse $pulse. $action';
  }

  @override
  String measurementSemantics(
    String time,
    int systolic,
    int diastolic,
    int pulse,
    String arm,
  ) {
    return '$time. Blood pressure $systolic over $diastolic, pulse $pulse, $arm.';
  }

  @override
  String get hasComment => 'Has a comment.';

  @override
  String get showComment => 'Show comment';

  @override
  String get hideComment => 'Hide comment';

  @override
  String get integerRequired => 'Enter a whole number';

  @override
  String allowedRange(int minimum, int maximum) {
    return 'Allowed: $minimum–$maximum';
  }

  @override
  String saveFailed(String error) {
    return 'Could not save: $error';
  }

  @override
  String get measurementDate => 'Measurement date';

  @override
  String get measurementTime => 'Measurement time';

  @override
  String get editMeasurement => 'Edit measurement';

  @override
  String get manualInput => 'Manual entry';

  @override
  String get checkValues => 'Check the values';

  @override
  String get recognizedComplete =>
      'Values recognized. Correct them if necessary.';

  @override
  String get recognizedIncomplete =>
      'Some values were not recognized. Check every field.';

  @override
  String get measurementDateTime => 'Measurement date and time';

  @override
  String get saveMeasurement => 'Save measurement';

  @override
  String get saveChanges => 'Save changes';

  @override
  String seriesSaveFailed(String error) {
    return 'Could not save the series: $error';
  }

  @override
  String get measurementSeries => 'Measurement series';

  @override
  String get seriesReady => 'Series ready';

  @override
  String measurementOfThree(int number) {
    return 'Measurement $number of 3';
  }

  @override
  String get makeFirstMeasurement => 'Take the first measurement.';

  @override
  String get reviewAndSaveSeries => 'Check the values and save the series.';

  @override
  String get nextOrFinishSeries =>
      'Take the next measurement or finish after two.';

  @override
  String get seriesComment => 'Series comment';

  @override
  String get nextMeasurement => 'Next measurement';

  @override
  String get finishSeries => 'Finish series';

  @override
  String measurementNumberTime(int number, String time) {
    return 'Measurement $number · $time';
  }

  @override
  String get cameraNotFound => 'No camera found';

  @override
  String torchUnavailable(String error) {
    return 'Flashlight unavailable: $error';
  }

  @override
  String photoRecognitionFailed(String error) {
    return 'Could not recognize the photo: $error';
  }

  @override
  String get photographDevice => 'Photograph the monitor';

  @override
  String get recognizing => 'Recognizing…';

  @override
  String get capture => 'Capture';

  @override
  String get cameraInstruction =>
      'Hold the phone comfortably. The entire monitor must be visible.';

  @override
  String get disableTorch => 'Turn off flashlight';

  @override
  String get enableTorch => 'Turn on flashlight';

  @override
  String get disableLight => 'Turn off light';

  @override
  String get enableLight => 'Turn on light';

  @override
  String cameraUnavailable(String error) {
    return 'Camera unavailable\n$error';
  }

  @override
  String recognitionFailed(String error) {
    return 'Could not recognize the values: $error';
  }

  @override
  String get checkRegions => 'Check the regions';

  @override
  String get regionsInstruction =>
      'The rectangles must precisely cover the SYS, DIA and Pulse digits.';

  @override
  String get blackWhiteMask => 'B/W mask';

  @override
  String get photo => 'Photo';

  @override
  String get blackWhitePreviewSemantics =>
      'Black-and-white recognition mask. SYS regions are yellow, DIA green, and Pulse blue.';

  @override
  String get photoPreviewSemantics =>
      'Rectified display photo. SYS regions are yellow, DIA green, and Pulse blue.';

  @override
  String get recognize => 'Recognize';

  @override
  String get retake => 'Retake';

  @override
  String get zoomOut => 'Zoom out';

  @override
  String get zoomIn => 'Zoom in';

  @override
  String get chartNoMeasurements => 'Chart without measurements.';

  @override
  String chartSemantics(
    String count,
    String period,
    int systolic,
    int diastolic,
    int pulse,
  ) {
    return 'Chart: $count. Average $period: SYS $systolic, DIA $diastolic, Pulse $pulse.';
  }

  @override
  String get lastSevenDays => 'for 7 days';

  @override
  String get availableData => 'from available data';

  @override
  String get chartScrollHint =>
      'Swipe left on the chart to see earlier measurements.';

  @override
  String get permissionInstruction =>
      'Allow Tonometer notifications and the “Measurement reminders” channel in phone settings.';

  @override
  String reminderChangeFailed(String error) {
    return 'Could not change the reminder: $error';
  }

  @override
  String testScheduled(String time) {
    return 'Test added for $time. Without exact alarm access, Android may delay the notification.';
  }

  @override
  String notificationTestFailed(String error) {
    return 'Could not schedule the test: $error';
  }

  @override
  String get deleteReminderTitle => 'Delete reminder?';

  @override
  String deleteReminderMessage(String time) {
    return 'The reminder at $time will no longer appear.';
  }

  @override
  String deleteReminderFailed(String error) {
    return 'Could not delete the reminder: $error';
  }

  @override
  String remindersOpenFailed(String error) {
    return 'Could not open reminders: $error';
  }

  @override
  String get noReminders => 'No reminders yet';

  @override
  String get noRemindersDetail =>
      'Add a convenient time for regular blood pressure measurements.';

  @override
  String get reminderActions => 'Reminder actions';

  @override
  String get addReminder => 'Add reminder';

  @override
  String get testInOneMinute => 'Test in 1 minute';

  @override
  String get disabled => 'Disabled';

  @override
  String get exactlyScheduled => 'Added to schedule';

  @override
  String get exactPermissionRequired => 'Exact timing permission required';

  @override
  String scheduledCount(int scheduled, int expected) {
    return 'Scheduled $scheduled of $expected';
  }

  @override
  String get everyDay => 'Every day';

  @override
  String get weekdays => 'Weekdays';

  @override
  String get weekdayMon => 'Mon';

  @override
  String get weekdayTue => 'Tue';

  @override
  String get weekdayWed => 'Wed';

  @override
  String get weekdayThu => 'Thu';

  @override
  String get weekdayFri => 'Fri';

  @override
  String get weekdaySat => 'Sat';

  @override
  String get weekdaySun => 'Sun';

  @override
  String get reminderTime => 'Reminder time';

  @override
  String get selectWeekday => 'Select at least one day of the week';

  @override
  String reminderSaveFailed(String error) {
    return 'Could not save the reminder: $error';
  }

  @override
  String get newReminder => 'New reminder';

  @override
  String get editReminder => 'Edit reminder';

  @override
  String get repeat => 'Repeat';

  @override
  String get reminderEnabled => 'Reminder enabled';

  @override
  String get reminderEnabledDetail =>
      'Reminders work while the app is closed. For exact timing, allow “Alarms & reminders” in phone settings.';

  @override
  String get saveReminder => 'Save reminder';

  @override
  String get csvShareTitle => 'Export Tonometer measurements';

  @override
  String get csvSubject => 'Blood pressure measurements';

  @override
  String get displayedData => 'Displayed data';

  @override
  String get filterAll => 'All measurements';

  @override
  String get filterRecent => 'Recent period';

  @override
  String get filterSinceDate => 'From a specific date';

  @override
  String get periodLength => 'Period length';

  @override
  String get decreasePeriod => 'Decrease period';

  @override
  String get increasePeriod => 'Increase period';

  @override
  String get weeks => 'Weeks';

  @override
  String get months => 'Months';

  @override
  String get applyFilter => 'Apply filter';

  @override
  String get filterData => 'Filter data';

  @override
  String get changeActiveFilter => 'Change active filter';

  @override
  String get sortOldestFirst => 'Show oldest first';

  @override
  String get sortNewestFirst => 'Show newest first';

  @override
  String get noMeasurementsForFilter =>
      'No measurements in the selected period';

  @override
  String get resetFilter => 'Show all';

  @override
  String get convertToSeries => 'Convert to series';

  @override
  String get addMeasurement => 'Add measurement';

  @override
  String get seriesHasMaximum => 'The series already has three measurements';

  @override
  String get tonometers => 'Tonometers';

  @override
  String get addTonometer => 'Add tonometer';

  @override
  String get editTonometer => 'Edit tonometer';

  @override
  String get builtInProfile => 'Built-in profile';

  @override
  String get activeTonometer => 'Active tonometer';

  @override
  String get profileActions => 'Profile actions';

  @override
  String get editTonometerIntro =>
      'Update the profile name, LCD corners, reading regions or reference values.';

  @override
  String profileOpenFailed(Object error) {
    return 'Profile could not be opened: $error';
  }

  @override
  String get deleteTonometerTitle => 'Delete tonometer profile?';

  @override
  String deleteTonometerMessage(Object name) {
    return 'The profile “$name” and its reference photo will be deleted. Measurements will remain in history.';
  }

  @override
  String profileDeleteFailed(Object error) {
    return 'Profile could not be deleted: $error';
  }

  @override
  String get newTonometerIntro =>
      'Create a profile from a clear photo with all three readings visible. The current Microlife profile will remain available.';

  @override
  String get tonometerName => 'Profile name';

  @override
  String get manufacturerOptional => 'Manufacturer (optional)';

  @override
  String get modelOptional => 'Model (optional)';

  @override
  String get enterTonometerName => 'Enter a name for the tonometer';

  @override
  String get takeReferencePhoto => 'Take reference photo';

  @override
  String get retakeReferencePhoto => 'Retake reference photo';

  @override
  String lcdDetectionFailed(Object error) {
    return 'LCD detection failed: $error';
  }

  @override
  String lcdRectificationFailed(Object error) {
    return 'LCD alignment failed: $error';
  }

  @override
  String get checkDetectedLcd => 'Set the LCD corners';

  @override
  String get adjustLcdCorners =>
      'Move the four blue points exactly onto the inner corners of the display. Select a point and use the arrows for precise movement.';

  @override
  String get cropAndAlignLcd => 'Crop and align LCD';

  @override
  String get changeLcdCorners => 'Change LCD corners';

  @override
  String get markReadingsOnPreparedLcd => 'Mark readings on the prepared LCD';

  @override
  String get selectedCorner => 'Selected LCD corner';

  @override
  String get topLeftCorner => 'Top-left';

  @override
  String get bottomRightCorner => 'Bottom-right';

  @override
  String get preciseMovement => 'Precise point movement';

  @override
  String get moveUp => 'Move up';

  @override
  String get moveDown => 'Move down';

  @override
  String get moveLeft => 'Move left';

  @override
  String get moveRight => 'Move right';

  @override
  String get adjustMeasurementRegions =>
      'Drag each colored rectangle onto its reading. Drag its round corner to resize it.';

  @override
  String get referenceReadings => 'Values shown in this photo';

  @override
  String get enterReferenceValues =>
      'Enter SYS, DIA and Pulse from the reference photo';

  @override
  String get saveAndTestProfile => 'Save and test profile';

  @override
  String profileSaveFailed(Object error) {
    return 'Profile could not be saved: $error';
  }

  @override
  String get testNewTonometer => 'Test the new tonometer';

  @override
  String get testPhotoRequest =>
      'Take at least three photos from slightly different angles and check every recognition result.';

  @override
  String takeTestPhoto(Object number) {
    return 'Take test photo $number';
  }

  @override
  String testRecognitionFailed(Object error) {
    return 'Test recognition failed: $error';
  }

  @override
  String get recognitionComplete => 'All three values were recognized';

  @override
  String get recognitionNeedsAdjustment =>
      'Some values were not recognized; the profile needs adjustment';

  @override
  String get adjustProfile => 'Adjust profile';

  @override
  String get finishSetup => 'Finish setup';

  @override
  String get editReadingRegions => 'Edit reading regions';

  @override
  String get continueToReferenceValues => 'Continue';

  @override
  String get restoreCsv => 'Restore measurements from CSV';

  @override
  String get restoreMeasurementsTitle => 'Replace measurement history?';

  @override
  String restoreMeasurementsMessage(Object count, Object seriesCount) {
    return 'The file contains $count measurements in $seriesCount series. All current measurements and series will be replaced.';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get restore => 'Restore';

  @override
  String restoreMeasurementsComplete(Object count) {
    return 'Restored $count measurements';
  }

  @override
  String restoreMeasurementsFailed(Object error) {
    return 'Could not restore measurements: $error';
  }

  @override
  String get profileBackupActions => 'Profile backup';

  @override
  String get backupProfiles => 'Back up profiles';

  @override
  String get restoreProfiles => 'Restore profiles';

  @override
  String get noCustomProfilesToBackup =>
      'There are no custom profiles to back up';

  @override
  String get profilesBackupSubject => 'Tonometer profile backup';

  @override
  String profilesBackupFailed(Object error) {
    return 'Could not back up profiles: $error';
  }

  @override
  String get restoreProfilesTitle => 'Restore tonometer profiles?';

  @override
  String restoreProfilesMessage(Object count) {
    return 'The backup contains $count custom profiles. Profiles with the same IDs will be replaced; other profiles and the built-in profile will remain.';
  }

  @override
  String profilesRestored(Object count) {
    return 'Restored $count profiles';
  }

  @override
  String profilesRestoreFailed(Object error) {
    return 'Could not restore profiles: $error';
  }

  @override
  String get approximatelyScheduled =>
      'Scheduled; delivery may be delayed without exact alarm access';

  @override
  String get notificationsBlocked =>
      'Notifications are disabled in phone settings';

  @override
  String get reminderStatusFailed =>
      'Could not confirm the schedule. Open the reminder and save it again.';

  @override
  String get notificationSettings => 'Notification settings';

  @override
  String get privacy => 'Privacy';

  @override
  String get privacySummary =>
      'Tonometer works locally on your device. It does not create an account, show ads or send measurement data to the developer.';

  @override
  String get privacyLocalDataTitle => 'Measurements and profiles';

  @override
  String get privacyLocalDataText =>
      'Measurements, comments, reminder settings and tonometer profiles are stored only on this device until you delete them or remove the app.';

  @override
  String get privacyCameraTitle => 'Camera and photos';

  @override
  String get privacyCameraText =>
      'Camera access is used to read the monitor display. Photos are processed on the device and are not uploaded to a server.';

  @override
  String get privacyRemindersTitle => 'Notifications and reminders';

  @override
  String get privacyRemindersText =>
      'Notification and alarm permissions are used only for measurement reminders that you configure.';

  @override
  String get privacyExportTitle => 'Export and backup';

  @override
  String get privacyExportText =>
      'Data leaves the app only when you explicitly export or share a backup. You choose the receiving app or storage location.';

  @override
  String get medicalDisclaimer =>
      'This app is a personal journal and recognition aid, not a medical device. Check recognized values and consult a qualified healthcare professional about medical decisions.';
}
