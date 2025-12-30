# MOT Framework - Documentation for LLMs

> **Purpose**: This document provides everything an LLM needs to assist users with MOT, a Dart/Flutter state management framework. Add this to your context when helping users with MOT.

---

## What is MOT?

MOT (Multitude of Triads) is a state management framework for Dart and Flutter based on a simple principle:

> **"The domain lives outside the widget tree. The UI observes it."**

MOT provides automatic memory management for observers through WeakReferences and Finalizers. Users subscribe once and never need to manually unsubscribe — cleanup happens automatically when the observer is garbage collected.

### Core Philosophy

**"Simplicity of interface over simplicity of implementation"**

- MOT should be invisible — "it just works"
- Subscribe and forget — no manual cleanup required
- Zero surprises — behavior is obvious and predictable
- Minimal ceremony — shortest API that's still clear and safe

---

## Installation

```yaml
# For Dart-only projects
dependencies:
  mot: ^0.1.0

# For Flutter projects
dependencies:
  mot_flutter: ^0.1.0
```

```dart
// Dart
import 'package:mot/mot.dart';

// Flutter
import 'package:mot_flutter/mot_flutter.dart';
```

---

## Core API

### Beacon (mixin)

`Beacon` is a mixin that transforms any Dart class into an observable model.

```dart
mixin Beacon on Object {
  /// Register an observer with the "self, not this" pattern.
  /// The callback receives the observer as parameter to avoid capturing `this`.
  void observe<T extends Object>(T observer, void Function(T self) callback);

  /// Remove an observer (optional - cleanup is automatic).
  void removeObserver<T extends Object>(T observer);

  /// Check if an observer is registered.
  bool hasObserver<T extends Object>(T observer);

  /// Schedule notification to all observers (via microtask queue).
  void notify();

  /// Notify synchronously (for testing only).
  void notifySync();
}
```

### BeaconField<T>

`BeaconField` is an observable field that notifies observers when its value changes.

```dart
class BeaconField<T> with Beacon {
  BeaconField(T initialValue);

  T get value;
  set value(T newValue);  // Notifies if newValue != current value
}
```

---

## The "self, not this" Pattern

This is the most important pattern in MOT. It prevents memory leaks by ensuring the callback doesn't capture `this`.

```dart
// WRONG: Captures `this` → memory leak, prevents GC
model.observe(() => this.refresh());  // DON'T DO THIS

// CORRECT: Captures nothing → safe, automatic cleanup
model.observe(this, (self) => self.refresh());  // DO THIS
```

The callback receives `self` as a parameter. This is the same object as `this`, but because it's a parameter rather than a closure capture, the observer can be garbage collected normally.

---

## Usage Examples

### Example 1: Simple Counter

```dart
import 'package:mot/mot.dart';

// Model - lives outside the widget tree
class CounterModel with Beacon {
  final count = BeaconField<int>(0);

  void increment() => count.value++;
  void decrement() => count.value--;
  void reset() => count.value = 0;
}
```

```dart
// Flutter widget
class CounterWidget extends StatefulWidget {
  const CounterWidget({super.key});

  @override
  State<CounterWidget> createState() => _CounterWidgetState();
}

class _CounterWidgetState extends State<CounterWidget> {
  final model = CounterModel();

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
        ElevatedButton(
          onPressed: model.decrement,
          child: const Text('-'),
        ),
      ],
    );
  }
}
```

### Example 2: User Profile (Multiple Fields)

```dart
class UserProfile with Beacon {
  final name = BeaconField<String>('');
  final email = BeaconField<String>('');
  final age = BeaconField<int>(0);
  final isVerified = BeaconField<bool>(false);

  void updateName(String newName) => name.value = newName;
  void updateEmail(String newEmail) => email.value = newEmail;
  void verify() => isVerified.value = true;
}
```

```dart
class ProfileWidget extends StatefulWidget {
  final UserProfile profile;

  const ProfileWidget({super.key, required this.profile});

  @override
  State<ProfileWidget> createState() => _ProfileWidgetState();
}

class _ProfileWidgetState extends State<ProfileWidget> {
  @override
  void initState() {
    super.initState();
    // Observe only the fields you need
    widget.profile.name.observe(this, (self) => self.setState(() {}));
    widget.profile.isVerified.observe(this, (self) => self.setState(() {}));
    // email and age changes won't trigger rebuilds here
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    return ListTile(
      title: Text(profile.name.value),
      trailing: profile.isVerified.value
        ? const Icon(Icons.verified)
        : null,
    );
  }
}
```

### Example 3: Model with Computed Properties

