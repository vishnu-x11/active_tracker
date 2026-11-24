import 'package:active_tracker/features/running/domain/use_cases/speed_window.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('pace needs a few readings before it shows', () {
    final w = SpeedWindow()
      ..add(0, 3)
      ..add(1000, 3);
    expect(w.value(1000), isNull);
    w.add(2000, 3);
    expect(w.value(2000), 3);
  });

  test('a single spike barely moves the speed', () {
    final w = SpeedWindow();
    for (var i = 0; i < 10; i++) {
      w.add(i * 1000, i == 5 ? 9 : 2.7);
    }
    expect(w.value(9000), closeTo(2.7, 0.01));
  });

  test('old readings drop out of the window, and clear empties it', () {
    final w = SpeedWindow();
    for (var i = 0; i < 12; i++) {
      w.add(i * 1000, 2);
    }
    for (var i = 12; i < 25; i++) {
      w.add(i * 1000, 3);
    }
    expect(w.value(24000), 3);
    expect(w.value(40000), isNull);
    w
      ..add(41000, 2)
      ..add(42000, 2)
      ..add(43000, 2)
      ..clear();
    expect(w.value(43000), isNull);
  });
}
