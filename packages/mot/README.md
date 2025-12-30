# MOT

**Subscribe and forget.** A state management framework for Dart that handles cleanup automatically.

## Philosophy

> *"The domain lives outside the widget tree. The UI observes it."*

MOT prioritizes **simplicity of interface over simplicity of implementation**:

- **Invisible** — It just works. No boilerplate, no ceremony.
- **Subscribe and forget** — No manual cleanup. Ever.
- **Zero surprises** — Obvious, predictable behavior.

## Installation

```yaml
dependencies:
  mot: ^1.0.0
```

For Flutter projects, use [`mot_flutter`](https://pub.dev/packages/mot_flutter) instead.

## Quick Start

```dart
import 'package:mot/mot.dart';

// 1. Create a model
class Counter with Beacon {
  final count = BeaconField<int>(0);

  void increment() => count.value++;
}

// 2. Observe it
final counter = Counter();
counter.count.observe(myObserver, (self) => self.onCountChanged());

// 3. That's it. Cleanup is automatic.
```

## The "self, not this" Pattern

MOT uses a special pattern to prevent memory leaks:

```dart
// WRONG: Captures `this` → memory leak
model.observe(() => this.refresh());

// CORRECT: Receives `self` as parameter → safe
model.observe(this, (self) => self.refresh());
```

## API

### Beacon (mixin)

Transform any class into an observable:

```dart
class MyModel with Beacon {
  void doSomething() {
    // ... modify state ...
    notify();  // Notify observers
  }
}
```

| Method | Description |
|--------|-------------|
| `observe(observer, callback)` | Register an observer |
| `removeObserver(observer)` | Unregister (optional) |
| `hasObserver(observer)` | Check if registered |
| `notify()` | Schedule notification |
| `notifySync()` | Immediate notification (testing) |

### BeaconField<T>

An observable field that notifies on change:

```dart
final name = BeaconField<String>('');

name.value = 'Alice';  // Notifies observers
name.value = 'Alice';  // Same value → no notification
```

## Key Behaviors

**Coalescing**: Multiple changes = one notification

```dart
model.name.value = 'A';  // Schedules
model.name.value = 'B';  // Already scheduled
model.name.value = 'C';  // Already scheduled
// → ONE notification with value 'C'
```

**Error isolation**: One failing callback doesn't stop others.

**Automatic cleanup**: Observers are removed when garbage collected.

## LLM Assistance

If you're using an AI assistant, add [`docs/llm/mot_for_llms.md`](https://github.com/frr149/mot/blob/main/docs/llm/mot_for_llms.md) to your context for accurate help.

## License

MIT
