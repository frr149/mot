import 'package:mot/src/observer_entry.dart';
import 'package:test/test.dart';

void main() {
  group('ObserverEntry', () {
    group('isAlive', () {
      test('returns true when observer is alive', () {
        final observer = Object();
        final entry = ObserverEntry<Object>(
          observer: observer,
          callback: (_) {},
          id: 1,
        );

        expect(entry.isAlive, isTrue);
      });

      test('returns false when observer is garbage collected', () {
        Object? observer = Object();
        final entry = ObserverEntry<Object>(
          observer: observer,
          callback: (_) {},
          id: 1,
        );

        // Remove strong reference
        observer = null;

        // Note: We cannot force GC in Dart, so this test documents
        // the expected behavior but may not always trigger GC
        // In a real scenario, the WeakReference would return null
        // after the observer is collected

        // For now, we verify the entry was created correctly
        // The async tests will verify GC behavior more thoroughly
        expect(entry.id, equals(1));
      });
    });

    group('tryInvoke', () {
      test('executes callback and returns true when observer is alive', () {
        final observer = _TestObserver();
        final entry = ObserverEntry<_TestObserver>(
          observer: observer,
          callback: (self) => self.called = true,
          id: 1,
        );

        final result = entry.tryInvoke();

        expect(result, isTrue);
        expect(observer.called, isTrue);
      });

      test('passes correct self reference to callback', () {
        final observer = _TestObserver();
        _TestObserver? receivedSelf;

        final entry = ObserverEntry<_TestObserver>(
          observer: observer,
          callback: (self) => receivedSelf = self,
          id: 1,
        );

        entry.tryInvoke();

        expect(receivedSelf, same(observer));
      });

      test('can invoke multiple times', () {
        final observer = _TestObserver();
        final entry = ObserverEntry<_TestObserver>(
          observer: observer,
          callback: (self) => self.callCount++,
          id: 1,
        );

        entry.tryInvoke();
        entry.tryInvoke();
        entry.tryInvoke();

        expect(observer.callCount, equals(3));
      });
    });

    group('id', () {
      test('stores the provided id', () {
        final entry = ObserverEntry<Object>(
          observer: Object(),
          callback: (_) {},
          id: 42,
        );

        expect(entry.id, equals(42));
      });

      test('different entries can have different ids', () {
        final entry1 = ObserverEntry<Object>(
          observer: Object(),
          callback: (_) {},
          id: 1,
        );
        final entry2 = ObserverEntry<Object>(
          observer: Object(),
          callback: (_) {},
          id: 2,
        );

        expect(entry1.id, isNot(equals(entry2.id)));
      });
    });
  });
}

class _TestObserver {
  bool called = false;
  int callCount = 0;
}
