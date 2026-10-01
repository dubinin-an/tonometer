import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonometer_mvp/data/app_database.dart';
import 'package:tonometer_mvp/data/measurement_repository.dart';
import 'package:tonometer_mvp/domain/measurement_draft.dart';

void main() {
  late AppDatabase database;
  late MeasurementRepository repository;

  setUp(() {
    database = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    repository = MeasurementRepository(database);
  });

  tearDown(() => database.close());

  test('stores and returns newest measurements first', () async {
    await repository.add(
      MeasurementDraft(
        systolic: 120,
        diastolic: 80,
        pulse: 70,
        measuredAt: DateTime(2026, 8, 16, 10),
      ),
    );
    await repository.add(
      MeasurementDraft(
        systolic: 143,
        diastolic: 90,
        pulse: 90,
        measuredAt: DateTime(2026, 8, 17, 10),
        comment: 'После прогулки',
      ),
    );

    final rows = await repository.getAll();

    expect(rows.map((row) => row.systolic), [143, 120]);
    expect(rows.first.comment, 'После прогулки');
  });

  test('stores a complete series atomically with sequence numbers', () async {
    final seriesId = await repository.addSeries([
      MeasurementDraft(
        systolic: 143,
        diastolic: 90,
        pulse: 90,
        measuredAt: DateTime(2026, 8, 18, 8, 10),
      ),
      MeasurementDraft(
        systolic: 138,
        diastolic: 87,
        pulse: 84,
        measuredAt: DateTime(2026, 8, 18, 8, 13),
      ),
    ]);

    final rows = await repository.getAll();
    expect(rows, hasLength(2));
    expect(rows.every((row) => row.seriesId == seriesId), isTrue);
    expect(rows.map((row) => row.sequenceNumber).toSet(), {1, 2});

    await repository.deleteSeries(seriesId);
    expect(await repository.getAll(), isEmpty);
  });

  test('rejects a series with fewer than two measurements', () async {
    expect(
      () => repository.addSeries([
        MeasurementDraft(
          systolic: 120,
          diastolic: 80,
          pulse: 70,
          measuredAt: DateTime(2026, 8, 18),
        ),
      ]),
      throwsArgumentError,
    );
  });

  test('converts an existing measurement into a series', () async {
    final firstId = await repository.add(
      MeasurementDraft(
        systolic: 140,
        diastolic: 90,
        pulse: 80,
        measuredAt: DateTime(2026, 8, 18, 8),
      ),
    );

    await repository.createSeriesFromMeasurement(firstId, [
      MeasurementDraft(
        systolic: 135,
        diastolic: 86,
        pulse: 76,
        measuredAt: DateTime(2026, 8, 18, 8, 5),
      ),
    ]);

    final rows = await repository.getAll();
    expect(rows, hasLength(2));
    expect(rows.map((row) => row.id), contains(firstId));
    expect(rows.map((row) => row.seriesId).toSet(), hasLength(1));
    expect(rows.map((row) => row.sequenceNumber).toSet(), {1, 2});
  });

  test('appends a measurement to an existing series', () async {
    final seriesId = await repository.addSeries([
      MeasurementDraft(
        systolic: 140,
        diastolic: 90,
        pulse: 80,
        measuredAt: DateTime(2026, 8, 18, 8),
      ),
      MeasurementDraft(
        systolic: 135,
        diastolic: 86,
        pulse: 76,
        measuredAt: DateTime(2026, 8, 18, 8, 5),
      ),
    ]);

    await repository.appendToSeries(seriesId, [
      MeasurementDraft(
        systolic: 132,
        diastolic: 84,
        pulse: 74,
        measuredAt: DateTime(2026, 8, 18, 8, 10),
      ),
    ]);

    final rows = await repository.getSeriesMeasurements(seriesId);
    expect(rows, hasLength(3));
    expect(rows.map((row) => row.sequenceNumber), [1, 2, 3]);
  });
}
