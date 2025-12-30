import 'beacon.dart';

/// An observable field that notifies observers when its value changes.
///
/// [BeaconField] is the minimal unit for fine-grained reactivity. It stores
/// a value and notifies all observers when the value changes.
///
/// ## Example
///
/// ```dart
/// class UserModel {
///   final name = BeaconField<String>('');
///   final age = BeaconField<int>(0);
/// }
///
/// // Observe a specific field
/// user.name.observe(this, (self) => self.setState(() {}));
///
/// // Change triggers notification
/// user.name.value = 'Alice';  // → observers notified
/// ```
///
/// ## Equality Check
///
/// Notifications only occur when the new value is different from the old
/// value (using `==` comparison). Setting the same value is a no-op.
///
/// ```dart
/// field.value = 'hello';  // notifies
/// field.value = 'hello';  // no-op, same value
/// ```
class BeaconField<T> with Beacon {
  /// Creates a beacon field with an initial value.
  BeaconField(this._value);

  T _value;

  /// The current value of this field.
  T get value => _value;

  /// Sets the value and notifies observers if it changed.
  ///
  /// If the new value equals the current value (via `==`), this is a no-op
  /// and no notification is sent.
  set value(T newValue) {
    if (newValue == _value) return;
    _value = newValue;
    notify();
  }
}
