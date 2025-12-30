# MOT Manifesto (Extended)

A sober and efficient alternative to state management in Flutter

---

## 0. The Sacrosanct Principle: Simplicity of Interface

> **"Simplicity of interface over simplicity of implementation"**

MOT prioritizes user experience over internal implementation convenience. This means:

1. **MOT must be invisible** — "It just works". The user should not think about the framework.
2. **Subscribe and forget** — No manual cleanup. If the observer dies, cleanup is automatic.
3. **Zero surprises** — Behavior must be obvious and predictable.
4. **Minimal ceremony** — The shortest API that remains clear and safe.

When facing a design decision:
- Simple API + complex implementation → **Do it**
- Complex API + simple implementation → **Don't do it**

The user should never pay the price of our comfort as implementers.

---

## 1. Context: The Tree Is Not the Domain

Flutter excels at rendering UI. The problem arises when we use the widget tree as:

- a container for domain state,
- an implicit injection system,
- a data transport mechanism,
- a dependency orchestrator.

This approach works in small apps. As soon as the domain grows, the tree stops being a visual structure and becomes accidental infrastructure: implicit dependencies, scopes, rebuilds that are hard to explain, and an architecture where the UI dictates the shape of the domain.

MOT separates this with a simple idea:

> **The domain lives outside the tree. The UI observes it.**

---

## 2. What Is MOT in One Sentence

MOT (Multitude of Triads) proposes that an application is built as a multitude of triads:

- **Model** — state and logic, sovereign and observable (powered by Beacon)
- **Observer** — reactive bridge between model and UI
- **Widget** — visual projection, deliberately passive

This is not a trend. It's basic engineering: clear responsibilities, explicit dependencies, testability, and cognitive cost control.

---

## 2. The Core Abstractions

MOT maintains few pieces, with concrete names, and well-defined responsibilities.

### 2.1 Beacon — The 1-N Communication Mechanism

#### What It Is

A Beacon is not a model—it is the mechanism that transforms any Dart class into an observable model. Think of it as the infrastructure that gives a class the ability to broadcast its changes.

**The influencer analogy:** An influencer is someone who broadcasts everything they do to their followers. A Beacon does exactly that for a class—it gives it the ability to notify all its observers whenever something changes. The class becomes an "influencer" in the domain: it has followers (observers) who react to its updates.

A model, then, is simply a domain class that uses Beacon to notify its changes. The class owns its state and logic; Beacon provides the communication channel.

#### Responsibilities

- Provide the 1-N notification mechanism (`observe`/`removeObserver`/`notify`).
- Automatic cleanup when observers die (WeakReference + Finalizer).
- Microqueue scheduling for safe, coalesced notifications.

#### What It Does NOT Do

- Does not hold domain state (the class does).
- Does not contain business logic (the class does).
- Does not render.
- Does not know about widgets.
- Does not navigate the tree.

#### API (v1.0)

```dart
mixin Beacon on Object {
  void observe<T extends Object>(T observer, void Function(T self) callback);
  void removeObserver<T extends Object>(T observer);
  bool hasObserver<T extends Object>(T observer);
  void notify();
}
```

#### The "self, not this" Pattern

```dart
// ❌ Captures this → memory leak
beacon.observe(() => this.refresh());

// ✅ Captures nothing → safe
beacon.observe(this, (self) => self.refresh());
```

The callback receives `self` as a parameter (passed from WeakReference), it does not capture `this`.

In essence: a mixin that gives any Dart class the power to broadcast changes safely—subscribe and forget.

---

### 2.2 BeaconField<T> — Fine-Grained Reactivity Without Magic

#### What It Is

A `BeaconField<T>` is an observable field. It is the minimal unit for achieving:

- per-field notification,
- fine-grained UI updates,
- change traceability.

In traditional Flutter, you either rebuild too much or end up creating complicated selectors. MOT makes it explicit: the field is observable.

#### Responsibilities

- Store a value `T`.
- Notify changes when the value changes.
- Optionally emit a `ChangeSet` describing the change.

#### Implementation (General Level)

- Stores `_value`.
- In the setter, if it changes, notifies:
  - simple listeners (`VoidCallback`)
  - detailed listeners (with `ChangeSet`)

This allows:

- the model to change with clear semantics,
- the UI to observe exactly what it needs.

---

### 2.3 ChangeSet — Change as Data

#### What It Is

`ChangeSet` is "the change converted into an object/value."
It serves two distinct purposes:

1. **Local use (efficient):** a record
2. **Synchronization (stable):** a serializable type

#### Responsibilities

- Describe what field changed and how.
- Enable logging, traceability, testing, and (later) undo/redo.
- In full-stack: be the unit that travels over the network.

#### Implementation (General Level)

- **Local:** `typedef ChangeSet<T> = (String field, T oldValue, T newValue);`
- **Remote:** `SerializableChangeSet` with `toJson`/`fromJson`, and typically `beaconId`, `field`, `oldValue`, `newValue`, `metadata`.

**MOT full-stack principle:**

> The model is not sent; its ChangeSets are sent.

