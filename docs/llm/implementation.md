# MOT Implementation: Safe Observer Pattern

## The Problem

In any pub/sub system, observers that forget to unsubscribe cause two problems:

1. **Memory leaks** — the model retains the observer forever
2. **Crashes** — calling methods on dead objects

Traditional solution: require developers to manually call `removeObserver()` in `dispose()`. But developers forget. And when they forget, bad things happen.

MOT takes a different stance:

> **Forgetting to unsubscribe should not be catastrophic.**

---

## Why Closures Cause Retain Cycles

When you write a closure in Dart, it **captures** the variables you reference inside it:

```dart
class MyWidget {
  void init() {
    model.addListener(() {
      this.refresh();  // ← "this" is captured by the closure
    });
  }
}
```

The closure is an object that holds a reference to `this`. As long as the closure exists, `this` cannot be garbage collected.

### The Retain Cycle

```
┌─────────────────────────────────────────────────┐
│                                                 │
│   Model                                         │
│   └── listeners: [closure]                      │
│                      │                          │
│                      └── captures: this ────┐   │
│                                             │   │
│   MyWidget ◄────────────────────────────────┘   │
│   (wants to die, but can't)                     │
│                                                 │
└─────────────────────────────────────────────────┘
```

The Model holds the closure. The closure holds MyWidget. MyWidget cannot be freed even when nothing else references it.

---

## The Solution: Parameters, Not Captures

The trick is to design callbacks that **don't capture anything**. Instead, the observer is passed as a parameter when the callback is invoked:

```dart
// ❌ CAPTURE — the closure retains "this"
model.addListener(() => this.refresh());
//                      ^^^^ captured inside the closure

// ✅ PARAMETER — the closure retains nothing
beacon.addObserver(
  observer: this,
  callback: (self) => self.refresh(),
  //         ^^^^ only exists when someone calls the closure
);
```

### Analogy

**Capture:** The closure keeps a photo of `this` in its pocket. As long as the closure exists, the photo exists.

**Parameter:** The closure says "when you call me, tell me who I'm talking to." It keeps no photo.

---

## Implementation

### The Observer Entry

Each subscription is stored as an entry containing:

1. A `WeakReference` to the observer (does not retain it)
2. The callback (which captures nothing)
3. An ID for cleanup via Finalizer

```dart
class _ObserverEntry<T extends Object> {
  final WeakReference<T> weakObserver;
  final void Function(T observer) callback;
  final int id;

  _ObserverEntry({
    required T observer,
    required this.callback,
    required this.id,
  }) : weakObserver = WeakReference(observer);

  /// Returns true if the observer is still alive
  bool get isAlive => weakObserver.target != null;

  /// Attempts to invoke the callback. Returns false if observer is dead.
  bool tryInvoke() {
    final observer = weakObserver.target;
    if (observer == null) return false;
    callback(observer);
    return true;
  }
}
```

### Registration with Finalizer

When an observer subscribes, we attach a `Finalizer` that will clean up when the GC reclaims the observer:

```dart
class Beacon {
  final List<_ObserverEntry> _listeners = [];
  int _nextId = 0;
  
  // Maps entryId → entry for cleanup from Finalizer
  final Map<int, _ObserverEntry> _entriesById = {};
  
  late final Finalizer<int> _finalizer = Finalizer(_onObserverDied);

  void _onObserverDied(int entryId) {
    final entry = _entriesById.remove(entryId);
    if (entry != null) {
      _listeners.remove(entry);
    }
  }

  void addObserver<T extends Object>({
    required T observer,
    required void Function(T self) callback,
  }) {
    final id = _nextId++;
    
    final entry = _ObserverEntry<T>(
      observer: observer,
      callback: callback,
      id: id,
    );

    _listeners.add(entry);
    _entriesById[id] = entry;
    
    // Attach finalizer — when observer dies, _onObserverDied is called with id
    _finalizer.attach(observer, id, detach: observer);
  }
}
```

### Safe Notification

When notifying, we check if each observer is still alive:

```dart
void notify() {
  // Opportunistic cleanup: remove dead entries
  _listeners.removeWhere((entry) => !entry.isAlive);
  
  // Iterate over a copy to avoid concurrent modification
  for (final entry in List.of(_listeners)) {
    entry.tryInvoke();
  }
}
```

### Optional Manual Removal

Developers can still manually unsubscribe if they want deterministic cleanup:

```dart
void removeObserver<T extends Object>(T observer) {
  _listeners.removeWhere(
    (entry) => identical(entry.weakObserver.target, observer),
  );
}
```

But if they forget, the system cleans up automatically.

---

## What Happens When an Observer Dies?

| Situation | What Happens |
|-----------|--------------|
| Observer alive | `weakReference.target` returns the object → callback is invoked |
| Observer dead | `weakReference.target` returns `null` → callback is skipped, entry is cleaned up |

### Cleanup Layers

| Layer | Mechanism | When |
|-------|-----------|------|
| **Safe invocation** | Check `target != null` before calling | Every `notify()` |
| **Opportunistic cleanup** | `removeWhere(!isAlive)` | Every `notify()` |
| **Automatic cleanup** | `Finalizer` callback | When GC reclaims observer |

