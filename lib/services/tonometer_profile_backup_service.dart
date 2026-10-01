import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../data/tonometer_profile_repository.dart';

class TonometerProfileBackupEntry {
  const TonometerProfileBackupEntry(this.profile, this.referenceBytes);

  final Map<String, dynamic> profile;
  final Uint8List referenceBytes;
}

class TonometerProfilesBackup {
  const TonometerProfilesBackup({required this.entries, this.activeProfileId});

  final List<TonometerProfileBackupEntry> entries;
  final String? activeProfileId;
}

class TonometerProfileBackupService {
  const TonometerProfileBackupService();

  Future<TonometerProfilesBackup> create(
    TonometerProfileRepository repository,
  ) async {
    final summaries = await repository.getAll();
    final entries = <TonometerProfileBackupEntry>[];
    for (final summary in summaries.where((item) => !item.builtIn)) {
      final bundle = await repository.load(summary.id);
      entries.add(
        TonometerProfileBackupEntry(
          jsonDecode(bundle.json) as Map<String, dynamic>,
          bundle.referenceBytes,
        ),
      );
    }
    return TonometerProfilesBackup(
      entries: entries,
      activeProfileId: await repository.getActiveId(),
    );
  }

  String encode(TonometerProfilesBackup backup) =>
      const JsonEncoder.withIndent('  ').convert({
        'format': 'tonometer_profiles_backup',
        'version': 1,
        'exportedAt': DateTime.now().toUtc().toIso8601String(),
        'activeProfileId': backup.activeProfileId,
        'profiles': backup.entries
            .map(
              (entry) => {
                'profile': entry.profile,
                'referenceBase64': base64Encode(entry.referenceBytes),
              },
            )
            .toList(),
      });

  TonometerProfilesBackup decodeBytes(Uint8List bytes) {
    final root = jsonDecode(utf8.decode(bytes));
    if (root is! Map<String, dynamic> ||
        root['format'] != 'tonometer_profiles_backup' ||
        root['version'] != 1) {
      throw const FormatException('Unsupported profile backup');
    }
    final rawProfiles = root['profiles'];
    if (rawProfiles is! List) throw const FormatException('Missing profiles');
    final entries = <TonometerProfileBackupEntry>[];
    final ids = <String>{};
    for (final raw in rawProfiles) {
      if (raw is! Map<String, dynamic> ||
          raw['profile'] is! Map<String, dynamic>) {
        throw const FormatException('Invalid profile entry');
      }
      final profile = Map<String, dynamic>.from(raw['profile'] as Map);
      final id = profile['id'];
      if (id is! String ||
          !RegExp(r'^[A-Za-z0-9._-]+$').hasMatch(id) ||
          id == TonometerProfileRepository.builtInId ||
          !ids.add(id)) {
        throw const FormatException('Invalid or duplicate profile id');
      }
      if (profile['name'] is! String ||
          (profile['name'] as String).trim().isEmpty ||
          profile['calibrationReference'] is! Map) {
        throw FormatException('Invalid profile: $id');
      }
      final encoded = raw['referenceBase64'];
      if (encoded is! String) {
        throw FormatException('Missing reference image: $id');
      }
      final bytes = base64Decode(encoded);
      if (bytes.isEmpty) throw FormatException('Empty reference image: $id');
      entries.add(TonometerProfileBackupEntry(profile, bytes));
    }
    return TonometerProfilesBackup(
      entries: entries,
      activeProfileId: root['activeProfileId'] as String?,
    );
  }

  Future<void> share(
    TonometerProfilesBackup backup, {
    required String shareTitle,
    required String subject,
  }) async {
    final directory = await getTemporaryDirectory();
    final now = DateTime.now();
    final date =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final file = File(
      path.join(directory.path, 'tonometer_profiles_$date.json'),
    );
    await file.writeAsString(encode(backup), flush: true);
    await SharePlus.instance.share(
      ShareParams(
        subject: shareTitle,
        text: subject,
        files: [XFile(file.path, mimeType: 'application/json')],
      ),
    );
  }

  Future<void> restore(
    TonometerProfileRepository repository,
    TonometerProfilesBackup backup,
  ) async {
    final previousActive = await repository.getActiveId();
    for (final entry in backup.entries) {
      await repository.saveCustom(
        profile: Map<String, dynamic>.from(entry.profile),
        referenceBytes: entry.referenceBytes,
        makeActive: false,
      );
    }
    final importedIds = backup.entries
        .map((e) => e.profile['id'] as String)
        .toSet();
    final desired = backup.activeProfileId;
    if (desired != null && importedIds.contains(desired)) {
      await repository.setActive(desired);
    } else {
      await repository.setActive(previousActive);
    }
  }
}