---

### 2.4 Observer / ObserverState — The Reactive Bridge

#### What It Is

The Observer is the adapter between the model world (domain) and the render world (UI). In Flutter, the natural way to materialize it is a State that listens to the model.

#### Responsibilities

- Subscribe to the model (or to specific fields).
- Call `setState()` when appropriate.
- Manage the lifecycle: `initState` / `dispose`.

#### What It Does NOT Do

- Does not contain business rules.
- Does not "push" state through the tree.
- Does not become a "god object."

#### Implementation (General Level)

```dart
ObserverState<M extends Beacon, W extends StatefulWidget>
```

- in `initState`: `model.addListener(_onModelChanged)`
- in `_onModelChanged`: `setState(() {})`
- in `dispose`: `model.removeListener(...)`

This returns control to an obvious place: the Observer decides when to redraw.

---

### 2.5 BeaconFieldObserver<T> — Surgical Reconstruction

#### What It Is

A small widget that observes a `BeaconField<T>` and rebuilds only its subtree when that field changes. It is the pragmatic equivalent of "selectors" but explicit and simple.

#### Responsibilities

- Subscribe to a `BeaconField`.
- Call `setState` when it changes.
- Render with `builder(context, field.value)`.

#### Implementation (General Level)

A `StatefulWidget` that:

- in `initState` subscribes
- in `dispose` unsubscribes
- in `build` calls the builder

Result: fewer rebuilds, less work, and less mental noise.

---

### 2.6 BeaconTower — Decoupled Signals Between Triads

> **Status:** Backlog (post v1.0)

#### What It Is

A signal channel for "broadcast" events where you don't want to couple models to each other.

It is the replacement for "NotificationCenter" but with MOT language:
a tower emits signals; whoever wants to, listens.

#### Responsibilities

- Type-safe signals using sealed classes (NO stringly-typed code).
- Allow `emit(Signal)`.
- Allow `on<SignalType>(handler)`.
- Allow `once<SignalType>(handler)`.
- (Optional) scopes, for tests or isolation.

#### What It Does NOT Do

- Does not replace observation (not for fine-grained state changes).
- Should not be used for "all communication."
- Does not replace composition/injection when there is real dependency.

#### API (Planned)

```dart
// Define signals as sealed classes
sealed class AppSignal {}
class UserLogout extends AppSignal {}
class SessionExpired extends AppSignal {
  final String reason;
  SessionExpired(this.reason);
}

// Emit
BeaconTower.emit(UserLogout());
BeaconTower.emit(SessionExpired('Token expired'));

// Listen (type-safe)
BeaconTower.on<UserLogout>((signal) => clearCache());
BeaconTower.on<SessionExpired>((signal) => showError(signal.reason));
```

The type IS the identifier. The compiler protects you. Typed payload for free.

---

### 2.7 Advisor — Punctual Decisions Without Confusion

#### What It Is

An Advisor is an interface that the model consults when it needs a contextual decision that does not belong to the pure domain, or that depends on external policies.

It is the functional equivalent of a delegate, but with a name that better describes its real role: it advises and decides.

#### Responsibilities

- Provide punctual 1:1 decisions.
- Separate policies from the model core.
- Facilitate tests (simple mocks).

#### Implementation (General Level)

- An interface (`abstract class XAdvisor`) and a nullable property in the model.
- The model calls: `advisor?.shouldX()`.

This keeps the model sovereign and testable, without coupling it to the outside.

---

## 4. Why These Pieces and Not Others

MOT does not try to invent complexity. It tries to reduce it.

These abstractions cover a minimal set of real needs:

1. **Observable models** — any class + Beacon
2. **Fine-grained reactivity** — BeaconField
3. **Change as data** — ChangeSet
4. **Controlled UI connection** — ObserverState, BeaconFieldObserver
5. **Decoupled events** — BeaconTower
6. **Clean external decisions** — Advisor

Everything else is extension: observable lists, registries, synchronization, tooling.

---

## 5. Implementation: System Overview

In a typical MOT app:

- The domain is formed by many small models (classes using Beacon).
- Each model exposes BeaconFields.
- The UI is built with `ObserverState` or `BeaconFieldObserver`.
- Punctual global events travel through `BeaconTower`.
- Contextualized decisions are consulted through an `Advisor`.

And the widget tree returns to its natural role:

> **rendering UI.**

---

## 6. Note on Full-Stack (In General Terms)

If you share models between backend and frontend, MOT proposes:

- keep the same domain code in a `shared/` package,
- serialize only `SerializableChangeSet`,
- and apply them to the model on the other side.

What remains open (and to be evaluated in real projects) is how to stabilize `beaconId` between endpoints, because that defines how you locate the exact instance to which to apply the change.

---

## 7. Closing

MOT is not a religion. It is a bet on basic engineering:

- clear responsibilities,
- explicit dependency,
- controlled reactivity,
- state outside the tree,
- and a domain that returns to being the center.

When that is achieved, performance improves, yes.
But more importantly: the architecture becomes reasonable.

