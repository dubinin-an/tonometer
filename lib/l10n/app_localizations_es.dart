// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Tonometer';

  @override
  String get showTable => 'Mostrar tabla';

  @override
  String get showChart => 'Mostrar gráfico';

  @override
  String get appMenu => 'Menú';

  @override
  String get reminders => 'Recordatorios';

  @override
  String get exportCsv => 'Exportar CSV';

  @override
  String get language => 'Idioma';

  @override
  String get russian => 'Русский';

  @override
  String get english => 'English';

  @override
  String get spanish => 'Español';

  @override
  String get edit => 'Editar';

  @override
  String get delete => 'Eliminar';

  @override
  String get doNotDelete => 'Conservar';

  @override
  String get saving => 'Guardando…';

  @override
  String get optional => 'Opcional';

  @override
  String get comment => 'Comentario';

  @override
  String get retry => 'Reintentar';

  @override
  String get time => 'Hora';

  @override
  String get average => 'Promedio';

  @override
  String get pulse => 'Pulso';

  @override
  String get leftArm => 'Brazo izquierdo';

  @override
  String get rightArm => 'Brazo derecho';

  @override
  String get arm => 'Brazo';

  @override
  String get deleteMeasurementTitle => '¿Eliminar la medición?';

  @override
  String deleteMeasurementMessage(int systolic, int diastolic, int pulse) {
    return '$systolic/$diastolic, pulso $pulse. Esta acción no se puede deshacer.';
  }

  @override
  String deleteEntryFailed(String error) {
    return 'No se pudo eliminar el registro: $error';
  }

  @override
  String get deleteSeriesTitle => '¿Eliminar toda la serie?';

  @override
  String deleteSeriesMessage(int count) {
    return 'Se eliminarán las $count mediciones de la serie.';
  }

  @override
  String get nothingToExport => 'Todavía no hay nada para exportar';

  @override
  String exportFailed(String error) {
    return 'No se pudo exportar: $error';
  }

  @override
  String get historyOpenFailed => 'No se pudo abrir el historial';

  @override
  String get noMeasurements => 'Todavía no hay mediciones';

  @override
  String get noMeasurementsDetail =>
      'Fotografía la pantalla del tensiómetro o introduce los valores manualmente.';

  @override
  String get startSeries => 'Iniciar una serie de mediciones';

  @override
  String get photograph => 'Fotografiar';

  @override
  String get manualEntry => 'Introducir una medición manualmente';

  @override
  String get seriesActions => 'Acciones de la serie';

  @override
  String get deleteSeries => 'Eliminar serie';

  @override
  String get measurementActions => 'Acciones de la medición';

  @override
  String get collapse => 'Contraer';

  @override
  String get expand => 'Expandir';

  @override
  String get collapseAllDays => 'Contraer todos los días';

  @override
  String get expandAllDays => 'Expandir todos los días';

  @override
  String measurementCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mediciones',
      one: '$count medición',
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
    return 'Serie, última medición a las $time. $count. Promedios: presión $systolic sobre $diastolic, pulso $pulse. $action';
  }

  @override
  String measurementSemantics(
    String time,
    int systolic,
    int diastolic,
    int pulse,
    String arm,
  ) {
    return '$time. Presión $systolic sobre $diastolic, pulso $pulse, $arm.';
  }

  @override
  String get hasComment => 'Tiene comentario.';

  @override
  String get showComment => 'Mostrar comentario';

  @override
  String get hideComment => 'Ocultar comentario';

  @override
  String get integerRequired => 'Introduce un número entero';

  @override
  String allowedRange(int minimum, int maximum) {
    return 'Permitido: $minimum–$maximum';
  }

  @override
  String saveFailed(String error) {
    return 'No se pudo guardar: $error';
  }

  @override
  String get measurementDate => 'Fecha de la medición';

  @override
  String get measurementTime => 'Hora de la medición';

  @override
  String get editMeasurement => 'Editar medición';

  @override
  String get manualInput => 'Entrada manual';

  @override
  String get checkValues => 'Comprueba los valores';

  @override
  String get recognizedComplete =>
      'Valores reconocidos. Corrígelos si es necesario.';

  @override
  String get recognizedIncomplete =>
      'No se reconocieron todos los valores. Comprueba cada campo.';

  @override
  String get measurementDateTime => 'Fecha y hora de la medición';

  @override
  String get saveMeasurement => 'Guardar medición';

  @override
  String get saveChanges => 'Guardar cambios';

  @override
  String seriesSaveFailed(String error) {
    return 'No se pudo guardar la serie: $error';
  }

  @override
  String get measurementSeries => 'Serie de mediciones';

  @override
  String get seriesReady => 'Serie lista';

  @override
  String measurementOfThree(int number) {
    return 'Medición $number de 3';
  }

  @override
  String get makeFirstMeasurement => 'Realiza la primera medición.';

  @override
  String get reviewAndSaveSeries => 'Comprueba los valores y guarda la serie.';

  @override
  String get nextOrFinishSeries =>
      'Puedes realizar otra medición o terminar después de dos.';

  @override
  String get seriesComment => 'Comentario de la serie';

  @override
  String get nextMeasurement => 'Siguiente medición';

  @override
  String get finishSeries => 'Finalizar serie';

  @override
  String measurementNumberTime(int number, String time) {
    return 'Medición $number · $time';
  }

  @override
  String get cameraNotFound => 'No se encontró ninguna cámara';

  @override
  String torchUnavailable(String error) {
    return 'Linterna no disponible: $error';
  }

  @override
  String photoRecognitionFailed(String error) {
    return 'No se pudo reconocer la foto: $error';
  }

  @override
  String get photographDevice => 'Fotografía el tensiómetro';

  @override
  String get recognizing => 'Reconociendo…';

  @override
  String get capture => 'Capturar';

  @override
  String get cameraInstruction =>
      'Sujeta el teléfono cómodamente. El tensiómetro completo debe quedar visible.';

  @override
  String get disableTorch => 'Apagar la linterna';

  @override
  String get enableTorch => 'Encender la linterna';

  @override
  String get disableLight => 'Apagar la luz';

  @override
  String get enableLight => 'Encender la luz';

  @override
  String cameraUnavailable(String error) {
    return 'Cámara no disponible\n$error';
  }

  @override
  String recognitionFailed(String error) {
    return 'No se pudieron reconocer los valores: $error';
  }

  @override
  String get checkRegions => 'Comprueba las áreas';

  @override
  String get regionsInstruction =>
      'Los rectángulos deben cubrir exactamente los dígitos SYS, DIA y Pulso.';

  @override
  String get blackWhiteMask => 'Máscara B/N';

  @override
  String get photo => 'Foto';

  @override
  String get blackWhitePreviewSemantics =>
      'Máscara de reconocimiento en blanco y negro. Las áreas SYS son amarillas, DIA verdes y Pulso azules.';

  @override
  String get photoPreviewSemantics =>
      'Foto rectificada de la pantalla. Las áreas SYS son amarillas, DIA verdes y Pulso azules.';

  @override
  String get recognize => 'Reconocer';

  @override
  String get retake => 'Repetir foto';

  @override
  String get zoomOut => 'Alejar';

  @override
  String get zoomIn => 'Acercar';

  @override
  String get chartNoMeasurements => 'Gráfico sin mediciones.';

  @override
  String chartSemantics(
    String count,
    String period,
    int systolic,
    int diastolic,
    int pulse,
  ) {
    return 'Gráfico: $count. Promedio $period: SYS $systolic, DIA $diastolic, Pulso $pulse.';
  }

  @override
  String get lastSevenDays => 'de 7 días';

  @override
  String get availableData => 'de los datos disponibles';

  @override
  String get chartScrollHint =>
      'Desliza el gráfico hacia la izquierda para ver mediciones anteriores.';

  @override
  String get permissionInstruction =>
      'Permite las notificaciones de Tonometer y el canal «Measurement reminders» en los ajustes del teléfono.';

  @override
  String reminderChangeFailed(String error) {
    return 'No se pudo cambiar el recordatorio: $error';
  }

  @override
  String testScheduled(String time) {
    return 'Prueba añadida para las $time. Sin permiso para alarmas exactas, Android puede retrasar la notificación.';
  }

  @override
  String notificationTestFailed(String error) {
    return 'No se pudo programar la prueba: $error';
  }

  @override
  String get deleteReminderTitle => '¿Eliminar el recordatorio?';

  @override
  String deleteReminderMessage(String time) {
    return 'El recordatorio de las $time dejará de aparecer.';
  }

  @override
  String deleteReminderFailed(String error) {
    return 'No se pudo eliminar el recordatorio: $error';
  }

  @override
  String remindersOpenFailed(String error) {
    return 'No se pudieron abrir los recordatorios: $error';
  }

  @override
  String get noReminders => 'Todavía no hay recordatorios';

  @override
  String get noRemindersDetail =>
      'Añade una hora conveniente para medir regularmente la presión arterial.';

  @override
  String get reminderActions => 'Acciones del recordatorio';

  @override
  String get addReminder => 'Añadir recordatorio';

  @override
  String get testInOneMinute => 'Probar en 1 minuto';

  @override
  String get disabled => 'Desactivado';

  @override
  String get exactlyScheduled => 'Añadido a la programación';

  @override
  String get exactPermissionRequired =>
      'Se requiere permiso para la hora exacta';

  @override
  String scheduledCount(int scheduled, int expected) {
    return 'Programados $scheduled de $expected';
  }

  @override
  String get everyDay => 'Todos los días';

  @override
  String get weekdays => 'Días laborables';

  @override
  String get weekdayMon => 'Lun';

  @override
  String get weekdayTue => 'Mar';

  @override
  String get weekdayWed => 'Mié';

  @override
  String get weekdayThu => 'Jue';

  @override
  String get weekdayFri => 'Vie';

  @override
  String get weekdaySat => 'Sáb';

  @override
  String get weekdaySun => 'Dom';

  @override
  String get reminderTime => 'Hora del recordatorio';

  @override
  String get selectWeekday => 'Selecciona al menos un día de la semana';

  @override
  String reminderSaveFailed(String error) {
    return 'No se pudo guardar el recordatorio: $error';
  }

  @override
  String get newReminder => 'Nuevo recordatorio';

  @override
  String get editReminder => 'Editar recordatorio';

  @override
  String get repeat => 'Repetir';

  @override
  String get reminderEnabled => 'Recordatorio activado';

  @override
  String get reminderEnabledDetail =>
      'Los recordatorios funcionan con la aplicación cerrada. Para la hora exacta, permite «Alarmas y recordatorios» en los ajustes del teléfono.';

  @override
  String get saveReminder => 'Guardar recordatorio';

  @override
  String get csvShareTitle => 'Exportar mediciones de Tonometer';

  @override
  String get csvSubject => 'Mediciones de presión arterial';

  @override
  String get displayedData => 'Datos mostrados';

  @override
  String get filterAll => 'Todas las mediciones';

  @override
  String get filterRecent => 'Período reciente';

  @override
  String get filterSinceDate => 'Desde una fecha específica';

  @override
  String get periodLength => 'Duración del período';

  @override
  String get decreasePeriod => 'Reducir el período';

  @override
  String get increasePeriod => 'Aumentar el período';

  @override
  String get weeks => 'Semanas';

  @override
  String get months => 'Meses';

  @override
  String get applyFilter => 'Aplicar filtro';

  @override
  String get filterData => 'Filtrar datos';

  @override
  String get changeActiveFilter => 'Cambiar el filtro activo';

  @override
  String get sortOldestFirst => 'Mostrar primero las más antiguas';

  @override
  String get sortNewestFirst => 'Mostrar primero las más recientes';

  @override
  String get noMeasurementsForFilter =>
      'No hay mediciones en el período seleccionado';

  @override
  String get resetFilter => 'Mostrar todo';

  @override
  String get convertToSeries => 'Convertir en serie';

  @override
  String get addMeasurement => 'Añadir medición';

  @override
  String get seriesHasMaximum => 'La serie ya tiene tres mediciones';

  @override
  String get tonometers => 'Tensiómetros';

  @override
  String get addTonometer => 'Añadir tensiómetro';

  @override
  String get editTonometer => 'Editar tensiómetro';

  @override
  String get builtInProfile => 'Perfil integrado';

  @override
  String get activeTonometer => 'Tensiómetro activo';

  @override
  String get profileActions => 'Acciones del perfil';

  @override
  String get editTonometerIntro =>
      'Actualiza el nombre, las esquinas del LCD, las áreas de lectura o los valores de referencia.';

  @override
  String profileOpenFailed(Object error) {
    return 'No se pudo abrir el perfil: $error';
  }

  @override
  String get deleteTonometerTitle => '¿Eliminar el perfil del tensiómetro?';

  @override
  String deleteTonometerMessage(Object name) {
    return 'Se eliminarán el perfil «$name» y su foto de referencia. Las mediciones permanecerán en el historial.';
  }

  @override
  String profileDeleteFailed(Object error) {
    return 'No se pudo eliminar el perfil: $error';
  }

  @override
  String get newTonometerIntro =>
      'Crea un perfil con una foto clara donde se vean las tres lecturas. El perfil Microlife actual seguirá disponible.';

  @override
  String get tonometerName => 'Nombre del perfil';

  @override
  String get manufacturerOptional => 'Fabricante (opcional)';

  @override
  String get modelOptional => 'Modelo (opcional)';

  @override
  String get enterTonometerName => 'Introduce un nombre para el tensiómetro';

  @override
  String get takeReferencePhoto => 'Tomar foto de referencia';

  @override
  String get retakeReferencePhoto => 'Repetir foto de referencia';

  @override
  String lcdDetectionFailed(Object error) {
    return 'No se pudo detectar la pantalla LCD: $error';
  }

  @override
  String lcdRectificationFailed(Object error) {
    return 'No se pudo alinear la pantalla LCD: $error';
  }

  @override
  String get checkDetectedLcd => 'Marca las esquinas de la pantalla LCD';

  @override
  String get adjustLcdCorners =>
      'Mueve los cuatro puntos azules exactamente a las esquinas interiores de la pantalla. Selecciona un punto y usa las flechas para ajustarlo.';

  @override
  String get cropAndAlignLcd => 'Recortar y alinear LCD';

  @override
  String get changeLcdCorners => 'Cambiar esquinas del LCD';

  @override
  String get markReadingsOnPreparedLcd =>
      'Marca las lecturas en el LCD preparado';

  @override
  String get selectedCorner => 'Esquina LCD seleccionada';

  @override
  String get topLeftCorner => 'Superior izquierda';

  @override
  String get bottomRightCorner => 'Inferior derecha';

  @override
  String get preciseMovement => 'Movimiento preciso del punto';

  @override
  String get moveUp => 'Mover arriba';

  @override
  String get moveDown => 'Mover abajo';

  @override
  String get moveLeft => 'Mover a la izquierda';

  @override
  String get moveRight => 'Mover a la derecha';

  @override
  String get adjustMeasurementRegions =>
      'Arrastra cada rectángulo de color hasta su lectura. Arrastra la esquina redonda para cambiar su tamaño.';

  @override
  String get referenceReadings => 'Valores mostrados en esta foto';

  @override
  String get enterReferenceValues =>
      'Introduce SYS, DIA y Pulso de la foto de referencia';

  @override
  String get saveAndTestProfile => 'Guardar y probar el perfil';

  @override
  String profileSaveFailed(Object error) {
    return 'No se pudo guardar el perfil: $error';
  }

  @override
  String get testNewTonometer => 'Prueba el nuevo tensiómetro';

  @override
  String get testPhotoRequest =>
      'Toma al menos tres fotos desde ángulos ligeramente diferentes y comprueba cada resultado.';

  @override
  String takeTestPhoto(Object number) {
    return 'Tomar foto de prueba $number';
  }

  @override
  String testRecognitionFailed(Object error) {
    return 'Falló el reconocimiento de prueba: $error';
  }

  @override
  String get recognitionComplete => 'Se reconocieron los tres valores';

  @override
  String get recognitionNeedsAdjustment =>
      'No se reconocieron algunos valores; hay que ajustar el perfil';

  @override
  String get adjustProfile => 'Ajustar perfil';

  @override
  String get finishSetup => 'Finalizar configuración';

  @override
  String get editReadingRegions => 'Editar áreas de lectura';

  @override
  String get continueToReferenceValues => 'Continuar';

  @override
  String get restoreCsv => 'Restaurar mediciones desde CSV';

  @override
  String get restoreMeasurementsTitle =>
      '¿Reemplazar el historial de mediciones?';

  @override
  String restoreMeasurementsMessage(Object count, Object seriesCount) {
    return 'El archivo contiene $count mediciones en $seriesCount series. Se reemplazarán todas las mediciones y series actuales.';
  }

  @override
  String get cancel => 'Cancelar';

  @override
  String get restore => 'Restaurar';

  @override
  String restoreMeasurementsComplete(Object count) {
    return 'Se restauraron $count mediciones';
  }

  @override
  String restoreMeasurementsFailed(Object error) {
    return 'No se pudieron restaurar las mediciones: $error';
  }

  @override
  String get profileBackupActions => 'Copia de perfiles';

  @override
  String get backupProfiles => 'Copiar perfiles';

  @override
  String get restoreProfiles => 'Restaurar perfiles';

  @override
  String get noCustomProfilesToBackup =>
      'No hay perfiles personalizados para copiar';

  @override
  String get profilesBackupSubject => 'Copia de perfiles de tensiómetros';

  @override
  String profilesBackupFailed(Object error) {
    return 'No se pudieron copiar los perfiles: $error';
  }

  @override
  String get restoreProfilesTitle => '¿Restaurar perfiles de tensiómetros?';

  @override
  String restoreProfilesMessage(Object count) {
    return 'La copia contiene $count perfiles personalizados. Se reemplazarán los perfiles con los mismos ID; los demás y el perfil integrado se conservarán.';
  }

  @override
  String profilesRestored(Object count) {
    return 'Se restauraron $count perfiles';
  }

  @override
  String profilesRestoreFailed(Object error) {
    return 'No se pudieron restaurar los perfiles: $error';
  }

  @override
  String get approximatelyScheduled =>
      'Programado; puede retrasarse sin permiso para alarmas exactas';

  @override
  String get notificationsBlocked =>
      'Las notificaciones están desactivadas en los ajustes del teléfono';

  @override
  String get reminderStatusFailed =>
      'No se pudo confirmar la programación. Abre el recordatorio y guárdalo de nuevo.';

  @override
  String get notificationSettings => 'Ajustes de notificaciones';

  @override
  String get privacy => 'Privacidad';

  @override
  String get privacySummary =>
      'Tonometer funciona localmente en el dispositivo. No crea una cuenta, no muestra anuncios ni envía las mediciones al desarrollador.';

  @override
  String get privacyLocalDataTitle => 'Mediciones y perfiles';

  @override
  String get privacyLocalDataText =>
      'Las mediciones, los comentarios, los ajustes de recordatorios y los perfiles de tensiómetros se guardan solo en este dispositivo hasta que los elimines o desinstales la aplicación.';

  @override
  String get privacyCameraTitle => 'Cámara y fotografías';

  @override
  String get privacyCameraText =>
      'El acceso a la cámara se usa para leer la pantalla del tensiómetro. Las fotos se procesan en el dispositivo y no se suben a ningún servidor.';

  @override
  String get privacyRemindersTitle => 'Notificaciones y recordatorios';

  @override
  String get privacyRemindersText =>
      'Los permisos de notificaciones y alarmas se usan únicamente para los recordatorios de medición que configures.';

  @override
  String get privacyExportTitle => 'Exportación y copias de seguridad';

  @override
  String get privacyExportText =>
      'Los datos solo salen de la aplicación cuando exportas o compartes una copia de forma explícita. Tú eliges la aplicación receptora o el lugar de almacenamiento.';

  @override
  String get medicalDisclaimer =>
      'Esta aplicación es un diario personal y una ayuda de reconocimiento, no un dispositivo médico. Comprueba los valores reconocidos y consulta a un profesional sanitario para tomar decisiones médicas.';
}
