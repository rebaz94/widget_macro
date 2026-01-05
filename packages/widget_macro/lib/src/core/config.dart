import 'package:macro_kit/macro_kit.dart';
import 'package:widget_macro/src/core/annotation.dart';

class WidgetMacroConfig extends MacroGlobalConfig {
  const WidgetMacroConfig({
    required this.stateFieldStrategy,
  });

  static WidgetMacroConfig defaultConfig = WidgetMacroConfig(
    stateFieldStrategy: StateFieldStrategy.public,
  );

  static WidgetMacroConfig fromJson(Map<String, dynamic> json) {
    @pragma('vm:prefer-inline')
    // ignore: unused_element
    T? parseField<T>(Object? value) {
      if (value is T) return value;
      return null;
    }

    return WidgetMacroConfig(
      stateFieldStrategy: MacroExt.decodeEnum(
        StateFieldStrategy.values,
        json['state_field_strategy'] ?? '',
        unknownValue: StateFieldStrategy.public,
      ),
    );
  }

  /// How to handle private property names (starting with _)
  ///
  /// - [StateFieldStrategy.public] (default): `_todos` → `todosState`
  /// - [StateFieldStrategy.private]: `_todos` → `_todosState`
  /// - [StateFieldStrategy.keep]: `_todos` → `_todosState`
  final StateFieldStrategy stateFieldStrategy;
}

/// Strategy for handling private property names
enum StateFieldStrategy {
  /// Always generate public state fields.
  ///
  /// If the original field starts with `_`, the underscore is removed.
  ///
  /// Example:
  /// ```dart
  /// @state
  /// int get _todos => 0;
  /// // → todosState
  /// ```
  public,

  /// Always generate private state fields.
  ///
  /// If the original field does not start with `_`, an underscore is added.
  ///
  /// Example:
  /// ```dart
  /// @state
  /// int get _todos => 0;
  /// // → _todosState
  /// ```
  private,

  /// Preserve the original field's privacy.
  ///
  /// Fields starting with `_` remain private, and public fields remain public.
  ///
  /// Example:
  /// ```dart
  /// @state
  /// int get _todos => 0;
  /// // → _todosState
  ///
  /// @state
  /// int get todos => 0;
  /// // → todosState
  /// ```
  keep
  ;

  const StateFieldStrategy();

  /// Resolves the final visibility for a field
  ///
  /// Precedence:
  /// 1. Local flags (public / private)
  /// 2. Global strategy
  bool resolveIsPublic({
    required int flags,
    required String fieldName,
  }) {
    // ── 1. Local override ─────────────────────────────
    if ((flags & StateFlags.public) != 0) return true;
    if ((flags & StateFlags.private) != 0) return false;

    // ── 2. Global strategy ────────────────────────────
    switch (this) {
      case StateFieldStrategy.public:
        return true;

      case StateFieldStrategy.private:
        return false;

      case StateFieldStrategy.keep:
        // Respect original field privacy
        return !fieldName.startsWith('_');
    }
  }

  String getFieldName(String originalName, int propValueFlags) {
    final isPrivateField = originalName.startsWith('_');

    final isPublic = resolveIsPublic(
      flags: propValueFlags,
      fieldName: originalName,
    );

    if (isPublic) {
      return isPrivateField ? originalName.substring(1) : originalName;
    } else {
      return isPrivateField ? originalName : '_$originalName';
    }
  }
}
