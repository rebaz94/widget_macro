import 'package:collection/collection.dart';
import 'package:macro_kit/macro_kit.dart';
import 'package:widget_macro/src/core/annotation.dart';

enum AnnotationType { state, computed, env, none }

enum EnvType { read, watch, custom }

class StateFieldInfo {
  StateFieldInfo({
    required this.field,
    required this.isFinalField,
    required this.isGetter,
    required this.isNullable,
    required this.isPrimitive,
    required this.propValueFlags,
  });

  final MacroProperty field;
  final bool isFinalField;
  final bool isGetter;
  final bool isNullable;
  final bool isPrimitive;
  final int propValueFlags;

  late final String valueNotifierType = isTracked ? 'TrackedValueNotifier' : 'ValueNotifier';

  bool get isTracked => (propValueFlags & Prop.trackedFlag) != 0;

  bool get isParam => (propValueFlags & Prop.paramFlag) != 0;

  String notifierType(String dcp) {
    return '$valueNotifierType<${field.getDartType(dcp)}>';
  }
}

class ComputedFieldInfo {
  ComputedFieldInfo({required this.field, required this.depends, required this.isTrackedValueNotifier});

  final MacroProperty field;
  final List<String> depends;
  final bool isTrackedValueNotifier;

  String notifierType(String dcp, String fcp) {
    final notifierTypeName = isTrackedValueNotifier ? 'TrackedValueNotifier' : '${fcp}ValueNotifier';
    return '$notifierTypeName<${field.getDartType(dcp)}>';
  }
}

class EnvFieldInfo {
  EnvFieldInfo({required this.field, required this.envType, required this.customEnvDartType});

  final MacroProperty field;
  final EnvType envType;
  final String? customEnvDartType;

  /// name of the field without Env suffix
  late final cleanName = field.name.endsWith('Env') ? field.name.substring(0, field.name.length - 3) : field.name;

  String getUnwrappedCustomEnvType(String dcp) {
    return customEnvDartType ?? field.typeArguments?.firstOrNull?.getDartType(dcp) ?? 'InvalidType';
  }
}

class EffectMethodInfo {
  EffectMethodInfo({required this.method, required this.depends, required this.isEnv});

  final MacroMethod method;
  final List<String> depends;
  final bool isEnv;
}

class QueryMethodInfo {
  QueryMethodInfo({
    required this.method,
    required this.depends,
    this.debounceDuration,
    this.useRefreshing,
    this.tracked,
  });

  final MacroMethod method;
  final List<String> depends;
  final String? debounceDuration;
  final bool? useRefreshing;
  final bool? tracked;
}

(AnnotationType, MacroKey?) getAnnotationType(MacroProperty field) {
  for (final key in field.keys ?? const <MacroKey>[]) {
    final name = key.name;
    if (name == 'Prop') return (AnnotationType.state, key);
    if (name == 'Computed') return (AnnotationType.computed, key);
    if (name == 'Env') return (AnnotationType.env, key);
  }
  return (AnnotationType.none, null);
}

String getDefaultValue(MacroProperty field) {
  if (field.isNullable) return 'null';

  return switch (field.typeInfo) {
    TypeInfo.int || TypeInfo.double || TypeInfo.num => '0',
    TypeInfo.string => "''",
    TypeInfo.boolean => 'false',
    TypeInfo.iterable => 'Iterable.empty()',
    TypeInfo.list => '[]',
    TypeInfo.map || TypeInfo.set => '{}',
    TypeInfo.datetime => 'DateTime()',
    TypeInfo.duration => 'Duration.zero',
    TypeInfo.bigInt => 'BigInt.zero',
    TypeInfo.uri => 'Uri()',
    TypeInfo.symbol => '#_',
    _ => 'null',
  };
}

bool isPrimitiveOrNullable(MacroProperty prop) {
  if (prop.isNullable) return true;

  return switch (prop.typeInfo) {
    TypeInfo.int ||
    TypeInfo.double ||
    TypeInfo.num ||
    TypeInfo.string ||
    TypeInfo.boolean ||
    TypeInfo.iterable ||
    TypeInfo.list ||
    TypeInfo.map ||
    TypeInfo.set ||
    TypeInfo.datetime ||
    TypeInfo.duration ||
    TypeInfo.bigInt ||
    TypeInfo.uri ||
    TypeInfo.symbol => true,
    _ => false,
  };
}

