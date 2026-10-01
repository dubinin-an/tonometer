// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Tonometer';

  @override
  String get showTable => 'Показать таблицу';

  @override
  String get showChart => 'Показать график';

  @override
  String get appMenu => 'Меню';

  @override
  String get reminders => 'Напоминания';

  @override
  String get exportCsv => 'Экспортировать CSV';

  @override
  String get language => 'Язык';

  @override
  String get russian => 'Русский';

  @override
  String get english => 'English';

  @override
  String get spanish => 'Español';

  @override
  String get edit => 'Изменить';

  @override
  String get delete => 'Удалить';

  @override
  String get doNotDelete => 'Не удалять';

  @override
  String get saving => 'Сохраняем…';

  @override
  String get optional => 'Необязательно';

  @override
  String get comment => 'Комментарий';

  @override
  String get retry => 'Повторить';

  @override
  String get time => 'Время';

  @override
  String get average => 'Среднее';

  @override
  String get pulse => 'Pulse';

  @override
  String get leftArm => 'Левая рука';

  @override
  String get rightArm => 'Правая рука';

  @override
  String get arm => 'Рука';

  @override
  String get deleteMeasurementTitle => 'Удалить измерение?';

  @override
  String deleteMeasurementMessage(int systolic, int diastolic, int pulse) {
    return '$systolic/$diastolic, пульс $pulse. Отменить удаление будет нельзя.';
  }

  @override
  String deleteEntryFailed(String error) {
    return 'Не удалось удалить запись: $error';
  }

  @override
  String get deleteSeriesTitle => 'Удалить всю серию?';

  @override
  String deleteSeriesMessage(int count) {
    return 'Будут удалены все измерения серии: $count.';
  }

  @override
  String get nothingToExport => 'Пока нечего экспортировать';

  @override
  String exportFailed(String error) {
    return 'Не удалось экспортировать: $error';
  }

  @override
  String get historyOpenFailed => 'Не удалось открыть историю';

  @override
  String get noMeasurements => 'Измерений пока нет';

  @override
  String get noMeasurementsDetail =>
      'Сфотографируйте экран тонометра или введите значения вручную.';

  @override
  String get startSeries => 'Начать серию измерений';

  @override
  String get photograph => 'Сфотографировать';

  @override
  String get manualEntry => 'Ввести измерение вручную';

  @override
  String get seriesActions => 'Действия с серией';

  @override
  String get deleteSeries => 'Удалить серию';

  @override
  String get measurementActions => 'Действия с измерением';

  @override
  String get collapse => 'Свернуть';

  @override
  String get expand => 'Раскрыть';

  @override
  String get collapseAllDays => 'Свернуть все дни';

  @override
  String get expandAllDays => 'Развернуть все дни';

  @override
  String measurementCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count измерений',
      few: '$count измерения',
      one: '$count измерение',
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
    return 'Серия, последнее измерение в $time. $count. Средние значения: давление $systolic на $diastolic, пульс $pulse. $action';
  }

  @override
  String measurementSemantics(
    String time,
    int systolic,
    int diastolic,
    int pulse,
    String arm,
  ) {
    return '$time. Давление $systolic на $diastolic, пульс $pulse, рука $arm.';
  }

  @override
  String get hasComment => 'Есть комментарий.';

  @override
  String get showComment => 'Показать комментарий';

  @override
  String get hideComment => 'Скрыть комментарий';

  @override
  String get integerRequired => 'Введите целое число';

  @override
  String allowedRange(int minimum, int maximum) {
    return 'Допустимо: $minimum–$maximum';
  }

  @override
  String saveFailed(String error) {
    return 'Не удалось сохранить: $error';
  }

  @override
  String get measurementDate => 'Дата измерения';

  @override
  String get measurementTime => 'Время измерения';

  @override
  String get editMeasurement => 'Изменить измерение';

  @override
  String get manualInput => 'Ручной ввод';

  @override
  String get checkValues => 'Проверьте значения';

  @override
  String get recognizedComplete =>
      'Значения распознаны. Исправьте их при необходимости.';

  @override
  String get recognizedIncomplete =>
      'Не все значения распознаны. Проверьте каждое поле.';

  @override
  String get measurementDateTime => 'Дата и время измерения';

  @override
  String get saveMeasurement => 'Сохранить измерение';

  @override
  String get saveChanges => 'Сохранить изменения';

  @override
  String seriesSaveFailed(String error) {
    return 'Не удалось сохранить серию: $error';
  }

  @override
  String get measurementSeries => 'Серия измерений';

  @override
  String get seriesReady => 'Серия готова';

  @override
  String measurementOfThree(int number) {
    return 'Измерение $number из 3';
  }

  @override
  String get makeFirstMeasurement => 'Сделайте первое измерение.';

  @override
  String get reviewAndSaveSeries => 'Проверьте значения и сохраните серию.';

  @override
  String get nextOrFinishSeries =>
      'Можно сделать следующее измерение или завершить после двух.';

  @override
  String get seriesComment => 'Комментарий к серии';

  @override
  String get nextMeasurement => 'Следующее измерение';

  @override
  String get finishSeries => 'Завершить серию';

  @override
  String measurementNumberTime(int number, String time) {
    return 'Измерение $number · $time';
  }

  @override
  String get cameraNotFound => 'Камера не найдена';

  @override
  String torchUnavailable(String error) {
    return 'Подсветка недоступна: $error';
  }

  @override
  String photoRecognitionFailed(String error) {
    return 'Не удалось распознать фото: $error';
  }

  @override
  String get photographDevice => 'Сфотографируйте прибор';

  @override
  String get recognizing => 'Распознаём…';

  @override
  String get capture => 'Снять';

  @override
  String get cameraInstruction =>
      'Держите телефон как удобно. Весь прибор должен быть виден.';

  @override
  String get disableTorch => 'Выключить подсветку';

  @override
  String get enableTorch => 'Включить подсветку';

  @override
  String get disableLight => 'Выключить свет';

  @override
  String get enableLight => 'Включить свет';

  @override
  String cameraUnavailable(String error) {
    return 'Камера недоступна\n$error';
  }

  @override
  String recognitionFailed(String error) {
    return 'Не удалось распознать значения: $error';
  }

  @override
  String get checkRegions => 'Проверьте области';

  @override
  String get regionsInstruction =>
      'Прямоугольники должны точно закрывать цифры SYS, DIA и Pulse.';

  @override
  String get blackWhiteMask => 'Ч/б маска';

  @override
  String get photo => 'Фото';

  @override
  String get blackWhitePreviewSemantics =>
      'Чёрно-белая маска для распознавания. Жёлтые области SYS, зелёные DIA, голубые Pulse.';

  @override
  String get photoPreviewSemantics =>
      'Выпрямленная фотография дисплея. Жёлтые области SYS, зелёные DIA, голубые Pulse.';

  @override
  String get recognize => 'Распознать';

  @override
  String get retake => 'Снять заново';

  @override
  String get zoomOut => 'Уменьшить масштаб';

  @override
  String get zoomIn => 'Увеличить масштаб';

  @override
  String get chartNoMeasurements => 'График без измерений.';

  @override
  String chartSemantics(
    String count,
    String period,
    int systolic,
    int diastolic,
    int pulse,
  ) {
    return 'График: $count. Среднее $period: SYS $systolic, DIA $diastolic, Pulse $pulse.';
  }

  @override
  String get lastSevenDays => 'за 7 дней';

  @override
  String get availableData => 'по имеющимся данным';

  @override
  String get chartScrollHint =>
      'Проведите по графику влево, чтобы увидеть более ранние измерения.';

  @override
  String get permissionInstruction =>
      'Разрешите уведомления Tonometer и канал «Measurement reminders» в настройках телефона.';

  @override
  String reminderChangeFailed(String error) {
    return 'Не удалось изменить напоминание: $error';
  }

  @override
  String testScheduled(String time) {
    return 'Проверка добавлена на $time. Без разрешения на точное время Android может задержать уведомление.';
  }

  @override
  String notificationTestFailed(String error) {
    return 'Не удалось запланировать проверку: $error';
  }

  @override
  String get deleteReminderTitle => 'Удалить напоминание?';

  @override
  String deleteReminderMessage(String time) {
    return 'Напоминание в $time больше не будет появляться.';
  }

  @override
  String deleteReminderFailed(String error) {
    return 'Не удалось удалить напоминание: $error';
  }

  @override
  String remindersOpenFailed(String error) {
    return 'Не удалось открыть напоминания: $error';
  }

  @override
  String get noReminders => 'Напоминаний пока нет';

  @override
  String get noRemindersDetail =>
      'Добавьте удобное время для регулярного измерения давления.';

  @override
  String get reminderActions => 'Действия с напоминанием';

  @override
  String get addReminder => 'Добавить напоминание';

  @override
  String get testInOneMinute => 'Проверить через 1 минуту';

  @override
  String get disabled => 'Отключено';

  @override
  String get exactlyScheduled => 'Добавлено в расписание';

  @override
  String get exactPermissionRequired => 'Нужно разрешение на точное время';

  @override
  String scheduledCount(int scheduled, int expected) {
    return 'Запланировано $scheduled из $expected';
  }

  @override
  String get everyDay => 'Каждый день';

  @override
  String get weekdays => 'По будням';

  @override
  String get weekdayMon => 'Пн';

  @override
  String get weekdayTue => 'Вт';

  @override
  String get weekdayWed => 'Ср';

  @override
  String get weekdayThu => 'Чт';

  @override
  String get weekdayFri => 'Пт';

  @override
  String get weekdaySat => 'Сб';

  @override
  String get weekdaySun => 'Вс';

  @override
  String get reminderTime => 'Время напоминания';

  @override
  String get selectWeekday => 'Выберите хотя бы один день недели';

  @override
  String reminderSaveFailed(String error) {
    return 'Не удалось сохранить напоминание: $error';
  }

  @override
  String get newReminder => 'Новое напоминание';

  @override
  String get editReminder => 'Изменить напоминание';

  @override
  String get repeat => 'Повторять';

  @override
  String get reminderEnabled => 'Напоминание включено';

  @override
  String get reminderEnabledDetail =>
      'Напоминание работает при закрытом приложении. Для точного времени разрешите «Будильники и напоминания» в настройках телефона.';

  @override
  String get saveReminder => 'Сохранить напоминание';

  @override
  String get csvShareTitle => 'Экспорт измерений Tonometer';

  @override
  String get csvSubject => 'Измерения артериального давления';

  @override
  String get displayedData => 'Отображаемые данные';

  @override
  String get filterAll => 'Все измерения';

  @override
  String get filterRecent => 'За последний период';

  @override
  String get filterSinceDate => 'С конкретной даты';

  @override
  String get periodLength => 'Длительность периода';

  @override
  String get decreasePeriod => 'Уменьшить период';

  @override
  String get increasePeriod => 'Увеличить период';

  @override
  String get weeks => 'Недели';

  @override
  String get months => 'Месяцы';

  @override
  String get applyFilter => 'Применить фильтр';

  @override
  String get filterData => 'Фильтровать данные';

  @override
  String get changeActiveFilter => 'Изменить активный фильтр';

  @override
  String get sortOldestFirst => 'Показать сначала старые';

  @override
  String get sortNewestFirst => 'Показать сначала новые';

  @override
  String get noMeasurementsForFilter => 'За выбранный период измерений нет';

  @override
  String get resetFilter => 'Показать все';

  @override
  String get convertToSeries => 'Преобразовать в серию';

  @override
  String get addMeasurement => 'Добавить измерение';

  @override
  String get seriesHasMaximum => 'В серии уже три измерения';

  @override
  String get tonometers => 'Тонометры';

  @override
  String get addTonometer => 'Добавить тонометр';

  @override
  String get editTonometer => 'Редактировать тонометр';

  @override
  String get builtInProfile => 'Встроенный профиль';

  @override
  String get activeTonometer => 'Действующий тонометр';

  @override
  String get profileActions => 'Действия с профилем';

  @override
  String get editTonometerIntro =>
      'Измените название, углы LCD, области показаний или эталонные значения.';

  @override
  String profileOpenFailed(Object error) {
    return 'Не удалось открыть профиль: $error';
  }

  @override
  String get deleteTonometerTitle => 'Удалить профиль тонометра?';

  @override
  String deleteTonometerMessage(Object name) {
    return 'Профиль «$name» и его эталонная фотография будут удалены. Измерения останутся в истории.';
  }

  @override
  String profileDeleteFailed(Object error) {
    return 'Не удалось удалить профиль: $error';
  }

  @override
  String get newTonometerIntro =>
      'Создайте профиль по четкой фотографии, на которой видны все три показания. Текущий профиль Microlife останется в списке.';

  @override
  String get tonometerName => 'Название профиля';

  @override
  String get manufacturerOptional => 'Производитель (необязательно)';

  @override
  String get modelOptional => 'Модель (необязательно)';

  @override
  String get enterTonometerName => 'Введите название тонометра';

  @override
  String get takeReferencePhoto => 'Сделать эталонное фото';

  @override
  String get retakeReferencePhoto => 'Переснять эталонное фото';

  @override
  String lcdDetectionFailed(Object error) {
    return 'Не удалось найти LCD: $error';
  }

  @override
  String lcdRectificationFailed(Object error) {
    return 'Не удалось выровнять LCD: $error';
  }

  @override
  String get checkDetectedLcd => 'Укажите углы LCD';

  @override
  String get adjustLcdCorners =>
      'Переместите четыре синие точки точно на внутренние углы экрана. Для точной настройки выберите точку и используйте стрелки.';

  @override
  String get cropAndAlignLcd => 'Обрезать и выровнять LCD';

  @override
  String get changeLcdCorners => 'Изменить углы LCD';

  @override
  String get markReadingsOnPreparedLcd =>
      'Укажите показания на подготовленном LCD';

  @override
  String get selectedCorner => 'Выбранный угол LCD';

  @override
  String get topLeftCorner => 'Левый верхний';

  @override
  String get bottomRightCorner => 'Правый нижний';

  @override
  String get preciseMovement => 'Точное перемещение точки';

  @override
  String get moveUp => 'Сдвинуть вверх';

  @override
  String get moveDown => 'Сдвинуть вниз';

  @override
  String get moveLeft => 'Сдвинуть влево';

  @override
  String get moveRight => 'Сдвинуть вправо';

  @override
  String get adjustMeasurementRegions =>
      'Перетащите каждый цветной прямоугольник на нужное показание. Круглый угол изменяет размер.';

  @override
  String get referenceReadings => 'Значения на этом фото';

  @override
  String get enterReferenceValues =>
      'Введите SYS, DIA и Pulse с эталонной фотографии';

  @override
  String get saveAndTestProfile => 'Сохранить и проверить профиль';

  @override
  String profileSaveFailed(Object error) {
    return 'Не удалось сохранить профиль: $error';
  }

  @override
  String get testNewTonometer => 'Проверьте новый тонометр';

  @override
  String get testPhotoRequest =>
      'Сделайте не менее трех фотографий с немного разных углов и проверьте каждый результат распознавания.';

  @override
  String takeTestPhoto(Object number) {
    return 'Сделать тестовое фото $number';
  }

  @override
  String testRecognitionFailed(Object error) {
    return 'Тестовое распознавание не удалось: $error';
  }

  @override
  String get recognitionComplete => 'Распознаны все три значения';

  @override
  String get recognitionNeedsAdjustment =>
      'Часть значений не распознана — профиль нужно уточнить';

  @override
  String get adjustProfile => 'Исправить профиль';

  @override
  String get finishSetup => 'Завершить настройку';

  @override
  String get editReadingRegions => 'Изменить области показаний';

  @override
  String get continueToReferenceValues => 'Продолжить';

  @override
  String get restoreCsv => 'Восстановить измерения из CSV';

  @override
  String get restoreMeasurementsTitle => 'Заменить историю измерений?';

  @override
  String restoreMeasurementsMessage(Object count, Object seriesCount) {
    return 'В файле $count измерений в $seriesCount сериях. Все текущие измерения и серии будут заменены.';
  }

  @override
  String get cancel => 'Отмена';

  @override
  String get restore => 'Восстановить';

  @override
  String restoreMeasurementsComplete(Object count) {
    return 'Восстановлено измерений: $count';
  }

  @override
  String restoreMeasurementsFailed(Object error) {
    return 'Не удалось восстановить измерения: $error';
  }

  @override
  String get profileBackupActions => 'Резервное копирование профилей';

  @override
  String get backupProfiles => 'Скопировать профили';

  @override
  String get restoreProfiles => 'Восстановить профили';

  @override
  String get noCustomProfilesToBackup =>
      'Нет пользовательских профилей для копирования';

  @override
  String get profilesBackupSubject => 'Резервная копия профилей тонометров';

  @override
  String profilesBackupFailed(Object error) {
    return 'Не удалось скопировать профили: $error';
  }

  @override
  String get restoreProfilesTitle => 'Восстановить профили тонометров?';

  @override
  String restoreProfilesMessage(Object count) {
    return 'В копии $count пользовательских профилей. Профили с совпадающими ID будут заменены; остальные и встроенный профиль останутся.';
  }

  @override
  String profilesRestored(Object count) {
    return 'Восстановлено профилей: $count';
  }

  @override
  String profilesRestoreFailed(Object error) {
    return 'Не удалось восстановить профили: $error';
  }

  @override
  String get approximatelyScheduled =>
      'В расписании; без разрешения на точное время возможна задержка';

  @override
  String get notificationsBlocked =>
      'Уведомления отключены в настройках телефона';

  @override
  String get reminderStatusFailed =>
      'Не удалось подтвердить расписание. Откройте напоминание и сохраните снова.';

  @override
  String get notificationSettings => 'Настройки уведомлений';

  @override
  String get privacy => 'Конфиденциальность';

  @override
  String get privacySummary =>
      'Tonometer работает локально на устройстве. Приложение не создаёт учётную запись, не показывает рекламу и не отправляет показания разработчику.';

  @override
  String get privacyLocalDataTitle => 'Измерения и профили';

  @override
  String get privacyLocalDataText =>
      'Измерения, комментарии, настройки напоминаний и профили тонометров хранятся только на этом устройстве, пока вы их не удалите или не удалите приложение.';

  @override
  String get privacyCameraTitle => 'Камера и фотографии';

  @override
  String get privacyCameraText =>
      'Доступ к камере используется для чтения экрана тонометра. Фотографии обрабатываются на устройстве и не загружаются на сервер.';

  @override
  String get privacyRemindersTitle => 'Уведомления и напоминания';

  @override
  String get privacyRemindersText =>
      'Разрешения на уведомления и будильники используются только для настроенных вами напоминаний об измерении.';

  @override
  String get privacyExportTitle => 'Экспорт и резервные копии';

  @override
  String get privacyExportText =>
      'Данные покидают приложение только при явном экспорте или отправке резервной копии. Приложение-получателя или место хранения выбираете вы.';

  @override
  String get medicalDisclaimer =>
      'Это приложение — личный журнал и помощник распознавания, а не медицинское устройство. Проверяйте распознанные значения и обращайтесь к квалифицированному врачу для принятия медицинских решений.';
}
