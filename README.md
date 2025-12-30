# MOT - Multitude of Triads

> A sober and efficient alternative to state management in Dart and Flutter.

## The Sacrosanct Principle

> **"Simplicity of interface over simplicity of implementation"**

MOT must be invisible. Subscribe and forget.

## Philosophy

Flutter excels at rendering UI. The problem arises when we use the widget tree as a container for domain state. MOT separates this with a simple idea:

> **The domain lives outside the tree. The UI observes it.**

## Quick Start

```dart
import 'package:mot/mot.dart';

// Define your model
class UserModel with Beacon {
  final name = BeaconField<String>('');
  final age = BeaconField<int>(0);
}

// In your widget
@override
void initState() {
  super.initState();
  // Subscribe and forget - cleanup is automatic
  user.name.observe(this, (self) => self.setState(() {}));
}
```

## Core Concepts

### Beacon

A mixin that transforms any Dart class into an observable model:

```dart
class Counter with Beacon {
  int _count = 0;
  int get count => _count;

  void increment() {
    _count++;
    notify();  // Observers are notified via microqueue
  }
}
```

### BeaconField

An observable field for fine-grained reactivity:

```dart
final name = BeaconField<String>('');
name.value = 'Alice';  // Observers notified
name.value = 'Alice';  // No-op, same value
```

### The "self, not this" Pattern

```dart
// WRONG: captures 'this' → memory leak
beacon.observe(() => this.refresh());

// CORRECT: captures nothing → safe
beacon.observe(this, (self) => self.refresh());
```

## Features

- **Subscribe and forget** — No manual cleanup needed
- **WeakReference + Finalizer** — Automatic observer cleanup
- **Microqueue notifications** — Safe during Flutter's build phase
- **Zero dependencies** — Pure Dart, works everywhere

## Installation

```yaml
dependencies:
  mot: ^0.0.1
```

For Flutter projects:

```yaml
dependencies:
  mot_flutter: ^0.0.1
```

## Documentation

- [MOT Manifesto](docs/llm/mot_manifesto.md) — Full philosophy and design
- [Implementation Details](docs/llm/implementation.md) — How it works under the hood

## License

MIT
