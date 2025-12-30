/// An entry representing an observer subscription.
///
/// Stores a [WeakReference] to the observer and the callback to invoke.
/// This allows automatic cleanup when the observer is garbage collected.
class ObserverEntry<T extends Object> {
  /// Creates an observer entry.
  ///
  /// The [observer] is stored as a weak reference, allowing it to be
  /// garbage collected even while subscribed.
  ObserverEntry({
    required T observer,
    required this.callback,
    required this.id,
  }) : _observerRef = WeakReference(observer);

  final WeakReference<T> _observerRef;

  /// The callback to invoke when notifying this observer.
  ///
  /// Receives the observer as parameter (the "self, not this" pattern).
  final void Function(T self) callback;

  /// Unique identifier for this entry, used by the Finalizer.
  final int id;

  /// Returns true if the observer is still alive (not garbage collected).
  bool get isAlive => _observerRef.target != null;

  /// Attempts to invoke the callback.
  ///
  /// Returns true if the observer was alive and the callback was invoked.
  /// Returns false if the observer has been garbage collected.
  bool tryInvoke() {
    final observer = _observerRef.target;
    if (observer == null) return false;
    callback(observer);
    return true;
  }
}
