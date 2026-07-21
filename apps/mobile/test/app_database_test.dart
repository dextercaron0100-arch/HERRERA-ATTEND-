import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geoattend_employee/core/database/app_database.dart';

void main() {
  test('offline attendance queue is durable and idempotent', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);

    await database.enqueue('event-1', '{"kind":"CLOCK_IN"}');
    await database.enqueue('event-1', '{"kind":"CLOCK_IN"}');
    expect(await database.pending(), hasLength(1));

    await database.markAttempt('event-1', 'offline');
    expect((await database.pending()).single.lastError, 'offline');

    await database.removePending('event-1');
    expect(await database.pending(), isEmpty);
  });
}
