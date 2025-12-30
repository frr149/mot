# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2024-12-30

### Added

- `Beacon` mixin for observable models
  - `observe()` with "self, not this" pattern
  - `removeObserver()` for manual cleanup (optional)
  - `hasObserver()` to check registration
  - `notify()` for microqueue-based notifications
  - `notifySync()` for synchronous testing
- `BeaconField<T>` for observable fields
  - Automatic notification on value change
  - Equality check to avoid redundant notifications
- Automatic cleanup via WeakReference + Finalizer
- Notification coalescing via microtask queue
- Error isolation (one failing callback doesn't stop others)
