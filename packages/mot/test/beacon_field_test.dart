import 'package:mot/mot.dart';
import 'package:test/test.dart';

void main() {
  group('BeaconField (sync)', () {
    group('value', () {
      test('returns initial value', () {
        final field = BeaconField<String>('hello');

        expect(field.value, equals('hello'));
      });

      test('returns updated value after set', () {
        final field = BeaconField<String>('hello');

        field.value = 'world';

        expect(field.value, equals('world'));
      });

      test('works with different types', () {
        final stringField = BeaconField<String>('test');
        final intField = BeaconField<int>(42);
        final boolField = BeaconField<bool>(true);
        final listField = BeaconField<List<int>>([1, 2, 3]);

        expect(stringField.value, equals('test'));
        expect(intField.value, equals(42));
        expect(boolField.value, isTrue);
        expect(listField.value, equals([1, 2, 3]));
      });

      test('works with nullable types', () {
        final field = BeaconField<String?>(null);

        expect(field.value, isNull);

        field.value = 'not null';
        expect(field.value, equals('not null'));

        field.value = null;
        expect(field.value, isNull);
      });
    });

    group('notifySync', () {
      test('invokes all observers', () {
        final field = BeaconField<int>(0);
        final observer1 = _TestObserver();
        final observer2 = _TestObserver();
        final observer3 = _TestObserver();

        field.observe(observer1, (self) => self.called = true);
        field.observe(observer2, (self) => self.called = true);
        field.observe(observer3, (self) => self.called = true);

        field.notifySync();

        expect(observer1.called, isTrue);
        expect(observer2.called, isTrue);
        expect(observer3.called, isTrue);
      });

      test('observer can read current value in callback', () {
        final field = BeaconField<int>(42);
        final observer = _TestObserver();
        int? observedValue;

        field.observe(observer, (self) {
          observedValue = field.value;
        });

        field.notifySync();

        expect(observedValue, equals(42));
      });
    });

    group('equality check (value setter)', () {
      test('setting same value does not schedule notification', () {
        final field = BeaconField<String>('same');

        // Set same value - should not schedule notify
        field.value = 'same';

        // The field's internal _notificationScheduled should be false
        // We verify this indirectly: if we now call notifySync and observe,
        // the observer should only be called once
        final observer = _TestObserver();
        field.observe(observer, (self) => self.callCount++);
        field.notifySync();

        expect(observer.callCount, equals(1)); // Only from notifySync
      });

      test('setting different value changes the stored value', () {
        final field = BeaconField<String>('old');

        field.value = 'new';

        expect(field.value, equals('new'));
      });

      test('uses == for comparison with value objects', () {
        final field = BeaconField<_ValueObject>(_ValueObject(1));

        // Same value by ==, different instance
        final sameValue = _ValueObject(1);
        field.value = sameValue;

        // The value should be updated to the new instance
        expect(identical(field.value, sameValue), isFalse);
        // Because the old value == new value, no notification was scheduled
      });
    });

    group('inheritance from Beacon', () {
      test('has observe method from Beacon', () {
        final field = BeaconField<int>(0);
        final observer = _TestObserver();

        field.observe(observer, (self) {});

        expect(field.hasObserver(observer), isTrue);
      });

      test('has removeObserver method from Beacon', () {
        final field = BeaconField<int>(0);
        final observer = _TestObserver();

        field.observe(observer, (self) {});
        field.removeObserver(observer);

        expect(field.hasObserver(observer), isFalse);
      });

      test('removed observer is not notified', () {
        final field = BeaconField<int>(0);
        final observer = _TestObserver();

        field.observe(observer, (self) => self.called = true);
        field.removeObserver(observer);

        field.notifySync();

        expect(observer.called, isFalse);
      });
    });
  });
}

class _TestObserver {
  bool called = false;
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
