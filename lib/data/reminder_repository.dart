import 'package:drift/drift.dart';

import '../domain/reminder_draft.dart';
import 'app_database.dart';

class ReminderRepository {
  const ReminderRepository(this._database);

  final AppDatabase _database;

  Stream<List<Reminder>> watchAll() {
    final query = _database.select(_database.reminders)
      ..orderBy([
        (row) => OrderingTerm.asc(row.hour),
        (row) => OrderingTerm.asc(row.minute),
      ]);
    return query.watch();
  }

  Future<List<Reminder>> getAll() {
    final query = _database.select(_database.reminders)
      ..orderBy([
        (row) => OrderingTerm.asc(row.hour),
        (row) => OrderingTerm.asc(row.minute),
      ]);
    return query.get();
  }

  Future<Reminder> getById(int id) {
    return (_database.select(
      _database.reminders,
    )..where((row) => row.id.equals(id))).getSingle();
  }

  Future<int> add(ReminderDraft draft) {
    return _database
        .into(_database.reminders)
        .insert(
          RemindersCompanion.insert(
            hour: draft.hour,
            minute: draft.minute,
            weekdaysMask: draft.weekdaysMask,
            enabled: Value(draft.enabled),
          ),
        );
  }

  Future<int> updateReminder(int id, ReminderDraft draft) {
    return (_database.update(
      _database.reminders,
    )..where((row) => row.id.equals(id))).write(
      RemindersCompanion(
        hour: Value(draft.hour),
        minute: Value(draft.minute),
        weekdaysMask: Value(draft.weekdaysMask),
        enabled: Value(draft.enabled),
      ),
    );
  }

  Future<int> setEnabled(int id, bool enabled) {
    return (_database.update(_database.reminders)
          ..where((row) => row.id.equals(id)))
        .write(RemindersCompanion(enabled: Value(enabled)));
  }

  Future<int> deleteReminder(int id) {
    return (_database.delete(
      _database.reminders,
    )..where((row) => row.id.equals(id))).go();
  }
}
