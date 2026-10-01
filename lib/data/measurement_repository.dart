import 'package:drift/drift.dart';

import '../domain/measurement_draft.dart';
import '../domain/measurement_backup.dart';
import 'app_database.dart';

class MeasurementRepository {
  const MeasurementRepository(this._database);

  final AppDatabase _database;

  Stream<List<Measurement>> watchAll() {
    final query = _database.select(_database.measurements)
      ..orderBy([(row) => OrderingTerm.desc(row.measuredAt)]);
    return query.watch();
  }

  Future<List<Measurement>> getAll() {
    final query = _database.select(_database.measurements)
      ..orderBy([(row) => OrderingTerm.desc(row.measuredAt)]);
    return query.get();
  }

  Future<Map<int, MeasurementSeriesBackup>> getSeriesBackup() async {
    final rows = await _database.select(_database.measurementSeries).get();
    return {
      for (final row in rows)
        row.id: MeasurementSeriesBackup(
          key: row.id.toString(),
          startedAt: row.startedAt,
          completedAt: row.completedAt,
          comment: row.comment,
        ),
    };
  }

  Future<void> restoreBackup(MeasurementBackup backup) {
    return _database.transaction(() async {
      await _database.delete(_database.measurements).go();
      await _database.delete(_database.measurementSeries).go();

      final restoredSeriesIds = <String, int>{};
      for (final series in backup.series.values) {
        restoredSeriesIds[series.key] = await _database
            .into(_database.measurementSeries)
            .insert(
              MeasurementSeriesCompanion.insert(
                startedAt: series.startedAt,
                completedAt: series.completedAt,
                comment: Value(series.comment),
              ),
            );
      }

      for (final measurement in backup.measurements) {
        final seriesKey = measurement.seriesKey;
        await _database
            .into(_database.measurements)
            .insert(
              MeasurementsCompanion.insert(
                systolic: measurement.systolic,
                diastolic: measurement.diastolic,
                pulse: measurement.pulse,
                armSide: Value(measurement.armSide),
                measuredAt: measurement.measuredAt,
                comment: Value(measurement.comment),
                seriesId: Value(
                  seriesKey == null ? null : restoredSeriesIds[seriesKey],
                ),
                sequenceNumber: Value(measurement.sequenceNumber),
                createdAt: Value(measurement.createdAt),
              ),
            );
      }
    });
  }

  Future<int> add(MeasurementDraft draft) {
    return _database
        .into(_database.measurements)
        .insert(
          MeasurementsCompanion.insert(
            systolic: draft.systolic,
            diastolic: draft.diastolic,
            pulse: draft.pulse,
            armSide: Value(draft.arm.code),
            measuredAt: draft.measuredAt,
            comment: Value(draft.comment),
          ),
        );
  }

  Future<int> addSeries(List<MeasurementDraft> drafts, {String? comment}) {
    if (drafts.length < 2 || drafts.length > 3) {
      throw ArgumentError.value(
        drafts.length,
        'drafts',
        'Для серии нужно 2–3 измерения',
      );
    }
    return _database.transaction(() async {
      final seriesId = await _database
          .into(_database.measurementSeries)
          .insert(
            MeasurementSeriesCompanion.insert(
              startedAt: drafts.first.measuredAt,
              completedAt: drafts.last.measuredAt,
              comment: Value(comment),
            ),
          );
      for (var index = 0; index < drafts.length; index++) {
        final draft = drafts[index];
        await _database
            .into(_database.measurements)
            .insert(
              MeasurementsCompanion.insert(
                systolic: draft.systolic,
                diastolic: draft.diastolic,
                pulse: draft.pulse,
                armSide: Value(draft.arm.code),
                measuredAt: draft.measuredAt,
                comment: Value(draft.comment),
                seriesId: Value(seriesId),
                sequenceNumber: Value(index + 1),
              ),
            );
      }
      return seriesId;
    });
  }

