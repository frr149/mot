import 'dart:async';

import 'observer_entry.dart';

/// A mixin that transforms any Dart class into an observable model.
///
/// Beacon provides the 1-N notification mechanism that allows multiple
/// observers to react to changes in a model. It handles:
///
/// - Safe observation with [WeakReference] (no memory leaks)
/// - Automatic cleanup when observers die
/// - Microqueue scheduling for safe, coalesced notifications
///
/// ## The "self, not this" Pattern
///
/// ```dart
/// // WRONG: captures this → memory leak
/// beacon.observe(() => this.refresh());
///
/// // CORRECT: captures nothing → safe
/// beacon.observe(this, (self) => self.refresh());
/// ```
///
/// ## Example
///
/// ```dart
/// class Counter with Beacon {
///   int _count = 0;
///   int get count => _count;
///
///   void increment() {
///     _count++;
///     notify();
///   }
/// }
///
/// // Subscribe (cleanup is automatic)
/// counter.observe(myWidget, (self) => self.setState(() {}));
/// ```
mixin Beacon on Object {
  final List<ObserverEntry<Object>> _observers = [];
  final Map<int, ObserverEntry<Object>> _entriesById = {};
  int _nextId = 0;
  bool _notificationScheduled = false;

  late final Finalizer<int> _finalizer = Finalizer(_onObserverFinalized);

  /// Registers an observer to be notified when [notify] is called.
  ///
  /// The [observer] is stored as a weak reference, allowing it to be
  /// garbage collected even while subscribed. When the observer dies,
  /// it is automatically removed from the subscription list.
  ///
  /// The [callback] receives the observer as parameter. This is the
  /// "self, not this" pattern that prevents memory leaks.
  ///
  /// ## Example
  ///
  /// ```dart
  /// model.observe(this, (self) => self.setState(() {}));
  /// ```
  void observe<T extends Object>(T observer, void Function(T self) callback) {
    final id = _nextId++;

    final entry = ObserverEntry<T>(
      observer: observer,
      callback: callback,
      id: id,
    );

    _observers.add(entry);
    _entriesById[id] = entry;

    _finalizer.attach(observer, id, detach: observer);
  }

  /// Removes an observer from the subscription list.
  ///
  /// This is optional — observers are automatically removed when they
  /// are garbage collected. Use this only if you need deterministic
  /// cleanup before the observer dies.
  void removeObserver<T extends Object>(T observer) {
    final index = _observers.indexWhere(
      (entry) => identical(entry.observer, observer),
    );

    if (index != -1) {
      final entry = _observers.removeAt(index);
      _entriesById.remove(entry.id);
      _finalizer.detach(observer);
    }
  }

  /// Returns true if the observer is currently subscribed.
  bool hasObserver<T extends Object>(T observer) =>
      _observers.any((entry) => identical(entry.observer, observer));

  /// Schedules a notification to all observers.
  ///
  /// Notifications are delivered via [scheduleMicrotask], which means:
  /// - Multiple calls to [notify] within the same microtask coalesce
  /// - Notifications happen after the current synchronous code completes
  /// - Safe to call during Flutter's build phase
  ///
  /// ## Example
  ///
  /// ```dart
  /// model.name = 'A';  // schedules notification
  /// model.name = 'B';  // already scheduled, no-op
  /// model.name = 'C';  // already scheduled, no-op
  /// // → ONE notification with final value 'C'
  /// ```
  void notify() {
    if (_notificationScheduled) return;
    _notificationScheduled = true;
    scheduleMicrotask(_executeNotify);
  }

  /// Executes notification synchronously. For testing only.
  ///
  /// In production code, always use [notify] which schedules via microtask.
  void notifySync() {
    _executeNotify();
  }

  void _executeNotify() {
    _notificationScheduled = false;

    // Opportunistic cleanup: remove dead observers
    _observers.removeWhere((entry) {
      if (!entry.isAlive) {
        _entriesById.remove(entry.id);
        return true;
      }
      return false;
    });

    // Iterate over a copy to avoid concurrent modification
    for (final entry in List.of(_observers)) {
      try {
        entry.tryInvoke();
        // ignore: avoid_catches_without_on_clauses
      } catch (error, stackTrace) {
        // Intentionally catching all errors to ensure notification continues
        // and errors are properly reported via Zone.handleUncaughtError
        Zone.current.handleUncaughtError(error, stackTrace);
      }
    }
  }

  void _onObserverFinalized(int id) {
    final entry = _entriesById.remove(id);
    if (entry != null) {
      _observers.remove(entry);
    }
  }
}
