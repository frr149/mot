/// Flutter integration for MOT state management.
///
/// This package re-exports the core `mot` package and provides
/// Flutter-specific helpers for widget integration.
///
/// ## Quick Start
///
/// ```dart
/// import 'package:mot_flutter/mot_flutter.dart';
///
/// class CounterModel with Beacon {
///   final count = BeaconField<int>(0);
///
///   void increment() => count.value++;
/// }
///
/// class CounterWidget extends StatefulWidget {
///   @override
///   State<CounterWidget> createState() => _CounterWidgetState();
/// }
///
/// class _CounterWidgetState extends State<CounterWidget> {
///   final model = CounterModel();
///
///   @override
///   void initState() {
///     super.initState();
///     // Subscribe and forget - cleanup is automatic
///     model.count.observe(this, (self) => self.setState(() {}));
///   }
///
///   @override
///   Widget build(BuildContext context) {
///     return Text('Count: ${model.count.value}');
///   }
/// }
/// ```
library;

// Re-export core MOT
export 'package:mot/mot.dart';
