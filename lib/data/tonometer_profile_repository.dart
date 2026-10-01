import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../domain/tonometer_profile.dart';

class TonometerProfileRepository {
  static const builtInId = 'microlife-unknown-model-v1';
  static const builtInProfileAsset =
      'assets/profiles/microlife_test_tonometer.profile.json';

  Future<Directory> _profilesDirectory() async {
    final documents = await getApplicationDocumentsDirectory();
    final directory = Directory(
      path.join(documents.path, 'tonometer_profiles'),
    );
    await directory.create(recursive: true);
    return directory;
  }

  Future<File> _activeFile() async {
    final directory = await _profilesDirectory();
    return File(path.join(directory.path, 'active_profile.txt'));
  }

  Future<List<TonometerProfileSummary>> getAll() async {
    final builtInJson = jsonDecode(
      await rootBundle.loadString(builtInProfileAsset),
    ) as Map<String, dynamic>;
    final result = <TonometerProfileSummary>[_summary(builtInJson, true)];
    final directory = await _profilesDirectory();
    await for (final entity in directory.list()) {
      if (entity is! File || !entity.path.endsWith('.profile.json')) continue;
      try {
        final value = jsonDecode(await entity.readAsString());
        if (value is Map<String, dynamic>) result.add(_summary(value, false));
      } on FormatException {
        // A damaged custom profile is ignored; the built-in profile remains usable.
      }
    }
    return result;
  }

  Future<String> getActiveId() async {
    final file = await _activeFile();
    if (!await file.exists()) return builtInId;
    final id = (await file.readAsString()).trim();
    final available = await getAll();
    return available.any((item) => item.id == id) ? id : builtInId;
  }

  Future<void> setActive(String id) async {
    final available = await getAll();
    if (!available.any((item) => item.id == id)) {
      throw ArgumentError.value(id, 'id', 'Unknown tonometer profile');
    }
    await (await _activeFile()).writeAsString(id, flush: true);
  }

  Future<TonometerProfileBundle> loadActive() async {
    final id = await getActiveId();
    return load(id);
  }

  Future<TonometerProfileBundle> load(String id) async {
    if (id == builtInId) {
      final source = await rootBundle.loadString(builtInProfileAsset);
      final json = jsonDecode(source) as Map<String, dynamic>;
      final reference = json['calibrationReference'] as Map<String, dynamic>;
      final asset = reference['asset'] as String;
      final data = await rootBundle.load(asset);
      return TonometerProfileBundle(
        json: source,
        referenceBytes: data.buffer.asUint8List(
          data.offsetInBytes,
          data.lengthInBytes,
        ),
      );
    }
    final directory = await _profilesDirectory();
    final profileFile = File(path.join(directory.path, '$id.profile.json'));
    final source = await profileFile.readAsString();
    final json = jsonDecode(source) as Map<String, dynamic>;
    final reference = json['calibrationReference'] as Map<String, dynamic>;
    final referenceFile = File(
      path.join(directory.path, reference['fileName'] as String),
    );
    return TonometerProfileBundle(
      json: source,
      referenceBytes: await referenceFile.readAsBytes(),
    );
  }

  Future<void> deleteCustom(String id) async {
    if (id == builtInId) {
      throw ArgumentError('The built-in profile cannot be deleted');
    }
    final wasActive = await getActiveId() == id;
    final directory = await _profilesDirectory();
    final profileFile = File(path.join(directory.path, '$id.profile.json'));
    if (!await profileFile.exists()) return;
    final source = await profileFile.readAsString();
    final json = jsonDecode(source) as Map<String, dynamic>;
    final reference = json['calibrationReference'] as Map<String, dynamic>?;
    final referenceName = reference?['fileName'] as String?;
    await profileFile.delete();
    if (referenceName != null) {
      final referenceFile = File(path.join(directory.path, referenceName));
      if (await referenceFile.exists()) await referenceFile.delete();
    }
    if (wasActive) {
      await (await _activeFile()).writeAsString(builtInId, flush: true);
    }
  }

  Future<void> saveCustom({
    required Map<String, dynamic> profile,
    required Uint8List referenceBytes,
    bool makeActive = true,
  }) async {
    final id = profile['id'] as String;
    final directory = await _profilesDirectory();
    final referenceName = '$id.reference.jpg';
    final reference = profile['calibrationReference'] as Map<String, dynamic>;
    reference['fileName'] = referenceName;
    reference.remove('asset');
    await File(path.join(directory.path, referenceName))
        .writeAsBytes(referenceBytes, flush: true);
    await File(path.join(directory.path, '$id.profile.json')).writeAsString(
      const JsonEncoder.withIndent('  ').convert(profile),
      flush: true,
    );
    if (makeActive) await setActive(id);
  }

  TonometerProfileSummary _summary(Map<String, dynamic> json, bool builtIn) {
    final device = json['device'] as Map<String, dynamic>? ?? const {};
    return TonometerProfileSummary(
      id: json['id'] as String,
      name: json['name'] as String,
      manufacturer: device['manufacturer'] as String?,
      model: device['model'] as String?,
      builtIn: builtIn,
    );
  }
}