(String, String, String) getImportPrefix(MacroState state) {
  final dartCorePrefix = state.imports["import dart:core"] ?? '';
  final flutterCorePrefix =
      state.imports["import package:flutter/foundation.dart"] ??
      state.imports["import package:flutter/material.dart"] ??
      state.imports["import package:flutter/cupertino.dart"] ??
      '';
  final providerPrefix = state.imports["import package:provider/provider.dart"] ?? '';

  return (dartCorePrefix, flutterCorePrefix, providerPrefix);
}

StateFieldInfo parseStateField(MacroProperty prop, MacroKey key) {
  final isFinalField = prop.modifier.isFinal || prop.modifier.isFieldFormalParameter;
  final isGetter = prop.modifier.isGetProperty;

  return StateFieldInfo(
    field: prop,
    isFinalField: isFinalField,
    isGetter: isGetter,
    isNullable: prop.isNullable,
    isPrimitive: isPrimitiveOrNullable(prop),
    propValueFlags: key.properties.firstWhereOrNull((p) => p.name == 'val')?.asIntConstantValue() ?? 0,
  );
}

EffectMethodInfo? parseEffectMethod(MacroMethod prop) {
  final (depends, isEnv, _) = _extractDependsListAnnotation(
    MacroProperty(
      name: '',
      importPrefix: '',
      type: '',
      typeInfo: TypeInfo.function,
      keys: prop.keys, // only need keys
    ),
    'Effect',
  );
  if (depends == null) {
    return null;
  }

  return EffectMethodInfo(method: prop, depends: depends, isEnv: isEnv);
}

QueryMethodInfo? parseQueryMethod(MacroMethod prop) {
  final (depends, debounce, useRefreshing, tracked) = _extractQueryDependsListAnnotation(
    MacroProperty(
      name: '',
      importPrefix: '',
      type: '',
      typeInfo: TypeInfo.function,
      keys: prop.keys, // only need keys
    ),
  );
  if (depends == null) {
    return null;
  }

  return QueryMethodInfo(
    method: prop,
    depends: depends,
    debounceDuration: debounce,
    useRefreshing: useRefreshing,
    tracked: tracked,
  );
}

(List<String>?, bool, bool) _extractDependsListAnnotation(MacroProperty prop, String annotationName) {
  return prop.cacheFirstKeyInto(
    keyName: annotationName,
    convertFn: (key) {
      final props = Map.fromEntries(key.properties.map((e) => MapEntry(e.name, e)));
      final depends = (props['deps']?.constantValue as List?)?.map((e) => e as String).toList() ?? const [];
      final env = props['env']?.asBoolConstantValue() ?? false;
      final tracked = props['tracked']?.asBoolConstantValue() ?? false;

      return (depends, env, tracked);
    },
    defaultValue: (null, false, false),
  );
}

(List<String>?, String?, bool?, bool?) _extractQueryDependsListAnnotation(MacroProperty prop) {
  return prop.cacheFirstKeyInto(
    keyName: 'Query',
    convertFn: (key) {
      final props = Map.fromEntries(key.properties.map((e) => MapEntry(e.name, e)));
      final depends = (props['deps']?.constantValue as List?)?.map((e) => e as String).toList() ?? const [];
      final debounce = MacroProperty.toLiteralValue(props['debounce']);
      final useRefreshing = props['useRefreshing']?.asBoolConstantValue();
      final tracked = props['tracked']?.asBoolConstantValue();

      return (depends, debounce, useRefreshing, tracked);
    },
    defaultValue: (null, null, null, null),
  );
}

ComputedFieldInfo parseComputedField(MacroProperty prop) {
  final (depends, _, tracked) = _extractDependsListAnnotation(prop, 'Computed');

  return ComputedFieldInfo(field: prop, depends: depends ?? const [], isTrackedValueNotifier: tracked);
}

EnvFieldInfo parseEnvField(MacroProperty prop, String dcp) {
  final (envType, customEnvDartType) = _extractEnvType(prop, dcp);

  return EnvFieldInfo(field: prop, envType: envType, customEnvDartType: customEnvDartType);
}

(EnvType, String? customEnvType) _extractEnvType(MacroProperty prop, String dcp) {
  return prop.cacheFirstKeyInto(
    keyName: 'Env',
    convertFn: (key) {
      final props = Map.fromEntries(key.properties.map((e) => MapEntry(e.name, e)));
      final customEnvDartType = props['type']?.asTypeValue()?.getDartType(dcp);
      final envType = switch (props['val']?.asIntConstantValue() ?? 0) {
        0 => EnvType.read,
        1 => EnvType.watch,
        2 => EnvType.custom,
        _ => EnvType.read,
      };
      return (envType, customEnvDartType);
    },
    defaultValue: (EnvType.custom, null),
  );
}
