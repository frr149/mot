/// MOT - Multitude of Triads
///
/// A sober and efficient alternative to state management in Dart and Flutter.
///
/// The domain lives outside the tree. The UI observes it.
///
/// ## Core Principle
///
/// > "Simplicity of interface over simplicity of implementation"
///
/// MOT must be invisible. Subscribe and forget.
///
/// ## Usage
///
/// ```dart
/// import 'package:mot/mot.dart';
///
/// class UserModel with Beacon {
///   final name = BeaconField<String>('');
///   final age = BeaconField<int>(0);
/// }
///
/// // Subscribe (cleanup is automatic when observer dies)
/// user.name.observe(this, (self) => self.refresh());
/// ```
library mot;

export 'src/beacon.dart';
export 'src/beacon_field.dart';
export 'src/observer_entry.dart';
