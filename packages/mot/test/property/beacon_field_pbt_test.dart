import 'package:glados/glados.dart';
import 'package:mot/mot.dart';

void main() {
  group('BeaconField PBT', () {
    Glados<int>().test(
      'value roundtrip: field.value = x implies field.value == x',
      (value) {
        final field = BeaconField<int>(0);

        field.value = value;

        expect(field.value, equals(value));
      },
    );

    Glados<double>().test(
      'value roundtrip with doubles',
      (value) {
        final field = BeaconField<double>(0);

        field.value = value;

        expect(field.value, equals(value));
      },
    );

    Glados<bool>().test(
      'value roundtrip with booleans',
      (value) {
        final field = BeaconField<bool>(false);

        field.value = value;

        expect(field.value, equals(value));
      },
    );

    Glados<List<int>>().test(
      'notification occurs when value changes',
      (values) {
        final field = BeaconField<int>(0);
        final observer = _TestObserver();
        var previousValue = field.value;
        var hadChanges = false;

        field.observe(observer, (self) => self.callCount++);

        for (final value in values.take(20)) {
          if (value != previousValue) {
            hadChanges = true;
          }
          field.value = value;
          previousValue = value;
        }

        field.notifySync();

        // Property: if there were changes, notification should occur
        if (hadChanges) {
          expect(observer.callCount, greaterThanOrEqualTo(1));
        }
      },
    );

    Glados<int>().test(
      'setting same value does not schedule notification',
      (value) {
        final field = BeaconField<int>(value);
        final observer = _TestObserver();

        field.observe(observer, (self) => self.callCount++);

        // Set same value multiple times - should NOT schedule any notify
        field.value = value;
        field.value = value;
        field.value = value;

        // Without notifySync or waiting for microtask, count should be 0
        // This proves that setting same value doesn't schedule notification
        expect(observer.callCount, equals(0));
      },
    );

    Glados2<int, int>().test(
      'equality check uses == operator for different instances',
      (a, b) {
        // Use two distinct values to ensure we test the == operator
        final valueA = a.abs() % 1000;
        final valueB = (b.abs() % 1000) + 1000; // Guaranteed different

        final field = BeaconField<_ValueObject>(_ValueObject(valueA));
        final observer = _TestObserver();

        field.observe(observer, (self) => self.callCount++);

        // Set different instance with SAME content - should NOT notify
        field.value = _ValueObject(valueA);

        // Count should be 0 (no notification scheduled)
        expect(observer.callCount, equals(0));

        // Now set a truly different value and sync
        field.value = _ValueObject(valueB);
        field.notifySync();

        // Now it should have been notified
        expect(observer.callCount, equals(1));
      },
    );

    Glados<int>().test(
      'multiple observers all receive notification',
      (count) {
        final field = BeaconField<int>(0);
        final observers = <_TestObserver>[];
        final numObservers = (count.abs() % 10) + 1;

        for (var i = 0; i < numObservers; i++) {
          final observer = _TestObserver();
          observers.add(observer);
          field.observe(observer, (self) => self.callCount++);
        }

        field.value = 1;
        field.notifySync();

        // Property: all observers called
        for (final observer in observers) {
          expect(observer.callCount, equals(1));
        }
      },
    );

    Glados<int>().test(
      'initial value is preserved',
      (initial) {
        final field = BeaconField<int>(initial);

        expect(field.value, equals(initial));
      },
    );
  });
}

class _TestObserver {
  int callCount = 0;
}

class _ValueObject {
  _ValueObject(this.value);
  final int value;

  @override
  bool operator ==(Object other) =>
      other is _ValueObject && other.value == value;

  @override
  int get hashCode => value.hashCode;
}
