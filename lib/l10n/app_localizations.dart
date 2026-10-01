import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('ru'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In ru, this message translates to:
  /// **'Tonometer'**
  String get appTitle;

  /// No description provided for @showTable.
  ///
  /// In ru, this message translates to:
  /// **'Показать таблицу'**
  String get showTable;

  /// No description provided for @showChart.
  ///
  /// In ru, this message translates to:
  /// **'Показать график'**
  String get showChart;

  /// No description provided for @appMenu.
  ///
  /// In ru, this message translates to:
  /// **'Меню'**
  String get appMenu;

  /// No description provided for @reminders.
  ///
  /// In ru, this message translates to:
  /// **'Напоминания'**
  String get reminders;

  /// No description provided for @exportCsv.
  ///
  /// In ru, this message translates to:
  /// **'Экспортировать CSV'**
  String get exportCsv;

  /// No description provided for @language.
  ///
  /// In ru, this message translates to:
  /// **'Язык'**
  String get language;

  /// No description provided for @russian.
  ///
  /// In ru, this message translates to:
  /// **'Русский'**
  String get russian;

  /// No description provided for @english.
  ///
  /// In ru, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @spanish.
  ///
  /// In ru, this message translates to:
  /// **'Español'**
  String get spanish;

  /// No description provided for @edit.
  ///
  /// In ru, this message translates to:
  /// **'Изменить'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In ru, this message translates to:
  /// **'Удалить'**
  String get delete;

  /// No description provided for @doNotDelete.
  ///
  /// In ru, this message translates to:
  /// **'Не удалять'**
  String get doNotDelete;

  /// No description provided for @saving.
  ///
  /// In ru, this message translates to:
  /// **'Сохраняем…'**
  String get saving;

  /// No description provided for @optional.
  ///
  /// In ru, this message translates to:
  /// **'Необязательно'**
  String get optional;

  /// No description provided for @comment.
  ///
  /// In ru, this message translates to:
  /// **'Комментарий'**
  String get comment;

  /// No description provided for @retry.
  ///
  /// In ru, this message translates to:
  /// **'Повторить'**
  String get retry;

  /// No description provided for @time.
  ///
  /// In ru, this message translates to:
  /// **'Время'**
  String get time;

  /// No description provided for @average.
  ///
  /// In ru, this message translates to:
  /// **'Среднее'**
  String get average;

  /// No description provided for @pulse.
  ///
  /// In ru, this message translates to:
  /// **'Pulse'**
  String get pulse;

  /// No description provided for @leftArm.
  ///
  /// In ru, this message translates to:
  /// **'Левая рука'**
  String get leftArm;

  /// No description provided for @rightArm.
  ///
  /// In ru, this message translates to:
  /// **'Правая рука'**
  String get rightArm;

  /// No description provided for @arm.
  ///
  /// In ru, this message translates to:
  /// **'Рука'**
  String get arm;

  /// No description provided for @deleteMeasurementTitle.
  ///
  /// In ru, this message translates to:
  /// **'Удалить измерение?'**
  String get deleteMeasurementTitle;

  /// No description provided for @deleteMeasurementMessage.
  ///
  /// In ru, this message translates to:
  /// **'{systolic}/{diastolic}, пульс {pulse}. Отменить удаление будет нельзя.'**
  String deleteMeasurementMessage(int systolic, int diastolic, int pulse);

  /// No description provided for @deleteEntryFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось удалить запись: {error}'**
  String deleteEntryFailed(String error);

  /// No description provided for @deleteSeriesTitle.
  ///
  /// In ru, this message translates to:
  /// **'Удалить всю серию?'**
  String get deleteSeriesTitle;

  /// No description provided for @deleteSeriesMessage.
  ///
  /// In ru, this message translates to:
  /// **'Будут удалены все измерения серии: {count}.'**
  String deleteSeriesMessage(int count);

  /// No description provided for @nothingToExport.
  ///
  /// In ru, this message translates to:
  /// **'Пока нечего экспортировать'**
  String get nothingToExport;

  /// No description provided for @exportFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось экспортировать: {error}'**
  String exportFailed(String error);

  /// No description provided for @historyOpenFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось открыть историю'**
  String get historyOpenFailed;

  /// No description provided for @noMeasurements.
  ///
  /// In ru, this message translates to:
  /// **'Измерений пока нет'**
  String get noMeasurements;

  /// No description provided for @noMeasurementsDetail.
  ///
  /// In ru, this message translates to:
  /// **'Сфотографируйте экран тонометра или введите значения вручную.'**
  String get noMeasurementsDetail;

  /// No description provided for @startSeries.
  ///
  /// In ru, this message translates to:
  /// **'Начать серию измерений'**
  String get startSeries;

  /// No description provided for @photograph.
  ///
  /// In ru, this message translates to:
  /// **'Сфотографировать'**
  String get photograph;

  /// No description provided for @manualEntry.
  ///
  /// In ru, this message translates to:
  /// **'Ввести измерение вручную'**
  String get manualEntry;

  /// No description provided for @seriesActions.
  ///
  /// In ru, this message translates to:
  /// **'Действия с серией'**
  String get seriesActions;

  /// No description provided for @deleteSeries.
  ///
  /// In ru, this message translates to:
  /// **'Удалить серию'**
  String get deleteSeries;

  /// No description provided for @measurementActions.
  ///
  /// In ru, this message translates to:
  /// **'Действия с измерением'**
  String get measurementActions;

  /// No description provided for @collapse.
  ///
  /// In ru, this message translates to:
  /// **'Свернуть'**
  String get collapse;

  /// No description provided for @expand.
  ///
  /// In ru, this message translates to:
  /// **'Раскрыть'**
  String get expand;

  /// No description provided for @collapseAllDays.
  ///
  /// In ru, this message translates to:
  /// **'Свернуть все дни'**
  String get collapseAllDays;

  /// No description provided for @expandAllDays.
  ///
  /// In ru, this message translates to:
  /// **'Развернуть все дни'**
  String get expandAllDays;

  /// No description provided for @measurementCount.
  ///
  /// In ru, this message translates to:
  /// **'{count, plural, =1{{count} измерение} few{{count} измерения} other{{count} измерений}}'**
  String measurementCount(int count);

  /// No description provided for @seriesSemantics.
  ///
  /// In ru, this message translates to:
  /// **'Серия, последнее измерение в {time}. {count}. Средние значения: давление {systolic} на {diastolic}, пульс {pulse}. {action}'**
  String seriesSemantics(
    String time,
    String count,
    int systolic,
    int diastolic,
    int pulse,
    String action,
  );

  /// No description provided for @measurementSemantics.
  ///
  /// In ru, this message translates to:
  /// **'{time}. Давление {systolic} на {diastolic}, пульс {pulse}, рука {arm}.'**
  String measurementSemantics(
    String time,
    int systolic,
    int diastolic,
    int pulse,
    String arm,
  );

  /// No description provided for @hasComment.
  ///
  /// In ru, this message translates to:
  /// **'Есть комментарий.'**
  String get hasComment;

  /// No description provided for @showComment.
  ///
  /// In ru, this message translates to:
  /// **'Показать комментарий'**
  String get showComment;

  /// No description provided for @hideComment.
  ///
  /// In ru, this message translates to:
  /// **'Скрыть комментарий'**
  String get hideComment;

  /// No description provided for @integerRequired.
  ///
  /// In ru, this message translates to:
  /// **'Введите целое число'**
  String get integerRequired;

  /// No description provided for @allowedRange.
  ///
  /// In ru, this message translates to:
  /// **'Допустимо: {minimum}–{maximum}'**
  String allowedRange(int minimum, int maximum);

  /// No description provided for @saveFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось сохранить: {error}'**
  String saveFailed(String error);

  /// No description provided for @measurementDate.
  ///
  /// In ru, this message translates to:
  /// **'Дата измерения'**
  String get measurementDate;

  /// No description provided for @measurementTime.
  ///
  /// In ru, this message translates to:
  /// **'Время измерения'**
  String get measurementTime;

  /// No description provided for @editMeasurement.
  ///
  /// In ru, this message translates to:
  /// **'Изменить измерение'**
  String get editMeasurement;

  /// No description provided for @manualInput.
  ///
  /// In ru, this message translates to:
  /// **'Ручной ввод'**
  String get manualInput;

  /// No description provided for @checkValues.
  ///
  /// In ru, this message translates to:
  /// **'Проверьте значения'**
  String get checkValues;

  /// No description provided for @recognizedComplete.
  ///
  /// In ru, this message translates to:
  /// **'Значения распознаны. Исправьте их при необходимости.'**
  String get recognizedComplete;

  /// No description provided for @recognizedIncomplete.
  ///
  /// In ru, this message translates to:
  /// **'Не все значения распознаны. Проверьте каждое поле.'**
  String get recognizedIncomplete;

  /// No description provided for @measurementDateTime.
  ///
  /// In ru, this message translates to:
  /// **'Дата и время измерения'**
  String get measurementDateTime;

  /// No description provided for @saveMeasurement.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить измерение'**
  String get saveMeasurement;

  /// No description provided for @saveChanges.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить изменения'**
  String get saveChanges;

  /// No description provided for @seriesSaveFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось сохранить серию: {error}'**
  String seriesSaveFailed(String error);

  /// No description provided for @measurementSeries.
  ///
  /// In ru, this message translates to:
  /// **'Серия измерений'**
  String get measurementSeries;

  /// No description provided for @seriesReady.
  ///
  /// In ru, this message translates to:
  /// **'Серия готова'**
  String get seriesReady;

  /// No description provided for @measurementOfThree.
  ///
  /// In ru, this message translates to:
  /// **'Измерение {number} из 3'**
  String measurementOfThree(int number);

  /// No description provided for @makeFirstMeasurement.
  ///
  /// In ru, this message translates to:
  /// **'Сделайте первое измерение.'**
  String get makeFirstMeasurement;

  /// No description provided for @reviewAndSaveSeries.
  ///
  /// In ru, this message translates to:
  /// **'Проверьте значения и сохраните серию.'**
  String get reviewAndSaveSeries;

  /// No description provided for @nextOrFinishSeries.
  ///
  /// In ru, this message translates to:
  /// **'Можно сделать следующее измерение или завершить после двух.'**
  String get nextOrFinishSeries;

  /// No description provided for @seriesComment.
  ///
  /// In ru, this message translates to:
  /// **'Комментарий к серии'**
  String get seriesComment;

  /// No description provided for @nextMeasurement.
  ///
  /// In ru, this message translates to:
  /// **'Следующее измерение'**
  String get nextMeasurement;

  /// No description provided for @finishSeries.
  ///
  /// In ru, this message translates to:
  /// **'Завершить серию'**
  String get finishSeries;

  /// No description provided for @measurementNumberTime.
  ///
  /// In ru, this message translates to:
  /// **'Измерение {number} · {time}'**
  String measurementNumberTime(int number, String time);

  /// No description provided for @cameraNotFound.
  ///
  /// In ru, this message translates to:
  /// **'Камера не найдена'**
  String get cameraNotFound;

  /// No description provided for @torchUnavailable.
  ///
  /// In ru, this message translates to:
  /// **'Подсветка недоступна: {error}'**
  String torchUnavailable(String error);

  /// No description provided for @photoRecognitionFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось распознать фото: {error}'**
  String photoRecognitionFailed(String error);

  /// No description provided for @photographDevice.
  ///
  /// In ru, this message translates to:
  /// **'Сфотографируйте прибор'**
  String get photographDevice;

  /// No description provided for @recognizing.
  ///
  /// In ru, this message translates to:
  /// **'Распознаём…'**
  String get recognizing;

  /// No description provided for @capture.
  ///
  /// In ru, this message translates to:
  /// **'Снять'**
  String get capture;

  /// No description provided for @cameraInstruction.
  ///
  /// In ru, this message translates to:
  /// **'Держите телефон как удобно. Весь прибор должен быть виден.'**
  String get cameraInstruction;

  /// No description provided for @disableTorch.
  ///
  /// In ru, this message translates to:
  /// **'Выключить подсветку'**
  String get disableTorch;

  /// No description provided for @enableTorch.
  ///
  /// In ru, this message translates to:
  /// **'Включить подсветку'**
  String get enableTorch;

  /// No description provided for @disableLight.
  ///
  /// In ru, this message translates to:
  /// **'Выключить свет'**
  String get disableLight;

  /// No description provided for @enableLight.
  ///
  /// In ru, this message translates to:
  /// **'Включить свет'**
  String get enableLight;

  /// No description provided for @cameraUnavailable.
  ///
  /// In ru, this message translates to:
  /// **'Камера недоступна\n{error}'**
  String cameraUnavailable(String error);

  /// No description provided for @recognitionFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось распознать значения: {error}'**
  String recognitionFailed(String error);

  /// No description provided for @checkRegions.
  ///
  /// In ru, this message translates to:
  /// **'Проверьте области'**
  String get checkRegions;

  /// No description provided for @regionsInstruction.
  ///
  /// In ru, this message translates to:
  /// **'Прямоугольники должны точно закрывать цифры SYS, DIA и Pulse.'**
  String get regionsInstruction;

  /// No description provided for @blackWhiteMask.
  ///
  /// In ru, this message translates to:
  /// **'Ч/б маска'**
  String get blackWhiteMask;

  /// No description provided for @photo.
  ///
  /// In ru, this message translates to:
  /// **'Фото'**
  String get photo;

  /// No description provided for @blackWhitePreviewSemantics.
  ///
  /// In ru, this message translates to:
  /// **'Чёрно-белая маска для распознавания. Жёлтые области SYS, зелёные DIA, голубые Pulse.'**
  String get blackWhitePreviewSemantics;

  /// No description provided for @photoPreviewSemantics.
  ///
  /// In ru, this message translates to:
  /// **'Выпрямленная фотография дисплея. Жёлтые области SYS, зелёные DIA, голубые Pulse.'**
  String get photoPreviewSemantics;

  /// No description provided for @recognize.
  ///
  /// In ru, this message translates to:
  /// **'Распознать'**
  String get recognize;

  /// No description provided for @retake.
  ///
  /// In ru, this message translates to:
  /// **'Снять заново'**
  String get retake;

  /// No description provided for @zoomOut.
  ///
  /// In ru, this message translates to:
  /// **'Уменьшить масштаб'**
  String get zoomOut;

  /// No description provided for @zoomIn.
  ///
  /// In ru, this message translates to:
  /// **'Увеличить масштаб'**
  String get zoomIn;

  /// No description provided for @chartNoMeasurements.
  ///
  /// In ru, this message translates to:
  /// **'График без измерений.'**
  String get chartNoMeasurements;

  /// No description provided for @chartSemantics.
  ///
  /// In ru, this message translates to:
  /// **'График: {count}. Среднее {period}: SYS {systolic}, DIA {diastolic}, Pulse {pulse}.'**
  String chartSemantics(
    String count,
    String period,
    int systolic,
    int diastolic,
    int pulse,
  );

  /// No description provided for @lastSevenDays.
  ///
  /// In ru, this message translates to:
  /// **'за 7 дней'**
  String get lastSevenDays;

  /// No description provided for @availableData.
  ///
  /// In ru, this message translates to:
  /// **'по имеющимся данным'**
  String get availableData;

  /// No description provided for @chartScrollHint.
  ///
  /// In ru, this message translates to:
  /// **'Проведите по графику влево, чтобы увидеть более ранние измерения.'**
  String get chartScrollHint;

  /// No description provided for @permissionInstruction.
  ///
  /// In ru, this message translates to:
  /// **'Разрешите уведомления Tonometer и канал «Measurement reminders» в настройках телефона.'**
  String get permissionInstruction;

  /// No description provided for @reminderChangeFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось изменить напоминание: {error}'**
  String reminderChangeFailed(String error);

  /// No description provided for @testScheduled.
  ///
  /// In ru, this message translates to:
  /// **'Проверка добавлена на {time}. Без разрешения на точное время Android может задержать уведомление.'**
  String testScheduled(String time);

  /// No description provided for @notificationTestFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось запланировать проверку: {error}'**
  String notificationTestFailed(String error);

  /// No description provided for @deleteReminderTitle.
  ///
  /// In ru, this message translates to:
  /// **'Удалить напоминание?'**
  String get deleteReminderTitle;

  /// No description provided for @deleteReminderMessage.
  ///
  /// In ru, this message translates to:
  /// **'Напоминание в {time} больше не будет появляться.'**
  String deleteReminderMessage(String time);

  /// No description provided for @deleteReminderFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось удалить напоминание: {error}'**
  String deleteReminderFailed(String error);

  /// No description provided for @remindersOpenFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось открыть напоминания: {error}'**
  String remindersOpenFailed(String error);

  /// No description provided for @noReminders.
  ///
  /// In ru, this message translates to:
  /// **'Напоминаний пока нет'**
  String get noReminders;

  /// No description provided for @noRemindersDetail.
  ///
  /// In ru, this message translates to:
  /// **'Добавьте удобное время для регулярного измерения давления.'**
  String get noRemindersDetail;

  /// No description provided for @reminderActions.
  ///
  /// In ru, this message translates to:
  /// **'Действия с напоминанием'**
  String get reminderActions;

  /// No description provided for @addReminder.
  ///
  /// In ru, this message translates to:
  /// **'Добавить напоминание'**
  String get addReminder;

  /// No description provided for @testInOneMinute.
  ///
  /// In ru, this message translates to:
  /// **'Проверить через 1 минуту'**
  String get testInOneMinute;

  /// No description provided for @disabled.
  ///
  /// In ru, this message translates to:
  /// **'Отключено'**
  String get disabled;

  /// No description provided for @exactlyScheduled.
  ///
  /// In ru, this message translates to:
  /// **'Добавлено в расписание'**
  String get exactlyScheduled;

  /// No description provided for @exactPermissionRequired.
  ///
  /// In ru, this message translates to:
  /// **'Нужно разрешение на точное время'**
  String get exactPermissionRequired;

  /// No description provided for @scheduledCount.
  ///
  /// In ru, this message translates to:
  /// **'Запланировано {scheduled} из {expected}'**
  String scheduledCount(int scheduled, int expected);

  /// No description provided for @everyDay.
  ///
  /// In ru, this message translates to:
  /// **'Каждый день'**
  String get everyDay;

  /// No description provided for @weekdays.
  ///
  /// In ru, this message translates to:
  /// **'По будням'**
  String get weekdays;

  /// No description provided for @weekdayMon.
  ///
  /// In ru, this message translates to:
  /// **'Пн'**
  String get weekdayMon;

  /// No description provided for @weekdayTue.
  ///
  /// In ru, this message translates to:
  /// **'Вт'**
  String get weekdayTue;

  /// No description provided for @weekdayWed.
  ///
  /// In ru, this message translates to:
  /// **'Ср'**
  String get weekdayWed;

  /// No description provided for @weekdayThu.
  ///
  /// In ru, this message translates to:
  /// **'Чт'**
  String get weekdayThu;

  /// No description provided for @weekdayFri.
  ///
  /// In ru, this message translates to:
  /// **'Пт'**
  String get weekdayFri;

  /// No description provided for @weekdaySat.
  ///
  /// In ru, this message translates to:
  /// **'Сб'**
  String get weekdaySat;

  /// No description provided for @weekdaySun.
  ///
  /// In ru, this message translates to:
  /// **'Вс'**
  String get weekdaySun;

  /// No description provided for @reminderTime.
  ///
  /// In ru, this message translates to:
  /// **'Время напоминания'**
  String get reminderTime;

  /// No description provided for @selectWeekday.
  ///
  /// In ru, this message translates to:
  /// **'Выберите хотя бы один день недели'**
  String get selectWeekday;

  /// No description provided for @reminderSaveFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось сохранить напоминание: {error}'**
  String reminderSaveFailed(String error);

  /// No description provided for @newReminder.
  ///
  /// In ru, this message translates to:
  /// **'Новое напоминание'**
  String get newReminder;

  /// No description provided for @editReminder.
  ///
  /// In ru, this message translates to:
  /// **'Изменить напоминание'**
  String get editReminder;

  /// No description provided for @repeat.
  ///
  /// In ru, this message translates to:
  /// **'Повторять'**
  String get repeat;

  /// No description provided for @reminderEnabled.
  ///
  /// In ru, this message translates to:
  /// **'Напоминание включено'**
  String get reminderEnabled;

  /// No description provided for @reminderEnabledDetail.
  ///
  /// In ru, this message translates to:
  /// **'Напоминание работает при закрытом приложении. Для точного времени разрешите «Будильники и напоминания» в настройках телефона.'**
  String get reminderEnabledDetail;

  /// No description provided for @saveReminder.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить напоминание'**
  String get saveReminder;

  /// No description provided for @csvShareTitle.
  ///
  /// In ru, this message translates to:
  /// **'Экспорт измерений Tonometer'**
  String get csvShareTitle;

  /// No description provided for @csvSubject.
  ///
  /// In ru, this message translates to:
  /// **'Измерения артериального давления'**
  String get csvSubject;

  /// No description provided for @displayedData.
  ///
  /// In ru, this message translates to:
  /// **'Отображаемые данные'**
  String get displayedData;

  /// No description provided for @filterAll.
  ///
  /// In ru, this message translates to:
  /// **'Все измерения'**
  String get filterAll;

  /// No description provided for @filterRecent.
  ///
  /// In ru, this message translates to:
  /// **'За последний период'**
  String get filterRecent;

  /// No description provided for @filterSinceDate.
  ///
  /// In ru, this message translates to:
  /// **'С конкретной даты'**
  String get filterSinceDate;

  /// No description provided for @periodLength.
  ///
  /// In ru, this message translates to:
  /// **'Длительность периода'**
  String get periodLength;

  /// No description provided for @decreasePeriod.
  ///
  /// In ru, this message translates to:
  /// **'Уменьшить период'**
  String get decreasePeriod;

  /// No description provided for @increasePeriod.
  ///
  /// In ru, this message translates to:
  /// **'Увеличить период'**
  String get increasePeriod;

  /// No description provided for @weeks.
  ///
  /// In ru, this message translates to:
  /// **'Недели'**
  String get weeks;

  /// No description provided for @months.
  ///
  /// In ru, this message translates to:
  /// **'Месяцы'**
  String get months;

  /// No description provided for @applyFilter.
  ///
  /// In ru, this message translates to:
  /// **'Применить фильтр'**
  String get applyFilter;

  /// No description provided for @filterData.
  ///
  /// In ru, this message translates to:
  /// **'Фильтровать данные'**
  String get filterData;

  /// No description provided for @changeActiveFilter.
  ///
  /// In ru, this message translates to:
  /// **'Изменить активный фильтр'**
  String get changeActiveFilter;

  /// No description provided for @sortOldestFirst.
  ///
  /// In ru, this message translates to:
  /// **'Показать сначала старые'**
  String get sortOldestFirst;

  /// No description provided for @sortNewestFirst.
  ///
  /// In ru, this message translates to:
  /// **'Показать сначала новые'**
  String get sortNewestFirst;

  /// No description provided for @noMeasurementsForFilter.
  ///
  /// In ru, this message translates to:
  /// **'За выбранный период измерений нет'**
  String get noMeasurementsForFilter;

  /// No description provided for @resetFilter.
  ///
  /// In ru, this message translates to:
  /// **'Показать все'**
  String get resetFilter;

  /// No description provided for @convertToSeries.
  ///
  /// In ru, this message translates to:
  /// **'Преобразовать в серию'**
  String get convertToSeries;

  /// No description provided for @addMeasurement.
  ///
  /// In ru, this message translates to:
  /// **'Добавить измерение'**
  String get addMeasurement;

  /// No description provided for @seriesHasMaximum.
  ///
  /// In ru, this message translates to:
  /// **'В серии уже три измерения'**
  String get seriesHasMaximum;

  /// No description provided for @tonometers.
  ///
  /// In ru, this message translates to:
  /// **'Тонометры'**
  String get tonometers;

  /// No description provided for @addTonometer.
  ///
  /// In ru, this message translates to:
  /// **'Добавить тонометр'**
  String get addTonometer;

  /// No description provided for @editTonometer.
  ///
  /// In ru, this message translates to:
  /// **'Редактировать тонометр'**
  String get editTonometer;

  /// No description provided for @builtInProfile.
  ///
  /// In ru, this message translates to:
  /// **'Встроенный профиль'**
  String get builtInProfile;

  /// No description provided for @activeTonometer.
  ///
  /// In ru, this message translates to:
  /// **'Действующий тонометр'**
  String get activeTonometer;

  /// No description provided for @profileActions.
  ///
  /// In ru, this message translates to:
  /// **'Действия с профилем'**
  String get profileActions;

  /// No description provided for @editTonometerIntro.
  ///
  /// In ru, this message translates to:
  /// **'Измените название, углы LCD, области показаний или эталонные значения.'**
  String get editTonometerIntro;

  /// No description provided for @profileOpenFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось открыть профиль: {error}'**
  String profileOpenFailed(Object error);

  /// No description provided for @deleteTonometerTitle.
  ///
  /// In ru, this message translates to:
  /// **'Удалить профиль тонометра?'**
  String get deleteTonometerTitle;

  /// No description provided for @deleteTonometerMessage.
  ///
  /// In ru, this message translates to:
  /// **'Профиль «{name}» и его эталонная фотография будут удалены. Измерения останутся в истории.'**
  String deleteTonometerMessage(Object name);

  /// No description provided for @profileDeleteFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось удалить профиль: {error}'**
  String profileDeleteFailed(Object error);

  /// No description provided for @newTonometerIntro.
  ///
  /// In ru, this message translates to:
  /// **'Создайте профиль по четкой фотографии, на которой видны все три показания. Текущий профиль Microlife останется в списке.'**
  String get newTonometerIntro;

  /// No description provided for @tonometerName.
  ///
  /// In ru, this message translates to:
  /// **'Название профиля'**
  String get tonometerName;

  /// No description provided for @manufacturerOptional.
  ///
  /// In ru, this message translates to:
  /// **'Производитель (необязательно)'**
  String get manufacturerOptional;

  /// No description provided for @modelOptional.
  ///
  /// In ru, this message translates to:
  /// **'Модель (необязательно)'**
  String get modelOptional;

  /// No description provided for @enterTonometerName.
  ///
  /// In ru, this message translates to:
  /// **'Введите название тонометра'**
  String get enterTonometerName;

  /// No description provided for @takeReferencePhoto.
  ///
  /// In ru, this message translates to:
  /// **'Сделать эталонное фото'**
  String get takeReferencePhoto;

  /// No description provided for @retakeReferencePhoto.
  ///
  /// In ru, this message translates to:
  /// **'Переснять эталонное фото'**
  String get retakeReferencePhoto;

  /// No description provided for @lcdDetectionFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось найти LCD: {error}'**
  String lcdDetectionFailed(Object error);

  /// No description provided for @lcdRectificationFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось выровнять LCD: {error}'**
  String lcdRectificationFailed(Object error);

  /// No description provided for @checkDetectedLcd.
  ///
  /// In ru, this message translates to:
  /// **'Укажите углы LCD'**
  String get checkDetectedLcd;

  /// No description provided for @adjustLcdCorners.
  ///
  /// In ru, this message translates to:
  /// **'Переместите четыре синие точки точно на внутренние углы экрана. Для точной настройки выберите точку и используйте стрелки.'**
  String get adjustLcdCorners;

  /// No description provided for @cropAndAlignLcd.
  ///
  /// In ru, this message translates to:
  /// **'Обрезать и выровнять LCD'**
  String get cropAndAlignLcd;

  /// No description provided for @changeLcdCorners.
  ///
  /// In ru, this message translates to:
  /// **'Изменить углы LCD'**
  String get changeLcdCorners;

  /// No description provided for @markReadingsOnPreparedLcd.
  ///
  /// In ru, this message translates to:
  /// **'Укажите показания на подготовленном LCD'**
  String get markReadingsOnPreparedLcd;

  /// No description provided for @selectedCorner.
  ///
  /// In ru, this message translates to:
  /// **'Выбранный угол LCD'**
  String get selectedCorner;

  /// No description provided for @topLeftCorner.
  ///
  /// In ru, this message translates to:
  /// **'Левый верхний'**
  String get topLeftCorner;

  /// No description provided for @bottomRightCorner.
  ///
  /// In ru, this message translates to:
  /// **'Правый нижний'**
  String get bottomRightCorner;

  /// No description provided for @preciseMovement.
  ///
  /// In ru, this message translates to:
  /// **'Точное перемещение точки'**
  String get preciseMovement;

  /// No description provided for @moveUp.
  ///
  /// In ru, this message translates to:
  /// **'Сдвинуть вверх'**
  String get moveUp;

  /// No description provided for @moveDown.
  ///
  /// In ru, this message translates to:
  /// **'Сдвинуть вниз'**
  String get moveDown;

  /// No description provided for @moveLeft.
  ///
  /// In ru, this message translates to:
  /// **'Сдвинуть влево'**
  String get moveLeft;

  /// No description provided for @moveRight.
  ///
  /// In ru, this message translates to:
  /// **'Сдвинуть вправо'**
  String get moveRight;

  /// No description provided for @adjustMeasurementRegions.
  ///
  /// In ru, this message translates to:
  /// **'Перетащите каждый цветной прямоугольник на нужное показание. Круглый угол изменяет размер.'**
  String get adjustMeasurementRegions;

  /// No description provided for @referenceReadings.
  ///
  /// In ru, this message translates to:
  /// **'Значения на этом фото'**
  String get referenceReadings;

  /// No description provided for @enterReferenceValues.
  ///
  /// In ru, this message translates to:
  /// **'Введите SYS, DIA и Pulse с эталонной фотографии'**
  String get enterReferenceValues;

  /// No description provided for @saveAndTestProfile.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить и проверить профиль'**
  String get saveAndTestProfile;

  /// No description provided for @profileSaveFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось сохранить профиль: {error}'**
  String profileSaveFailed(Object error);

  /// No description provided for @testNewTonometer.
  ///
  /// In ru, this message translates to:
  /// **'Проверьте новый тонометр'**
  String get testNewTonometer;

  /// No description provided for @testPhotoRequest.
  ///
  /// In ru, this message translates to:
  /// **'Сделайте не менее трех фотографий с немного разных углов и проверьте каждый результат распознавания.'**
  String get testPhotoRequest;

  /// No description provided for @takeTestPhoto.
  ///
  /// In ru, this message translates to:
  /// **'Сделать тестовое фото {number}'**
  String takeTestPhoto(Object number);

  /// No description provided for @testRecognitionFailed.
  ///
  /// In ru, this message translates to:
  /// **'Тестовое распознавание не удалось: {error}'**
  String testRecognitionFailed(Object error);

  /// No description provided for @recognitionComplete.
  ///
  /// In ru, this message translates to:
  /// **'Распознаны все три значения'**
  String get recognitionComplete;

  /// No description provided for @recognitionNeedsAdjustment.
  ///
  /// In ru, this message translates to:
  /// **'Часть значений не распознана — профиль нужно уточнить'**
  String get recognitionNeedsAdjustment;

  /// No description provided for @adjustProfile.
  ///
  /// In ru, this message translates to:
  /// **'Исправить профиль'**
  String get adjustProfile;

  /// No description provided for @finishSetup.
  ///
  /// In ru, this message translates to:
  /// **'Завершить настройку'**
  String get finishSetup;

  /// No description provided for @editReadingRegions.
  ///
  /// In ru, this message translates to:
  /// **'Изменить области показаний'**
  String get editReadingRegions;

  /// No description provided for @continueToReferenceValues.
  ///
  /// In ru, this message translates to:
  /// **'Продолжить'**
  String get continueToReferenceValues;

  /// No description provided for @restoreCsv.
  ///
  /// In ru, this message translates to:
  /// **'Восстановить измерения из CSV'**
  String get restoreCsv;

  /// No description provided for @restoreMeasurementsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Заменить историю измерений?'**
  String get restoreMeasurementsTitle;

  /// No description provided for @restoreMeasurementsMessage.
  ///
  /// In ru, this message translates to:
  /// **'В файле {count} измерений в {seriesCount} сериях. Все текущие измерения и серии будут заменены.'**
  String restoreMeasurementsMessage(Object count, Object seriesCount);

  /// No description provided for @cancel.
  ///
  /// In ru, this message translates to:
  /// **'Отмена'**
  String get cancel;

  /// No description provided for @restore.
  ///
  /// In ru, this message translates to:
  /// **'Восстановить'**
  String get restore;

  /// No description provided for @restoreMeasurementsComplete.
  ///
  /// In ru, this message translates to:
  /// **'Восстановлено измерений: {count}'**
  String restoreMeasurementsComplete(Object count);

  /// No description provided for @restoreMeasurementsFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось восстановить измерения: {error}'**
  String restoreMeasurementsFailed(Object error);

  /// No description provided for @profileBackupActions.
  ///
  /// In ru, this message translates to:
  /// **'Резервное копирование профилей'**
  String get profileBackupActions;

  /// No description provided for @backupProfiles.
  ///
  /// In ru, this message translates to:
  /// **'Скопировать профили'**
  String get backupProfiles;

  /// No description provided for @restoreProfiles.
  ///
  /// In ru, this message translates to:
  /// **'Восстановить профили'**
  String get restoreProfiles;

  /// No description provided for @noCustomProfilesToBackup.
  ///
  /// In ru, this message translates to:
  /// **'Нет пользовательских профилей для копирования'**
  String get noCustomProfilesToBackup;

  /// No description provided for @profilesBackupSubject.
  ///
  /// In ru, this message translates to:
  /// **'Резервная копия профилей тонометров'**
  String get profilesBackupSubject;

  /// No description provided for @profilesBackupFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось скопировать профили: {error}'**
  String profilesBackupFailed(Object error);

  /// No description provided for @restoreProfilesTitle.
  ///
  /// In ru, this message translates to:
  /// **'Восстановить профили тонометров?'**
  String get restoreProfilesTitle;

  /// No description provided for @restoreProfilesMessage.
  ///
  /// In ru, this message translates to:
  /// **'В копии {count} пользовательских профилей. Профили с совпадающими ID будут заменены; остальные и встроенный профиль останутся.'**
  String restoreProfilesMessage(Object count);

  /// No description provided for @profilesRestored.
  ///
  /// In ru, this message translates to:
  /// **'Восстановлено профилей: {count}'**
  String profilesRestored(Object count);

  /// No description provided for @profilesRestoreFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось восстановить профили: {error}'**
  String profilesRestoreFailed(Object error);

  /// No description provided for @approximatelyScheduled.
  ///
  /// In ru, this message translates to:
  /// **'В расписании; без разрешения на точное время возможна задержка'**
  String get approximatelyScheduled;

  /// No description provided for @notificationsBlocked.
  ///
  /// In ru, this message translates to:
  /// **'Уведомления отключены в настройках телефона'**
  String get notificationsBlocked;

  /// No description provided for @reminderStatusFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось подтвердить расписание. Откройте напоминание и сохраните снова.'**
  String get reminderStatusFailed;

  /// No description provided for @notificationSettings.
  ///
  /// In ru, this message translates to:
  /// **'Настройки уведомлений'**
  String get notificationSettings;

  /// No description provided for @privacy.
  ///
  /// In ru, this message translates to:
  /// **'Конфиденциальность'**
  String get privacy;

  /// No description provided for @privacySummary.
  ///
  /// In ru, this message translates to:
  /// **'Tonometer работает локально на устройстве. Приложение не создаёт учётную запись, не показывает рекламу и не отправляет показания разработчику.'**
  String get privacySummary;

  /// No description provided for @privacyLocalDataTitle.
  ///
  /// In ru, this message translates to:
  /// **'Измерения и профили'**
  String get privacyLocalDataTitle;

  /// No description provided for @privacyLocalDataText.
  ///
  /// In ru, this message translates to:
  /// **'Измерения, комментарии, настройки напоминаний и профили тонометров хранятся только на этом устройстве, пока вы их не удалите или не удалите приложение.'**
  String get privacyLocalDataText;

  /// No description provided for @privacyCameraTitle.
  ///
  /// In ru, this message translates to:
  /// **'Камера и фотографии'**
  String get privacyCameraTitle;

  /// No description provided for @privacyCameraText.
  ///
  /// In ru, this message translates to:
  /// **'Доступ к камере используется для чтения экрана тонометра. Фотографии обрабатываются на устройстве и не загружаются на сервер.'**
  String get privacyCameraText;

  /// No description provided for @privacyRemindersTitle.
  ///
  /// In ru, this message translates to:
  /// **'Уведомления и напоминания'**
  String get privacyRemindersTitle;

  /// No description provided for @privacyRemindersText.
  ///
  /// In ru, this message translates to:
  /// **'Разрешения на уведомления и будильники используются только для настроенных вами напоминаний об измерении.'**
  String get privacyRemindersText;

  /// No description provided for @privacyExportTitle.
  ///
  /// In ru, this message translates to:
  /// **'Экспорт и резервные копии'**
  String get privacyExportTitle;

  /// No description provided for @privacyExportText.
  ///
  /// In ru, this message translates to:
  /// **'Данные покидают приложение только при явном экспорте или отправке резервной копии. Приложение-получателя или место хранения выбираете вы.'**
  String get privacyExportText;

  /// No description provided for @medicalDisclaimer.
  ///
  /// In ru, this message translates to:
  /// **'Это приложение — личный журнал и помощник распознавания, а не медицинское устройство. Проверяйте распознанные значения и обращайтесь к квалифицированному врачу для принятия медицинских решений.'**
  String get medicalDisclaimer;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