The worst case if a developer forgets to unsubscribe: a zombie entry occupies a few bytes until the next `notify()` or until the Finalizer fires.

---

## Usage Pattern

```dart
class MyWidget extends StatefulWidget {
  // ...
}

class _MyWidgetState extends State<MyWidget> {
  late final UserModel user;

  @override
  void initState() {
    super.initState();
    user = UserModel();
    
    // Subscribe using "self", not "this"
    user.addObserver(
      observer: this,
      callback: (self) => self._onUserChanged(),
    );
  }

  void _onUserChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    // OPTIONAL: deterministic cleanup
    // If you forget this, nothing bad happens
    user.removeObserver(this);
    super.dispose();
  }
}
```

---

## Key Insight

The "self, not this" pattern works because:

1. `this` passed to `observer:` is stored in a `WeakReference` (no retention)
2. The closure `(self) => self._onUserChanged()` captures nothing
3. When invoked, `self` is provided by the Beacon from the `WeakReference`

The closure has no idea who `self` will be until it's called. It's a pure function waiting for input.

---

## Summary

| Traditional Approach | MOT Approach |
|---------------------|--------------|
| Closure captures `this` | Closure captures nothing |
| Strong reference to observer | `WeakReference` to observer |
| Forgetting `dispose` = memory leak | Forgetting `dispose` = auto-cleanup |
| Calling dead observer = crash | Dead observer = silently skipped |

**MOT philosophy:** The framework should protect developers from common mistakes. Forgetting to unsubscribe is human. The consequences should not be catastrophic.

---

## Microqueue Notifications

### The Problem with Synchronous Notifications

Calling listeners synchronously during a state change creates several issues:

1. **Notification during build** — In Flutter, calling `setState()` while a widget is building throws an exception
2. **Cascade overflow** — Listener A changes state, which notifies Listener B, which changes state, which notifies Listener A...
3. **Inconsistent state** — Observers see partially-updated state when multiple fields change
4. **Unpredictable order** — The order of listener execution becomes implicit and fragile

### The Solution: Microqueue Scheduling

MOT schedules all notifications on Dart's **microqueue** using `scheduleMicrotask()`:

```dart
void notify() {
  if (_notificationScheduled) return;
  _notificationScheduled = true;

  scheduleMicrotask(() {
    _notificationScheduled = false;
    _doNotify();
  });
}
```

### Why Microqueue, Not Event Queue?

Dart has two queues:

| Queue | Scheduled with | Timing |
|-------|---------------|--------|
| **Microqueue** | `scheduleMicrotask()` | Runs before next event, after current code |
| **Event queue** | `Future()`, `Timer()` | Runs on next event loop iteration |

The microqueue is ideal because:

- **Fast enough** — Notifications happen "almost immediately" (same event loop turn)
- **Deferred enough** — Current synchronous code completes first
- **Batching-friendly** — Multiple changes coalesce into one notification

### How It Works

```
Time →

┌─────────────────────────────────────────────────────────────┐
│ Synchronous execution                                        │
│                                                              │
│   user.name = "Alice";  // schedules notification            │
│   user.age = 30;        // already scheduled, no-op          │
│   user.email = "...";   // already scheduled, no-op          │
│                                                              │
│ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ │
│ Microqueue (same event loop turn)                            │
│                                                              │
│   → notify() fires ONCE                                      │
│   → all observers see final state: name="Alice", age=30      │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Natural Batching

With microqueue scheduling, batching is **automatic**:

```dart
// Without explicit batch API, changes naturally coalesce
user.name = "Alice";
user.age = 30;
user.email = "alice@example.com";
// → ONE notification with all three changes
```

For cases where you need explicit control, MOT still provides `beginBatch()`/`endBatch()`:

```dart
user.beginBatch();
try {
  // Complex multi-step operation
  user.name = computeName();
  user.age = computeAge();
  // Even if these throw, endBatch ensures notification
} finally {
  user.endBatch();  // Notification happens here
}
```

### Interaction with Flutter's Build Phase

Because notifications are deferred to the microqueue:

```dart
// This is SAFE in MOT:
@override
Widget build(BuildContext context) {
  // Even if model changes during build, setState() is deferred
  model.someField = newValue;  // ← Won't crash
  return Text(model.someField);
}
```

The `setState()` call happens after `build()` completes, triggering a new frame.

### Implementation Detail

```dart
mixin Beacon {
  bool _notificationScheduled = false;

  void notify() {
    if (_notificationScheduled) return;
    _notificationScheduled = true;

    scheduleMicrotask(_executeNotification);
  }

  void _executeNotification() {
    _notificationScheduled = false;

    // Clean up dead observers opportunistically
    _listeners.removeWhere((entry) => !entry.isAlive);

    // Notify all alive observers
    for (final entry in List.of(_listeners)) {
      entry.tryInvoke();
    }
  }
}
```

### Summary

| Synchronous Notifications | Microqueue Notifications |
|--------------------------|-------------------------|
| Can crash during build | Safe during build |
| Each change = one notification | Changes coalesce naturally |
| Risk of cascade overflow | Cascades are bounded |
| Observers see intermediate state | Observers see final state |

**MOT philosophy:** Notifications should be predictable and safe. The microqueue provides the right balance between immediacy and safety.