  Future<void> createSeriesFromMeasurement(
    int measurementId,
    List<MeasurementDraft> newDrafts, {
    String? comment,
  }) {
    if (newDrafts.isEmpty || newDrafts.length > 2) {
      throw ArgumentError.value(newDrafts.length, 'newDrafts');
    }
    return _database.transaction(() async {
      final existing = await (_database.select(
        _database.measurements,
      )..where((row) => row.id.equals(measurementId))).getSingle();
      if (existing.seriesId != null) {
        throw StateError('Measurement already belongs to a series');
      }
      final allDates = [
        existing.measuredAt,
        ...newDrafts.map((d) => d.measuredAt),
      ]..sort();
      final seriesId = await _database
          .into(_database.measurementSeries)
          .insert(
            MeasurementSeriesCompanion.insert(
              startedAt: allDates.first,
              completedAt: allDates.last,
              comment: Value(comment),
            ),
          );
      await (_database.update(
        _database.measurements,
      )..where((row) => row.id.equals(measurementId))).write(
        MeasurementsCompanion(
          seriesId: Value(seriesId),
          sequenceNumber: const Value(1),
        ),
      );
      await _insertSeriesDrafts(seriesId, newDrafts, firstSequenceNumber: 2);
    });
  }

  Future<void> appendToSeries(
    int seriesId,
    List<MeasurementDraft> newDrafts, {
    String? comment,
  }) {
    if (newDrafts.isEmpty) return Future.value();
    return _database.transaction(() async {
      final existing =
          await (_database.select(_database.measurements)
                ..where((row) => row.seriesId.equals(seriesId))
                ..orderBy([
                  (row) => OrderingTerm.asc(row.sequenceNumber),
                  (row) => OrderingTerm.asc(row.measuredAt),
                ]))
              .get();
      if (existing.isEmpty || existing.length + newDrafts.length > 3) {
        throw StateError('A series must contain two or three measurements');
      }
      final series = await (_database.select(
        _database.measurementSeries,
      )..where((row) => row.id.equals(seriesId))).getSingle();
      final allDates = [
        ...existing.map((m) => m.measuredAt),
        ...newDrafts.map((d) => d.measuredAt),
      ]..sort();
      await (_database.update(
        _database.measurementSeries,
      )..where((row) => row.id.equals(seriesId))).write(
        MeasurementSeriesCompanion(
          startedAt: Value(allDates.first),
          completedAt: Value(allDates.last),
          comment: Value(comment ?? series.comment),
        ),
      );
      await _insertSeriesDrafts(
        seriesId,
        newDrafts,
        firstSequenceNumber: existing.length + 1,
      );
    });
  }

  Future<List<Measurement>> getSeriesMeasurements(int seriesId) {
    final query = _database.select(_database.measurements)
      ..where((row) => row.seriesId.equals(seriesId))
      ..orderBy([
        (row) => OrderingTerm.asc(row.sequenceNumber),
        (row) => OrderingTerm.asc(row.measuredAt),
      ]);
    return query.get();
  }

  Future<String?> getSeriesComment(int seriesId) async {
    final series = await (_database.select(
      _database.measurementSeries,
    )..where((row) => row.id.equals(seriesId))).getSingle();
    return series.comment;
  }

  Future<void> _insertSeriesDrafts(
    int seriesId,
    List<MeasurementDraft> drafts, {
    required int firstSequenceNumber,
  }) async {
    for (var index = 0; index < drafts.length; index++) {
      final draft = drafts[index];
      await _database
          .into(_database.measurements)
          .insert(
            MeasurementsCompanion.insert(
              systolic: draft.systolic,
              diastolic: draft.diastolic,
              pulse: draft.pulse,
              armSide: Value(draft.arm.code),
              measuredAt: draft.measuredAt,
              comment: Value(draft.comment),
              seriesId: Value(seriesId),
              sequenceNumber: Value(firstSequenceNumber + index),
            ),
          );
    }
  }

  Future<int> deleteSeries(int seriesId) {
    return (_database.delete(
      _database.measurementSeries,
    )..where((row) => row.id.equals(seriesId))).go();
  }

  Future<int> updateMeasurement(int id, MeasurementDraft draft) {
    return (_database.update(
      _database.measurements,
    )..where((row) => row.id.equals(id))).write(
      MeasurementsCompanion(
        systolic: Value(draft.systolic),
        diastolic: Value(draft.diastolic),
        pulse: Value(draft.pulse),
        armSide: Value(draft.arm.code),
        measuredAt: Value(draft.measuredAt),
        comment: Value(draft.comment),
      ),
    );
  }

  Future<int> deleteMeasurement(int id) {
    return (_database.delete(
      _database.measurements,
    )..where((row) => row.id.equals(id))).go();
  }

  Future<void> close() => _database.close();
}
