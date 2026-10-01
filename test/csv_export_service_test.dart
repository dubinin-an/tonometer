import 'package:flutter_test/flutter_test.dart';
import 'package:tonometer_mvp/data/app_database.dart';
import 'package:tonometer_mvp/domain/measurement_backup.dart';
import 'package:tonometer_mvp/services/csv_export_service.dart';

void main() {
  test('encodes stable CSV and escapes comments', () {
    final measuredAt = DateTime(2026, 8, 17, 9, 5);
    final csv = const CsvExportService().encode([
      Measurement(
        id: 1,
        systolic: 143,
        diastolic: 90,
        pulse: 90,
        armSide: 'R',
        measuredAt: measuredAt,
        comment: 'После еды, "спокойно"',
        createdAt: measuredAt,
      ),
    ]);

    expect(csv, contains('format_version'));
    expect(csv, contains('"143","90","90","R"'));
    expect(csv, contains('"После еды, ""спокойно"""'));
  });

  test('round-trips a complete measurement series', () {
    final first = DateTime.utc(2026, 8, 17, 9, 5);
    final measurements = [
      Measurement(
        id: 1,
        systolic: 143,
        diastolic: 90,
        pulse: 90,
        armSide: 'L',
        measuredAt: first,
        comment: 'first\nline',
        seriesId: 7,
        sequenceNumber: 1,
        createdAt: first,
      ),
      Measurement(
        id: 2,
        systolic: 139,
        diastolic: 88,
        pulse: 87,
        armSide: 'R',
        measuredAt: first.add(const Duration(minutes: 2)),
        seriesId: 7,
        sequenceNumber: 2,
        createdAt: first,
      ),
    ];
    final service = const CsvExportService();
    final decoded = service.decode(
      service.encode(
        measurements,
        series: {
          7: MeasurementSeriesBackup(
            key: '7',
            startedAt: first,
            completedAt: first.add(const Duration(minutes: 2)),
            comment: 'series',
          ),
        },
      ),
    );
    expect(decoded.measurements, hasLength(2));
    expect(decoded.series, hasLength(1));
    expect(decoded.measurements.first.comment, 'first\nline');
    expect(decoded.measurements.last.sequenceNumber, 2);
    expect(decoded.series['7']?.comment, 'series');
  });

  test('imports legacy CSV as standalone measurements', () {
    const csv =
        'date,time,systolic,diastolic,pulse,arm,comment\r\n'
        '"2026-08-17","09:05","143","90","88","L","legacy"\r\n';
    final decoded = const CsvExportService().decode(csv);
    expect(decoded.measurements.single.systolic, 143);
    expect(decoded.measurements.single.seriesKey, isNull);
    expect(decoded.series, isEmpty);
  });
}