```dart
class ShoppingCart with Beacon {
  final _items = <CartItem>[];

  List<CartItem> get items => List.unmodifiable(_items);

  // Computed property - no caching, always fresh
  double get total => _items.fold(0, (sum, item) => sum + item.price);
  int get itemCount => _items.length;
  bool get isEmpty => _items.isEmpty;

  void addItem(CartItem item) {
    _items.add(item);
    notify();  // Notify after mutation
  }

  void removeItem(CartItem item) {
    _items.remove(item);
    notify();
  }

  void clear() {
    _items.clear();
    notify();
  }
}

class CartItem {
  final String name;
  final double price;

  const CartItem({required this.name, required this.price});
}
```

### Example 4: Observing the Model Directly

You can observe a model that uses `Beacon` directly, not just `BeaconField`:

```dart
class TodoList with Beacon {
  final _todos = <Todo>[];

  List<Todo> get todos => List.unmodifiable(_todos);
  int get pendingCount => _todos.where((t) => !t.done).length;

  void add(String title) {
    _todos.add(Todo(title: title));
    notify();
  }

  void toggle(Todo todo) {
    todo.done = !todo.done;
    notify();
  }

  void remove(Todo todo) {
    _todos.remove(todo);
    notify();
  }
}
```

```dart
class TodoListWidget extends StatefulWidget {
  final TodoList todoList;

  const TodoListWidget({super.key, required this.todoList});

  @override
  State<TodoListWidget> createState() => _TodoListWidgetState();
}

class _TodoListWidgetState extends State<TodoListWidget> {
  @override
  void initState() {
    super.initState();
    // Observe the model itself, not a field
    widget.todoList.observe(this, (self) => self.setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: widget.todoList.todos.length,
      itemBuilder: (context, index) {
        final todo = widget.todoList.todos[index];
        return CheckboxListTile(
          title: Text(todo.title),
          value: todo.done,
          onChanged: (_) => widget.todoList.toggle(todo),
        );
      },
    );
  }
}
```

---

## Key Behaviors

### Notification Coalescing

Multiple changes within the same microtask result in a single notification:

```dart
model.name.value = 'A';  // Schedules notification
model.name.value = 'B';  // Already scheduled, no-op
model.name.value = 'C';  // Already scheduled, no-op
// → ONE notification with final value 'C'
```

### Equality Check

`BeaconField` only notifies if the new value is different:

```dart
final field = BeaconField<String>('hello');
field.value = 'hello';  // Same value → no notification
field.value = 'world';  // Different → notification scheduled
```

### Error Isolation

If one observer's callback throws, other observers still get notified:

```dart
model.observe(observer1, (self) => throw Exception('Oops'));
model.observe(observer2, (self) => self.doSomething());  // Still called!

// Errors are reported via Zone.current.handleUncaughtError()
```

### Automatic Cleanup

When an observer is garbage collected, it's automatically removed:

```dart
void setupObserver() {
  final tempObserver = SomeObject();
  model.observe(tempObserver, (self) => print('notified'));
  // tempObserver goes out of scope and can be GC'd
  // No memory leak, no manual cleanup needed
}
```

---

## Common Patterns

### Sharing State Between Widgets

```dart
// Create model at app level or use a service locator
final appState = AppState();

// Pass to widgets that need it
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomeScreen(appState: appState),
    );
  }
}

// Each widget observes what it needs
class HomeScreen extends StatefulWidget {
  final AppState appState;
  const HomeScreen({super.key, required this.appState});
  // ...
}
```

### Fine-Grained Updates

Observe specific fields to minimize rebuilds:

```dart
// Only rebuilds when name changes
profile.name.observe(this, (self) => self.setState(() {}));

// This widget won't rebuild when email or age changes
```

### Combining Multiple Observations

```dart
@override
void initState() {
  super.initState();
  // Rebuild when ANY of these change
  model.field1.observe(this, (self) => self.setState(() {}));
  model.field2.observe(this, (self) => self.setState(() {}));
  model.field3.observe(this, (self) => self.setState(() {}));
}
```

### Manual Cleanup (Rare)

Usually not needed, but available if you need deterministic cleanup:

```dart
@override
void dispose() {
  model.removeObserver(this);  // Optional - happens automatically anyway
  super.dispose();
}
```

---

## Common Mistakes and Solutions

### Mistake 1: Capturing `this` in closure

```dart
// WRONG
model.observe(this, (self) {
  this.setState(() {});  // Captures `this`!
});

// CORRECT
model.observe(this, (self) {
  self.setState(() {});  // Uses parameter, no capture
});
```

### Mistake 2: Forgetting to call notify()

```dart
class MyModel with Beacon {
  final _items = <String>[];

  void addItem(String item) {
    _items.add(item);
    // WRONG: Forgot notify() - observers won't know!
  }

  void addItemCorrect(String item) {
    _items.add(item);
    notify();  // CORRECT: Observers will be notified
  }
}
```

### Mistake 3: Using BeaconField for collections incorrectly

