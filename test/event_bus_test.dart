
import 'package:flutter_test/flutter_test.dart';
import 'package:debug_console_overlay/src/event_bus.dart';
import 'package:debug_console_overlay/src/models.dart';

void main() {
  test('event bus stores and streams logs', () async {
    final bus = DebugBus.instance;
    final events = <LogEvent>[];
    final sub = bus.logsStream.listen(events.add);

    final e = LogEvent(DateTime.now(), LogLevel.info, 'hello');
    bus.addLog(e);

    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(bus.logsSnapshot.isNotEmpty, true);
    expect(events.contains(e), true);
    await sub.cancel();
  });
}
