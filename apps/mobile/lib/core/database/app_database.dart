import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

class PendingAttendanceEvents extends Table {
  TextColumn get idempotencyKey => text()();
  TextColumn get payload => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {idempotencyKey};
}

@DriftDatabase(tables: [PendingAttendanceEvents])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  Future<void> enqueue(String idempotencyKey, String payload) =>
      into(pendingAttendanceEvents).insert(
        PendingAttendanceEventsCompanion.insert(
            idempotencyKey: idempotencyKey, payload: payload),
        mode: InsertMode.insertOrIgnore,
      );

  Future<List<PendingAttendanceEvent>> pending() =>
      (select(pendingAttendanceEvents)
            ..orderBy([(row) => OrderingTerm.asc(row.createdAt)]))
          .get();

  Future<void> markAttempt(String idempotencyKey, String error) =>
      (update(pendingAttendanceEvents)
            ..where((row) => row.idempotencyKey.equals(idempotencyKey)))
          .write(
        PendingAttendanceEventsCompanion(
            attempts: const Value.absent(), lastError: Value(error)),
      );

  Future<void> removePending(String idempotencyKey) =>
      (delete(pendingAttendanceEvents)
            ..where((row) => row.idempotencyKey.equals(idempotencyKey)))
          .go();
}

LazyDatabase _openConnection() => LazyDatabase(() async {
      final directory = await getApplicationDocumentsDirectory();
      return NativeDatabase.createInBackground(
          File(p.join(directory.path, 'geoattend.sqlite')));
    });