```dart
// WRONG: Mutating the list doesn't trigger notification
final items = BeaconField<List<String>>([]);
items.value.add('new');  // No notification! Same list reference

// CORRECT: Replace the entire list
items.value = [...items.value, 'new'];

// OR: Use a model with Beacon mixin for collections
class ItemList with Beacon {
  final _items = <String>[];
  List<String> get items => List.unmodifiable(_items);

  void add(String item) {
    _items.add(item);
    notify();
  }
}
```

### Mistake 4: Observing in build()

```dart
// WRONG: Creates new subscription every build!
@override
Widget build(BuildContext context) {
  model.observe(this, (self) => self.setState(() {}));
  return Text(model.value);
}

// CORRECT: Observe once in initState
@override
void initState() {
  super.initState();
  model.observe(this, (self) => self.setState(() {}));
}
```

---

## Migration from Other State Managers

### From Provider/ChangeNotifier

```dart
// Before (Provider)
class Counter extends ChangeNotifier {
  int _count = 0;
  int get count => _count;

  void increment() {
    _count++;
    notifyListeners();
  }
}

// After (MOT)
class Counter with Beacon {
  final count = BeaconField<int>(0);

  void increment() => count.value++;
}

// Widget: Replace Consumer with observe
// Before
Consumer<Counter>(builder: (context, counter, child) => Text('${counter.count}'));

// After
class _MyWidgetState extends State<MyWidget> {
  @override
  void initState() {
    super.initState();
    counter.count.observe(this, (self) => self.setState(() {}));
  }

  @override
  Widget build(BuildContext context) => Text('${counter.count.value}');
}
```

### From Riverpod

```dart
// Before (Riverpod)
final counterProvider = StateNotifierProvider<CounterNotifier, int>((ref) {
  return CounterNotifier();
});

class CounterNotifier extends StateNotifier<int> {
  CounterNotifier() : super(0);
  void increment() => state++;
}

// After (MOT)
class Counter with Beacon {
  final count = BeaconField<int>(0);
  void increment() => count.value++;
}

// Create instance where needed (no providers)
final counter = Counter();
```

### From BLoC

```dart
// Before (BLoC)
class CounterCubit extends Cubit<int> {
  CounterCubit() : super(0);
  void increment() => emit(state + 1);
}

// After (MOT)
class Counter with Beacon {
  final count = BeaconField<int>(0);
  void increment() => count.value++;
}

// No BlocProvider, BlocBuilder, etc. needed
```

---

## Testing

### Testing Models

```dart
import 'package:test/test.dart';

void main() {
  test('Counter increments', () {
    final counter = Counter();

    counter.increment();

    expect(counter.count.value, equals(1));
  });

  test('Counter notifies observers', () {
    final counter = Counter();
    final observer = _TestObserver();

    counter.count.observe(observer, (self) => self.notified = true);
    counter.increment();

    // Use notifySync for synchronous testing
    counter.count.notifySync();

    expect(observer.notified, isTrue);
  });
}

class _TestObserver {
  bool notified = false;
}
```

### Testing with Async

```dart
test('notifications are delivered after microtask', () async {
  final counter = Counter();
  final observer = _TestObserver();

  counter.count.observe(observer, (self) => self.callCount++);
  counter.increment();

  // Not yet notified (microtask hasn't run)
  expect(observer.callCount, equals(0));

  // Wait for microtask
  await Future<void>.delayed(Duration.zero);

  expect(observer.callCount, equals(1));
});
```

---

## FAQ

**Q: Do I need to call dispose() or removeObserver()?**
A: No. Cleanup is automatic when the observer is garbage collected.

**Q: Can I observe multiple fields?**
A: Yes. Call `observe()` for each field you want to watch.

**Q: What if I observe the same model twice?**
A: Each call to `observe()` registers a separate callback. Both will be called.

**Q: How do I observe a list/map?**
A: Use a model with `Beacon` mixin and call `notify()` after mutations. Don't use `BeaconField<List<T>>` for mutable lists.

**Q: Can I use MOT without Flutter?**
A: Yes. The `mot` package is pure Dart. Only use `mot_flutter` if you need Flutter-specific features.

**Q: How do I share state between screens?**
A: Pass the model instance to widgets that need it, or use a service locator pattern.

---

## Summary

| Concept | Description |
|---------|-------------|
| `Beacon` | Mixin that makes any class observable |
| `BeaconField<T>` | Observable field that notifies on change |
| `observe(observer, callback)` | Subscribe with "self, not this" pattern |
| `notify()` | Schedule notification (coalesces in microtask) |
| `notifySync()` | Immediate notification (for testing) |
| `removeObserver()` | Manual cleanup (usually not needed) |

**Key principle**: Subscribe and forget. MOT handles cleanup automatically.
