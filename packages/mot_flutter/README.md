# MOT Flutter

[![pub package](https://img.shields.io/pub/v/mot_flutter.svg)](https://pub.dev/packages/mot_flutter)

**Subscribe and forget.** State management for Flutter with automatic cleanup.

## Installation

```yaml
dependencies:
  mot_flutter: ^0.1.0
```

This package re-exports [`mot`](https://pub.dev/packages/mot) and provides Flutter integration.

## Quick Start

```dart
import 'package:mot_flutter/mot_flutter.dart';

// 1. Create a model (lives outside the widget tree)
class Counter with Beacon {
  final count = BeaconField<int>(0);

  void increment() => count.value++;
}

// 2. Use in a StatefulWidget
class CounterWidget extends StatefulWidget {
  const CounterWidget({super.key});

  @override
  State<CounterWidget> createState() => _CounterWidgetState();
}

class _CounterWidgetState extends State<CounterWidget> {
  final model = Counter();

  @override
  void initState() {
    super.initState();
    // Subscribe and forget - cleanup is automatic
    model.count.observe(this, (self) => self.setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Count: ${model.count.value}'),
        ElevatedButton(
          onPressed: model.increment,
          child: const Text('+'),
        ),
      ],
    );
  }
}
```

## The Pattern

```dart
// In initState, observe the fields you need:
model.field.observe(this, (self) => self.setState(() {}));

// That's it. No dispose() needed.
// When the widget dies, the subscription is cleaned up automatically.
```

## Fine-Grained Updates

Only observe what you need:

```dart
@override
void initState() {
  super.initState();
  // Only rebuilds when name changes
  profile.name.observe(this, (self) => self.setState(() {}));
  // Won't rebuild when email or age changes
}
```

## Philosophy

> *"The domain lives outside the widget tree. The UI observes it."*

MOT keeps your business logic separate from Flutter. Models are plain Dart classes that can be tested without Flutter.

## Documentation

- [mot package](https://pub.dev/packages/mot) — Core API documentation
- [LLM guide](https://github.com/frr149/mot/blob/main/docs/llm/mot_for_llms.md) — Add to AI context for help

## License

MIT
