import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

class MeasurementSeries extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get completedAt => dateTime()();
  TextColumn get comment => text().nullable()();
}

@TableIndex(name: 'measurements_series_id', columns: {#seriesId})
class Measurements extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get systolic => integer()();
  IntColumn get diastolic => integer()();
  IntColumn get pulse => integer()();
  TextColumn get armSide => text()
      .withDefault(const Constant('L'))
      .check(const CustomExpression<bool>("arm_side IN ('L', 'R')"))();
  DateTimeColumn get measuredAt => dateTime()();
  TextColumn get comment => text().nullable()();
  IntColumn get seriesId => integer().nullable().references(
    MeasurementSeries,
    #id,
    onDelete: KeyAction.cascade,
  )();
  IntColumn get sequenceNumber => integer().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Reminders extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get hour =>
      integer().check(const CustomExpression<bool>('hour BETWEEN 0 AND 23'))();
  IntColumn get minute => integer().check(
    const CustomExpression<bool>('minute BETWEEN 0 AND 59'),
  )();
  IntColumn get weekdaysMask => integer().check(
    const CustomExpression<bool>('weekdays_mask BETWEEN 1 AND 127'),
  )();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(tables: [Measurements, Reminders, MeasurementSeries])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) => migrator.createAll(),
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.createTable(reminders);
      }
      if (from < 3) {
        await migrator.createTable(measurementSeries);
        await migrator.addColumn(measurements, measurements.seriesId);
        await migrator.addColumn(measurements, measurements.sequenceNumber);
        await customStatement(
          'CREATE INDEX measurements_series_id '
          'ON measurements (series_id)',
        );
      }
      if (from < 4) {
        await migrator.addColumn(measurements, measurements.armSide);
      }
    },
    beforeOpen: (_) => customStatement('PRAGMA foreign_keys = ON'),
  );

  static QueryExecutor _openConnection() {
    return LazyDatabase(() async {
      final directory = await getApplicationDocumentsDirectory();
      final file = File(path.join(directory.path, 'tonometer.sqlite'));
      return NativeDatabase.createInBackground(file);
    });
  }
}
