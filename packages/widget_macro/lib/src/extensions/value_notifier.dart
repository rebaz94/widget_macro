import 'dart:async';

import 'package:flutter/widgets.dart';

/// Extension methods for [ValueNotifier] to simplify reactive UI building.
///
/// These methods provide convenient wrappers around [ValueListenableBuilder]
/// for building widgets that automatically rebuild when the notifier changes.
///
/// **Performance Note:** All methods are marked for inlining, so using these
/// functions does not cause any performance overhead compared to using
/// [ValueListenableBuilder] directly.
extension ValueNotifierX<T> on ValueNotifier<T> {
  /// Builds a widget that rebuilds when this notifier's value changes.
  ///
  /// Provides only the current value to the builder function.
  ///
  /// Example:
  /// ```dart
  /// counterState.state((value) => Text('$value'))
  /// ```
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  Widget state(Widget Function(T value) build) {
    return ValueListenableBuilder(
      valueListenable: this,
      builder: (context, value, child) => build(value),
    );
  }

  /// Builds a widget that rebuilds when this notifier's value changes.
  ///
  /// Provides [BuildContext], current value, and optional child to the builder.
  /// The [child] parameter can be used for widgets that don't need to rebuild.
  ///
  /// Example:
  /// ```dart
  /// counterState.watch(
  ///   (context, value, child) => Text('$value'),
  ///   child: const Icon(Icons.star),
  /// )
  /// ```
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  Widget watch(Widget Function(BuildContext context, T value, Widget? child) build, {Widget? child}) {
    return ValueListenableBuilder(
      valueListenable: this,
      builder: build,
      child: child,
    );
  }
}

/// Extension that adds the `until` method to [ValueNotifier] classes.
extension Until<T> on ValueNotifier<T> {
  /// Returns the future that completes when the [condition] evaluates to true.
  /// If the [condition] is already true, it completes immediately.
  ///
  /// The [timeout] parameter specifies the maximum time to wait for the
  /// condition to be met. If provided and the timeout is reached before the
  /// condition is met, the future will complete with a [TimeoutException].
  FutureOr<T> until(
    bool Function(T value) condition, {
    Duration? timeout,
  }) {
    if (condition(value)) return value;

    final completer = Completer<T>();
    Timer? timer;
    late void Function() fnListener;

    void dispose() {
      removeListener(fnListener);
      timer?.cancel();
    }

    fnListener = () {
      if (condition(value)) {
        dispose();
        completer.complete(value);
      }
    };

    // Start timeout timer if specified
    if (timeout != null) {
      timer = Timer(timeout, () {
        if (!completer.isCompleted) {
          dispose();
          completer.completeError(TimeoutException(null, timeout));
        }
      });
    }

    return completer.future;
  }
}

/// A [ValueNotifier] that tracks the previous value before each update.
///
/// This is useful for scenarios where you need to:
/// - Compare current and previous values
/// - Track value changes for animations or transitions
/// - Log or debug state changes
///
/// The previous value is accessible through the [previousValue] getter.
///
/// Example:
/// ```dart
/// @tracked
/// int get counter => 0;
///
/// // Later in code:
/// print('Current: ${counterState.value}');
/// print('Previous: ${counterState.previousValue}');
///
/// // Update value
/// counterState.value = 5;
/// // Now: value = 5, previousValue = 0
/// ```
///
/// **Note:** The [previousValue] is `null` initially until the first value change occurs.
class TrackedValueNotifier<T> extends ValueNotifier<T> {
  TrackedValueNotifier(super.value);

  T? _previousValue;

  /// The previous value before the last update.
  ///
  /// Returns `null` if no value change has occurred yet.
  T? get previousValue => _previousValue;

  @override
  set value(T newValue) {
    _previousValue = value;
    super.value = newValue;
  }
}
