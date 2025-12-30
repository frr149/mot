import 'package:glados/glados.dart';
import 'package:mot/mot.dart';

void main() {
  group('Beacon PBT', () {
    Glados<int>().test(
      'observe/remove sequence does not crash',
      (seed) {
        final beacon = _TestBeacon();
        final observers = List.generate(5, (_) => _TestObserver());

        // Pseudo-random sequence based on seed
        final operations = seed.abs() % 100;
        for (var i = 0; i < operations; i++) {
          final action = (seed + i) % 3;
          final observerIdx = (seed + i) % observers.length;
          final observer = observers[observerIdx];

          switch (action) {
            case 0:
              beacon.observe(observer, (self) => self.callCount++);
            case 1:
              beacon.removeObserver(observer);
            case 2:
              beacon.notifySync();
          }
        }

        // If we get here without exception, test passes
        expect(true, isTrue);
      },
    );

    Glados<int>().test(
      'all live observers are invoked on notify',
      (count) {
        final beacon = _TestBeacon();
        final numObservers = (count.abs() % 10) + 1;
        final observers = <_TestObserver>[];

        for (var i = 0; i < numObservers; i++) {
          final observer = _TestObserver();
          observers.add(observer);
          beacon.observe(observer, (self) => self.callCount++);
        }

        beacon.notifySync();

        // Property: every registered observer should be called exactly once
        for (final observer in observers) {
          expect(
            observer.callCount,
            equals(1),
            reason: 'Each observer should be called once',
          );
        }
      },
    );

    Glados2<int, int>().test(
      'removed observers are never invoked',
      (registerCount, removeCount) {
        final beacon = _TestBeacon();
        final numRegister = (registerCount.abs() % 10) + 1;
        final numRemove = removeCount.abs() % numRegister;
        final observers = <_TestObserver>[];

        // Register observers
        for (var i = 0; i < numRegister; i++) {
          final observer = _TestObserver();
          observers.add(observer);
          beacon.observe(observer, (self) => self.callCount++);
        }

        // Remove some observers
        final removed = <_TestObserver>[];
        for (var i = 0; i < numRemove; i++) {
          final observer = observers[i];
          beacon.removeObserver(observer);
          removed.add(observer);
        }

        beacon.notifySync();

        // Property: removed observers should NOT be called
        for (final observer in removed) {
          expect(
            observer.callCount,
            equals(0),
            reason: 'Removed observers should not be called',
          );
        }

        // Property: remaining observers SHOULD be called
        for (var i = numRemove; i < observers.length; i++) {
          expect(
            observers[i].callCount,
            equals(1),
            reason: 'Non-removed observers should be called',
          );
        }
      },
    );

    Glados<int>().test(
      'hasObserver is consistent with observe/remove',
      (seed) {
        final beacon = _TestBeacon();
        final observer = _TestObserver();

        // Initially not registered
        expect(beacon.hasObserver(observer), isFalse);

        // After observe, should be registered
        beacon.observe(observer, (self) {});
        expect(beacon.hasObserver(observer), isTrue);

        // After remove, should not be registered
        beacon.removeObserver(observer);
        expect(beacon.hasObserver(observer), isFalse);

        // Multiple removes are safe (idempotent)
        beacon.removeObserver(observer);
        expect(beacon.hasObserver(observer), isFalse);
      },
    );
  });
}

class _TestBeacon with Beacon {}

class _TestObserver {
  int callCount = 0;
}
