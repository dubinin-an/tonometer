import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../data/app_database.dart';
import '../domain/measurement_backup.dart';

class CsvExportService {
  const CsvExportService();

  static const _version = 2;
  static const _columns = <String>[
    'format_version',
    'date',
    'time',
    'systolic',
    'diastolic',
    'pulse',
    'arm',
    'comment',
    'measured_at',
    'created_at',
    'series_id',
    'series_sequence',
    'series_started_at',
    'series_completed_at',
    'series_comment',
  ];

  Future<void> export(
    List<Measurement> measurements, {
    required Map<int, MeasurementSeriesBackup> series,
    required String shareTitle,
    required String subject,
  }) async {
    final directory = await getTemporaryDirectory();
    final now = DateTime.now();
    final date =
        '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
    final file = File(
      path.join(directory.path, 'tonometer_measurements_$date.csv'),
    );
    await file.writeAsString(encode(measurements, series: series), flush: true);
    await SharePlus.instance.share(
      ShareParams(
        subject: shareTitle,
        text: subject,
        files: [XFile(file.path, mimeType: 'text/csv')],
      ),
    );
  }

  String encode(
    List<Measurement> measurements, {
    Map<int, MeasurementSeriesBackup> series = const {},
  }) {
    final rows = <List<Object?>>[_columns];
    for (final measurement in measurements) {
      final local = measurement.measuredAt.toLocal();
      final seriesId = measurement.seriesId;
      final seriesData = seriesId == null ? null : series[seriesId];
      if (seriesId != null && seriesData == null) {
        throw StateError('Missing metadata for series $seriesId');
      }
      rows.add([
        _version,
        _date(local),
        _time(local),
        measurement.systolic,
        measurement.diastolic,
        measurement.pulse,
        measurement.armSide,
        measurement.comment ?? '',
        measurement.measuredAt.toUtc().toIso8601String(),
        measurement.createdAt.toUtc().toIso8601String(),
        seriesData?.key ?? '',
        measurement.sequenceNumber ?? '',
        seriesData?.startedAt.toUtc().toIso8601String() ?? '',
        seriesData?.completedAt.toUtc().toIso8601String() ?? '',
        seriesData?.comment ?? '',
      ]);
    }
    return '${rows.map((row) => row.map((v) => _escape('$v')).join(',')).join('\r\n')}\r\n';
  }

  MeasurementBackup decodeBytes(Uint8List bytes) => decode(utf8.decode(bytes));

