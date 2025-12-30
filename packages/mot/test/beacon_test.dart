import 'dart:async';

import 'package:mot/mot.dart';
import 'package:test/test.dart';

void main() {
  group('Beacon (sync)', () {
    group('observe', () {
      test('registers an observer', () {
        final beacon = _TestBeacon();
        final observer = _TestObserver();

        beacon.observe(observer, (self) => self.called = true);

        expect(beacon.hasObserver(observer), isTrue);
      });

      test('allows multiple observers', () {
        final beacon = _TestBeacon();
        final observer1 = _TestObserver();
        final observer2 = _TestObserver();

        beacon.observe(observer1, (self) => self.called = true);
        beacon.observe(observer2, (self) => self.called = true);

        expect(beacon.hasObserver(observer1), isTrue);
        expect(beacon.hasObserver(observer2), isTrue);
      });

      test('same observer can only be registered once per callback', () {
        final beacon = _TestBeacon();
        final observer = _TestObserver();

        beacon.observe(observer, (self) => self.callCount++);
        beacon.observe(observer, (self) => self.callCount++);

        beacon.notifySync();

        // Both callbacks are registered (different callback instances)
        expect(observer.callCount, equals(2));
      });
    });

    group('removeObserver', () {
      test('removes an observer', () {
        final beacon = _TestBeacon();
        final observer = _TestObserver();

        beacon.observe(observer, (self) => self.called = true);
        beacon.removeObserver(observer);

        expect(beacon.hasObserver(observer), isFalse);
      });

      test('removed observer is not notified', () {
        final beacon = _TestBeacon();
        final observer = _TestObserver();

        beacon.observe(observer, (self) => self.called = true);
        beacon.removeObserver(observer);
        beacon.notifySync();

        expect(observer.called, isFalse);
      });

      test('removing non-existent observer does nothing', () {
        final beacon = _TestBeacon();
        final observer = _TestObserver();

        // Should not throw
        beacon.removeObserver(observer);

        expect(beacon.hasObserver(observer), isFalse);
      });
    });

    group('hasObserver', () {
      test('returns false for unregistered observer', () {
        final beacon = _TestBeacon();
        final observer = _TestObserver();

        expect(beacon.hasObserver(observer), isFalse);
      });

      test('returns true for registered observer', () {
        final beacon = _TestBeacon();
        final observer = _TestObserver();

        beacon.observe(observer, (self) {});

        expect(beacon.hasObserver(observer), isTrue);
      });

      test('returns false after observer is removed', () {
        final beacon = _TestBeacon();
        final observer = _TestObserver();

        beacon.observe(observer, (self) {});
        beacon.removeObserver(observer);

        expect(beacon.hasObserver(observer), isFalse);
      });
    });

    group('notifySync', () {
      test('invokes callback with correct self reference', () {
        final beacon = _TestBeacon();
        final observer = _TestObserver();
        _TestObserver? receivedSelf;

        beacon.observe(observer, (self) => receivedSelf = self);
        beacon.notifySync();

        expect(receivedSelf, same(observer));
      });

      test('invokes all registered observers', () {
        final beacon = _TestBeacon();
        final observer1 = _TestObserver();
        final observer2 = _TestObserver();
        final observer3 = _TestObserver();

        beacon.observe(observer1, (self) => self.called = true);
        beacon.observe(observer2, (self) => self.called = true);
        beacon.observe(observer3, (self) => self.called = true);

        beacon.notifySync();

        expect(observer1.called, isTrue);
        expect(observer2.called, isTrue);
        expect(observer3.called, isTrue);
      });

      test('can be called multiple times', () {
        final beacon = _TestBeacon();
        final observer = _TestObserver();

        beacon.observe(observer, (self) => self.callCount++);

        beacon.notifySync();
        beacon.notifySync();
        beacon.notifySync();

        expect(observer.callCount, equals(3));
      });
    });

    group('error handling', () {
      test('one failing callback does not stop others', () {
        final beacon = _TestBeacon();
        final observer1 = _TestObserver();
        final observer2 = _TestObserver();
        final observer3 = _TestObserver();

        beacon.observe(observer1, (self) => self.called = true);
        beacon.observe(observer2, (self) => throw Exception('Test error'));
        beacon.observe(observer3, (self) => self.called = true);

        // Capture errors via Zone
        final errors = <Object>[];
        runZonedGuarded(
          beacon.notifySync,
          (error, stack) => errors.add(error),
        );

        expect(observer1.called, isTrue);
        expect(observer3.called, isTrue);
        expect(errors, hasLength(1));
      });

      test('error is reported via Zone.handleUncaughtError', () {
        final beacon = _TestBeacon();
        final observer = _TestObserver();
        final testError = Exception('Test error');

        beacon.observe(observer, (self) => throw testError);

        Object? capturedError;
        runZonedGuarded(
          beacon.notifySync,
          (error, stack) => capturedError = error,
        );

        expect(capturedError, same(testError));
      });

      test('multiple errors are all reported', () {
        final beacon = _TestBeacon();
        final observer1 = _TestObserver();
        final observer2 = _TestObserver();

        beacon.observe(observer1, (self) => throw Exception('Error 1'));
        beacon.observe(observer2, (self) => throw Exception('Error 2'));

        final errors = <Object>[];
        runZonedGuarded(
          beacon.notifySync,
          (error, stack) => errors.add(error),
        );

        expect(errors, hasLength(2));
      });
    });
  });
}

class _TestBeacon with Beacon {}

class _TestObserver {
  bool called = false;
  int callCount = 0;
}
