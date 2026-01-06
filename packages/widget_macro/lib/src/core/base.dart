import 'dart:async';

import 'package:flutter/widgets.dart';

/// Base state mixin that added to generated state class
mixin BaseStateMixin<T extends StatefulWidget> on State<T> {
  bool initStateCalled = false;
  Set<void Function()> $untrackedFns = const {};
  EffectFnInfo? $effectFnInfo;

  void createEffect(
    ValueNotifier<Object?> notifier,
    void Function() fn,
  ) {
    $effectFnInfo ??= {};
    final effectFn = effectListener(fn);
    $effectFnInfo![fn] = effectFn;
    notifier.addListener(effectFn);
  }

  void Function() effectListener(void Function() fn) {
    return () {
      if ($untrackedFns.contains(fn)) return;

      fn();
    };
  }

  void addEffect(
    ValueNotifier<Object?> dependency,
    void Function() fn,
  ) {
    removeEffect(dependency, fn);
    createEffect(dependency, fn);
  }

  void removeEffect(
    ValueNotifier<Object?> dependency,
    void Function() fn,
  ) {
    final effect = $effectFnInfo?.remove(fn);
    if (effect == null) return;

    dependency.removeListener(effect);
  }

  void untracked(
    void Function() fn, {
    void Function()? effectFn,
    List<void Function()>? effectFns,
  }) async {
    void update(bool untracked) {
      if (effectFns != null) {
        for (final effectFn in effectFns) {
          if (untracked) {
            $untrackedFns.add(effectFn);
          } else {
            $untrackedFns.remove(effectFn);
          }
        }
      } else if (effectFn != null) {
        if (untracked) {
          $untrackedFns.add(effectFn);
        } else {
          $untrackedFns.remove(effectFn);
        }
      }
    }
    if ($untrackedFns == const <void Function()>{}) {
      $untrackedFns = {};
    }

    // this make notifier call all listener before un-tracking
    // if we don't do that, some event maybe shown in one effect but hidden from other
    scheduleMicrotask(() {
      update(true);
      try {
        fn();
      } catch (_) {
        update(false);
        rethrow;
      }
      update(false);
    });
  }

  @override
  @mustCallSuper
  void dispose() {
    $effectFnInfo?.clear();
    $effectFnInfo = null;
    super.dispose();
  }
}

@protected
typedef EffectFnInfo = Map<void Function(), void Function()>;

@protected
final class MacroEffectUtils {
  MacroEffectUtils._();

  static void createEffect(
    ValueNotifier<Object?> notifier,
    void Function() fn,
    EffectFnInfo effectFnInfo,
    Set<void Function()> untrackedFns,
  ) {
    final effectFn = effectListener(untrackedFns, fn);
    effectFnInfo[fn] = effectFn;
    notifier.addListener(effectFn);
  }

  static void Function() effectListener(Set<void Function()> untrackedFns, void Function() fn) {
    return () {
      if (untrackedFns.contains(fn)) return;

      fn();
    };
  }

  static void addEffect(
    ValueNotifier<Object?> dependency,
    void Function() fn,
    EffectFnInfo effectFnInfo,
    Set<void Function()> untrackedFns,
  ) {
    removeEffect(dependency, fn, effectFnInfo);
    createEffect(dependency, fn, effectFnInfo, untrackedFns);
  }

  static void removeEffect(
    ValueNotifier<Object?> dependency,
    void Function() fn,
    EffectFnInfo? effectFnInfo,
  ) {
    final effect = effectFnInfo?.remove(fn);
    if (effect == null) return;

    dependency.removeListener(effect);
  }

  static void untracked(
    void Function() fn, {
    void Function()? effectFn,
    List<void Function()>? effectFns,
    required EffectFnInfo? effectFnInfo,
    required Set<void Function()> untrackedFns,
  }) async {
    void update(bool untracked) {
      if (effectFns != null) {
        for (final effectFn in effectFns) {
          if (untracked) {
            untrackedFns.add(effectFn);
          } else {
            untrackedFns.remove(effectFn);
          }
        }
      } else if (effectFn != null) {
        if (untracked) {
          untrackedFns.add(effectFn);
        } else {
          untrackedFns.remove(effectFn);
        }
      }
    }

    // this make notifier call all listener before un-trucking
    // if we don't do that, some event maybe shown in one effect but hidden from other
    scheduleMicrotask(() {
      update(true);
      try {
        fn();
      } catch (_) {
        update(false);
        rethrow;
      }
      update(false);
    });
  }
}