  MeasurementBackup decode(String source) {
    final rows = _parseCsv(source);
    if (rows.length < 2) {
      throw const FormatException('CSV contains no measurements');
    }
    final header = rows.first.map((v) => v.trim().toLowerCase()).toList();
    final indexes = {for (var i = 0; i < header.length; i++) header[i]: i};
    for (final required in ['date', 'time', 'systolic', 'diastolic', 'pulse']) {
      if (!indexes.containsKey(required)) {
        throw FormatException('Missing column: $required');
      }
    }
    String value(List<String> row, String name) {
      final index = indexes[name];
      return index == null || index >= row.length ? '' : row[index].trim();
    }

    final measurements = <MeasurementBackupEntry>[];
    final series = <String, MeasurementSeriesBackup>{};
    for (var rowNumber = 1; rowNumber < rows.length; rowNumber++) {
      final row = rows[rowNumber];
      if (row.every((v) => v.trim().isEmpty)) continue;
      try {
        final systolic = _bounded(value(row, 'systolic'), 40, 300, 'systolic');
        final diastolic = _bounded(
          value(row, 'diastolic'),
          20,
          200,
          'diastolic',
        );
        final pulse = _bounded(value(row, 'pulse'), 25, 250, 'pulse');
        final arm = value(row, 'arm').toUpperCase();
        if (arm.isNotEmpty && arm != 'L' && arm != 'R') {
          throw const FormatException('arm must be L or R');
        }
        final measuredAt = value(row, 'measured_at').isNotEmpty
            ? DateTime.parse(value(row, 'measured_at'))
            : DateTime.parse('${value(row, 'date')}T${value(row, 'time')}:00');
        final createdText = value(row, 'created_at');
        final createdAt = createdText.isEmpty
            ? measuredAt
            : DateTime.parse(createdText);
        final seriesKey = value(row, 'series_id');
        final sequenceText = value(row, 'series_sequence');
        if (seriesKey.isEmpty != sequenceText.isEmpty) {
          throw const FormatException(
            'series_id and series_sequence must be set together',
          );
        }
        final sequence = sequenceText.isEmpty ? null : int.parse(sequenceText);
        if (sequence != null && (sequence < 1 || sequence > 3)) {
          throw const FormatException('series_sequence must be 1..3');
        }
        measurements.add(
          MeasurementBackupEntry(
            systolic: systolic,
            diastolic: diastolic,
            pulse: pulse,
            armSide: arm.isEmpty ? 'L' : arm,
            measuredAt: measuredAt,
            createdAt: createdAt,
            comment: _nullable(value(row, 'comment')),
            seriesKey: _nullable(seriesKey),
            sequenceNumber: sequence,
          ),
        );
        if (seriesKey.isNotEmpty) {
          final candidate = MeasurementSeriesBackup(
            key: seriesKey,
            startedAt:
                _optionalDate(value(row, 'series_started_at')) ?? measuredAt,
            completedAt:
                _optionalDate(value(row, 'series_completed_at')) ?? measuredAt,
            comment: _nullable(value(row, 'series_comment')),
          );
          final existing = series[seriesKey];
          if (existing != null && !_sameSeries(existing, candidate)) {
            throw FormatException('Conflicting metadata for series $seriesKey');
          }
          series[seriesKey] = candidate;
        }
      } catch (error) {
        throw FormatException('Row ${rowNumber + 1}: $error');
      }
    }
    if (measurements.isEmpty) {
      throw const FormatException('CSV contains no measurements');
    }
    for (final key in series.keys) {
      final entries = measurements.where((m) => m.seriesKey == key).toList();
      if (entries.length < 2 || entries.length > 3) {
        throw FormatException('Series $key must contain 2 or 3 measurements');
      }
      final sequences = entries.map((e) => e.sequenceNumber).toList()..sort();
      for (var i = 0; i < sequences.length; i++) {
        if (sequences[i] != i + 1) {
          throw FormatException('Invalid sequence in series $key');
        }
      }
    }
    return MeasurementBackup(measurements: measurements, series: series);
  }

  static int _bounded(String source, int min, int max, String name) {
    final value = int.parse(source);
    if (value < min || value > max) {
      throw FormatException('$name is out of range');
    }
    return value;
  }

  static bool _sameSeries(
    MeasurementSeriesBackup a,
    MeasurementSeriesBackup b,
  ) =>
      a.startedAt.toUtc() == b.startedAt.toUtc() &&
      a.completedAt.toUtc() == b.completedAt.toUtc() &&
      a.comment == b.comment;

  static DateTime? _optionalDate(String value) =>
      value.isEmpty ? null : DateTime.parse(value);
  static String? _nullable(String value) => value.isEmpty ? null : value;
  static String _date(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
  static String _time(DateTime value) =>
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  static String _escape(String value) => '"${value.replaceAll('"', '""')}"';

  static List<List<String>> _parseCsv(String source) {
    final rows = <List<String>>[];
    var row = <String>[];
    var field = StringBuffer();
    var quoted = false;
    for (var i = 0; i < source.length; i++) {
      final char = source[i];
      if (quoted) {
        if (char == '"') {
          if (i + 1 < source.length && source[i + 1] == '"') {
            field.write('"');
            i++;
          } else {
            quoted = false;
          }
        } else {
          field.write(char);
        }
      } else if (char == '"') {
        quoted = true;
      } else if (char == ',') {
        row.add(field.toString());
        field = StringBuffer();
      } else if (char == '\n' || char == '\r') {
        if (char == '\r' && i + 1 < source.length && source[i + 1] == '\n') i++;
        row.add(field.toString());
        rows.add(row);
        row = <String>[];
        field = StringBuffer();
      } else {
        field.write(char);
      }
    }
    if (quoted) throw const FormatException('Unclosed quoted field');
    if (field.isNotEmpty || row.isNotEmpty) {
      row.add(field.toString());
      rows.add(row);
    }
    if (rows.isNotEmpty && rows.first.isNotEmpty) {
      rows.first[0] = rows.first[0].replaceFirst('\ufeff', '');
    }
    return rows;
  }
}
