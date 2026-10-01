import 'dart:io';
import 'dart:ui';

import 'package:path_provider/path_provider.dart';

class LocaleService {
  static const supportedLanguageCodes = {'ru', 'en', 'es'};
  static const _fileName = 'locale.txt';

  Future<Locale?> load() async {
    try {
      final file = await _file();
      if (!await file.exists()) return null;
      final code = (await file.readAsString()).trim();
      return supportedLanguageCodes.contains(code) ? Locale(code) : null;
    } on FileSystemException {
      return null;
    }
  }

  Future<void> save(Locale locale) async {
    if (!supportedLanguageCodes.contains(locale.languageCode)) return;
    await (await _file()).writeAsString(locale.languageCode, flush: true);
  }

  Locale resolveSystemLocale(Locale systemLocale) {
    return supportedLanguageCodes.contains(systemLocale.languageCode)
        ? Locale(systemLocale.languageCode)
        : const Locale('en');
  }

  Future<File> _file() async {
    final directory = await getApplicationSupportDirectory();
    return File('${directory.path}/$_fileName');
  }
}
