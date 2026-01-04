import 'dart:async';

/// Signature of callbacks that have no arguments and return no data.
typedef VoidCallback = void Function();

/// Error callback
typedef ErrorCallback = void Function(Object error);

/// The callback fired by the observer
typedef ObserveCallback<T> = void Function(T? previousValue, T value);

/// Creates a delayer scheduler with the given [duration].
Timer Function(void Function()) createDelayedScheduler(Duration duration) =>
    (fn) => Timer(duration, fn);

/// {@template DebounceOperation}
/// The operation that must be performed is the [callback]
/// It will be performed when the [timer] completes and only
/// if the timer has not been cancelled before
/// {@endtemplate}
class DebounceOperation {
  /// {@macro DebounceOperation}
  const DebounceOperation(this.callback, this.timer);

  /// The callback to be performed
  final VoidCallback callback;

  /// The timer that will trigger the callback
  final Timer timer;
}

/// A static class for handling method call debouncing.
abstract class Debouncer {
  static final Map<Object, DebounceOperation> _operations = {};

  /// Will delay the execution of [callback] with the given [duration]. If
  /// another call to `debounce()` with the same [operationId] happens within
  /// this duration, the first call will be cancelled and the debouncer will
  /// start waiting for another [duration] before executing [callback].
  ///
  /// [operationId] is any arbitrary Object, and is used to identify this
  /// particular debounce operation in subsequent calls to `debounce()` or
  /// `cancel()`. I recommend using `#someString` (a Symbol).
  static void debounce(
    Object operationId,
    Duration duration,
    VoidCallback callback,
  ) {
    _operations[operationId]?.timer.cancel();

    _operations[operationId] = DebounceOperation(
      callback,
      Timer(duration, () {
        fire(operationId);
      }),
    );
  }

  /// Fires the callback associated with [operationId] immediately. It also
  /// cancels the debounce timer.
  static void fire(Object operationId) {
    _operations[operationId]?.timer.cancel();
    final operation = _operations.remove(operationId);
    operation?.callback();
  }

  /// Cancels any active debounce operation with the given [operationId].
  static void cancel(Object operationId) {
    _operations[operationId]?.timer.cancel();
    _operations.remove(operationId);
  }

  /// Cancels all active debouncers.
  static void cancelAll() {
    for (final operation in _operations.values) {
      operation.timer.cancel();
    }
    _operations.clear();
  }

  /// Returns the number of active debouncers (debouncers that haven't yet
  /// called their callbacks).
  static int count() {
    return _operations.length;
  }
}
