import 'dart:async';

import 'package:macro_kit/macro_kit.dart';
import 'package:widget_macro/src/core/shared.dart';

/// {@template widget_state_macro}
/// **WidgetStateMacro** generates reactive state management for StatefulWidget without boilerplate.
///
/// Apply this macro to your State class to automatically generate:
/// - **Reactive state fields** - Wrapped in ValueNotifier for automatic UI updates
/// - **Computed properties** - Auto-recompute when dependencies change
/// - **Dependency injection** - Read, watch, or inject dependencies from context or custom sources
/// - **Side effects** - Functions that automatically track and react to state changes
/// - **Async queries** - Automatically managed asynchronous operations with loading/error states
///
/// ## Usage
///
/// 1. Create a standard StatefulWidget
/// 2. Apply `@widgetStateMacro` to your State class
/// 3. Extend from the generated base class (widget name prefixed with `_Base`)
///
/// ## Example
///
/// ```dart
/// // 1. Create your StatefulWidget as normal
/// class MyHomePage extends StatefulWidget {
///   const MyHomePage({
///     super.key,
///     required this.title,
///   });
///
///   final String title;
///
///   @override
///   State<MyHomePage> createState() => _MyHomePageState();
/// }
///
/// // 2. Apply macro and extend generated base class
/// @widgetStateMacro
/// class _MyHomePageState extends _BaseMyHomePageState {
///   // Observe widget parameters
///   @param
///   String get title => widget.title;
///
///   // Create reactive state (generates counterState notifier)
///   @state
///   int get counter => 0;
///
///   // Tracked state - keeps history of previous values
///   @tracked
///   int get trackedCounter => 0;
///
///   // Computed value that rebuilds when counter changes
///   @Computed.depends([#counterState])
///   int get doubleCounter => counterState.value * 2;
///
///   // Read dependency once from Provider/InheritedWidget
///   @Env.read()
///   MyCounter get myCounterEnv => myCounter;
///
///   // Watch dependency - rebuilds when it changes
///   @Env.watch()
///   MyCounter get myCounterWatchedEnv => myCounterWatched;
///
///   // Define without `Env` suffix works
///   @override
///   @Env.watch()
///   MyService get myService;
///
///   // Custom injection (e.g., get_it, service locator)
///   // Don't access this field directly to get the value.
///   // Use [myCounter3] instead, which caches the injected value.
///   // Accessing [myCounter3Env] directly will create a new instance each time.
///   @Env.custom()
///   MyCounter get myCounter3Env {
///     return getIt<MyCounter>();
///   }
///
///   // Custom injection with reactivity
///   // use [myCounter4] to get the value
///   @Env.custom()
///   ValueNotifier<MyCounter> get myCounter4Env {
///     return getIt();
///   }
///
///   // Custom notifier type for advanced use cases
///   // use [myCounter5] to get the value
///   @Env.customNotifier(MyCounter)
///   CustomValueNotifier get myCounter5Env {
///     return CustomValueNotifier(MyCounter(title: 'Custom'));
///   }
///
///   // Reactive query that runs when counter changes
///   @Query.by([#userIdState])
///   Future<UserData> fetchUserData() async {
///     final response = await api.getUser(userIdState.value);
///     return UserData.fromJson(response);
///   }
///   // Generates: Resource<UserData> fetchUserDataQuery
///   // Use: fetchUserDataQuery.data, fetchUserDataQuery.isLoading, etc.
///
///   // Query with debouncing for search
///   @state
///   String get searchTerm => '';
///
///   @Query.by([#searchTermState], debounce: Duration(milliseconds: 300))
///   Future<List<Result>> searchResults() async {
///     if (searchTermState.value.isEmpty) return [];
///     return await api.search(searchTermState.value);
///   }
///
///   // Side effect that runs when counter changes
///   @Effect.by([#counterState])
///   void logCounter() {
///     print('Counter: ${counterState.value}');
///
///     // Update state without re-triggering this effect
///     if (counterState.value > 10) {
///       untracked(
///         () => counterState.value = 0,
///         effectFns: [logCounter],
///         dependency: counterState,
///       );
///     }
///   }
///
///   // React to environment dependency changes,
///   // the argument is optional, can be removed
///   @Effect.env([#myCounter4Env])
///   void myCounter4EnvChanged(Map<String, Object?> oldValues) {
///     print('Environment myCounter4Env changed: ${myCounter4Env.value}');
///     print('Old value: ${oldValues['myCounter4Env']}');
///   }
///
///   // Using queries in build method
///   @override
///   Widget build(BuildContext context) {
///     return Scaffold(
///       body: fetchUserDataQuery.state((value) => value.when(
///         loading: () => CircularProgressIndicator(),
///         error: (error) => Text('Error: $error'),
///         data: (userData) => Text('User: ${userData.name}'),
///        ),
///       ),
///     );
///   }
/// }
/// ```
///
/// ## Key Features
///
/// ### State Management
/// - `@state` - Creates a ValueNotifier for reactive state
/// - `@tracked` - Creates a TrackedValueNotifier that tracks previous values
/// - `@param` - Tracks widget parameters for rebuilds
/// - `@Computed.depends([...])` - Derives values from state
///
/// ### Dependency Injection
/// - `@Env.read()` - One-time dependency access (no rebuilds)
/// - `@Env.watch()` - Reactive dependency (rebuilds on change)
/// - `@Env.custom()` - Custom injection source (get_it, etc.)
/// - `@Env.customNotifier(Type)` - Custom notifier implementation
///
/// ### Async Queries
/// - `@Query.by([...])` - Manages async operations with automatic re-execution on dependency changes
///   - Generated notifier named `{methodName}Query` with type `Resource<T>`
///   - Provides `isLoading`, `isRefreshing`, `hasData`, `hasError`, `data`, `error`
///   - Supports `debounce` for rate limiting
///   - Supports `useRefreshing` to control loading behavior during refresh
///   - Supports `tracked` to keep previous query results
///   - Call `refresh()` to manually trigger re-execution
///
/// ### Side Effects
/// - `@Effect.by([...])` - Runs when specified dependencies change
/// - `@Effect.env([...])` - Runs when specified environment dependencies change
/// - `untracked()` - Updates state without triggering effects
///
/// ## Important Notes
/// - The State class must extend `_Base{WidgetName}State` (auto-generated)
/// - Environment properties should end with `Env` suffix, or use `@override` with `super` access,
/// - **Never access environment fields directly** (e.g., `myServiceEnv`). Always use the
///   generated property without the `Env` suffix (e.g., `myService`) to access the cached/resolved value
/// - State fields automatically get a `State` suffix (e.g., `counter` → `counterState`)
/// - Query methods get a `Query` suffix (e.g., `fetchUser` → `fetchUserQuery`)
/// - **Never invoke query methods directly**. Always use the generated query notifier (e.g., `fetchUserQuery`) which manages execution automatically
/// {@endtemplate}
class WidgetStateMacro extends MacroGenerator {
  const WidgetStateMacro({
    super.capability = widgetStateMacroCapability,
    this.widgetName,
    this.privateWidget = false,
  });

  static WidgetStateMacro initialize(MacroConfig config) {
    final props = config.key.propertiesAsMap();

    return WidgetStateMacro(
      capability: config.capability,
      widgetName: props['widgetName']?.asStringConstantValue(),
      privateWidget: props['privateWidget']?.asBoolConstantValue() ?? false,
    );
  }

  /// The widget name this State class belongs to.
  ///
  /// Defaults to auto-detection from the State class name.
  /// Override this when the widget name cannot be inferred correctly.
  final String? widgetName;

  /// Whether the generated base widget should be private.
  ///
  /// When `true`, the base class is prefixed with `_`.
  /// Defaults to `false`.
  final bool privateWidget;

  @override
  final String suffixName = '';

  @override
  GeneratedType get generatedType => GeneratedType.clazz;

  static const _stateRef = r'$';

  @override
  Future<void> init(MacroState state) async {
    if (state.targetType != TargetType.clazz) {
      throw MacroException('WidgetMacro can only be applied on class but applied on: ${state.targetType}');
    }
  }

  @override
  Future<void> onClassFields(MacroState state, List<MacroProperty> fields) async {
    state.set('classFields', fields);
  }

  @override
  Future<void> onClassMethods(MacroState state, List<MacroMethod> methods) async {
    state.set('classMethods', methods);
  }

  @override
  Future<void> onGenerate(MacroState state) async {
    final classFields = state.getOrNull<List<MacroProperty>>('classFields') ?? const [];
    final classMethods = state.getOrNull<List<MacroMethod>>('classMethods') ?? const [];
    final className = state.targetName;
    final (dartCorePrefix, flutterCorePrefix, providerPrefix) = getImportPrefix(state);

    // Parse fields and methods
    final stateFields = <StateFieldInfo>[];
    final computedFields = <ComputedFieldInfo>[];
    final envFields = <EnvFieldInfo>[];
    final effectMethods = <EffectMethodInfo>[];
    final queryMethods = <QueryMethodInfo>[];

    for (final field in classFields) {
      final (annotation, key) = getAnnotationType(field);

      switch (annotation) {
        case AnnotationType.state:
          stateFields.add(parseStateField(field, key!));
        case AnnotationType.computed:
          computedFields.add(parseComputedField(field));
        case AnnotationType.env:
          envFields.add(parseEnvField(field, dartCorePrefix));
        case AnnotationType.none:
      }
    }

    for (final method in classMethods) {
      if (parseEffectMethod(method) case final method?) {
        effectMethods.add(method);
      }
    }

    for (final method in classMethods) {
      if (parseQueryMethod(method) case final method?) {
        queryMethods.add(method);
      }
    }

    final isPrivateState = state.targetName.startsWith('_');
    final widgetName = () {
      if (this.widgetName != null) return this.widgetName!;

      final isEndingWithState = state.targetName.endsWith('State');
      var name = state.targetName;
      if (isEndingWithState) {
        name = state.targetName.substring(0, state.targetName.length - 5);
      }

      if (privateWidget) {
        return name;
      } else if (isPrivateState) {
        return name.substring(1);
      } else {
        return name;
      }
    }();
    final baseStateClassName = '${isPrivateState ? '_' : ''}${FieldRename.pascal.renameOf('Base${state.targetName}')}';

    // Generate code
    final buff = StringBuffer();

    _generateStateClass(
      buff: buff,
      state: state,
      className: className,
      widgetClass: widgetName,
      baseStateClass: baseStateClassName,
      stateFields: stateFields,
      computedFields: computedFields,
      envFields: envFields,
      effectMethods: effectMethods,
      queryMethods: queryMethods,
      dartCorePrefix: dartCorePrefix,
      flutterCorePrefix: flutterCorePrefix,
      providerPrefix: providerPrefix,
    );

    state.reportGenerated(buff.toString(), canBeCombined: false);
  }

  void _generateStateClass({
    required StringBuffer buff,
    required MacroState state,
    required String className,
    required String widgetClass,
    required String baseStateClass,
    required List<StateFieldInfo> stateFields,
    required List<ComputedFieldInfo> computedFields,
    required List<EnvFieldInfo> envFields,
    required List<EffectMethodInfo> effectMethods,
    required List<QueryMethodInfo> queryMethods,
    required String dartCorePrefix,
    required String flutterCorePrefix,
    required String providerPrefix,
  }) {
    final dcp = dartCorePrefix;
    final fcp = flutterCorePrefix;

    final generatedStateFields = _generateStateFields(
      stateFields,
      computedFields,
      envFields,
      effectMethods,
      queryMethods,
      dcp,
      fcp,
      providerPrefix,
    );

    final template =
        '''
abstract class $baseStateClass extends ${fcp}State<$widgetClass> with BaseStateMixin<$widgetClass> {
  @${dcp}protected
  @${dcp}pragma('vm:prefer-inline')
  @${dcp}pragma('dart2js:tryInline')
  $className get $_stateRef => this as $className;
 
$generatedStateFields

  @${dcp}override
  void initState() {
    super.initState();
    //
  }

  void _initState() {
    final $_stateRef = this.$_stateRef;
${_generateInitStateBody(stateFields, computedFields, envFields, effectMethods, providerPrefix)}
  }

  @${dcp}override
  @${dcp}mustCallSuper
  void didChangeDependencies() {
    if (!didInitState) {
_initState();
didInitState = true;
super.didChangeDependencies();
return;
    }
${_generateDidChangeDependenciesBody(envFields, effectMethods, providerPrefix)}
    super.didChangeDependencies();
  }

  @${dcp}override
  void didUpdateWidget(${dcp}covariant $widgetClass old) {
${_generateDidUpdateWidgetBody(className, stateFields)}
    super.didUpdateWidget(old);
  }

  @${dcp}override
  void dispose() {
${_generateDisposeBody(stateFields, computedFields, queryMethods, envFields)}
    super.dispose();
  }
}''';

    buff.write(template);
  }

  String _generateStateFields(
    List<StateFieldInfo> stateFields,
    List<ComputedFieldInfo> computedFields,
    List<EnvFieldInfo> envFields,
    List<EffectMethodInfo> effectMethods,
    List<QueryMethodInfo> queryMethods,
    String dcp,
    String fcp,
    String providerPrefix,
  ) {
    final buff = StringBuffer();

    for (final fieldInfo in stateFields) {
      final field = fieldInfo.field;

      if (fieldInfo.isGetter && fieldInfo.isPrimitive) {
        final defaultValue = getDefaultValue(field);
        buff.write('\n  final ${field.name}State = ${fieldInfo.notifierType(dcp)}($defaultValue);');
      } else {
        buff.write('\n  late final ${field.name}State = ${fieldInfo.notifierType(dcp)}($_stateRef.${field.name});');
      }
    }

    for (final fieldInfo in computedFields) {
      final name = fieldInfo.field.name;
      final notifierType = fieldInfo.notifierType(dcp, fcp);

      buff.write('''

  late final $notifierType ${name}State = () {
    final state = $notifierType($_stateRef.$name);
${fieldInfo.depends.map((dep) => '    $dep.addListener(\$${name}DependsRebuild);').join('\n')}
    return state;
  }();

  void \$${name}DependsRebuild() {
    ${name}State.value = $_stateRef.$name;
  }''');
    }

    for (final methodInfo in queryMethods) {
      final name = methodInfo.method.name;
      final isPrivateMethod = name.startsWith('_');
      final sourceNotifierName = '${isPrivateMethod ? '_\$${name.substring(1)}' : '\$$name'}Source';
      final queryName = '${isPrivateMethod ? name.substring(1) : name}Query';
      final sourceFnChangedName = '${sourceNotifierName}Changed';

      final methodRetType = methodInfo.method.returns.firstOrNull;
      final String resourceType;
      bool isStream = false;
      if (methodRetType == null || methodRetType.typeInfo == TypeInfo.voidType) {
        resourceType = 'void';
      } else {
        isStream = methodRetType.typeInfo == TypeInfo.stream;
        resourceType = switch (methodRetType.typeInfo) {
          TypeInfo.future ||
          TypeInfo.stream => methodRetType.typeArguments?.firstOrNull?.getDartType(dcp) ?? '${dcp}Object?',
          _ => methodRetType.getDartType(dcp),
        };
      }

      buff.write('''

  final ${fcp}ValueNotifier<${dcp}int> $sourceNotifierName = ${fcp}ValueNotifier(0);
  late final Resource<$resourceType> $queryName = (){
    ${methodInfo.depends.map((dep) => '    $dep.addListener($sourceFnChangedName);').join('\n')}
    return Resource${isStream ? '.stream' : ''}(
      $_stateRef.$name,
      source: $sourceNotifierName,
      useRefreshing: ${methodInfo.useRefreshing ?? true},
      debounceDelay: ${methodInfo.debounceDuration ?? 'null'},
      trackPreviousState: ${methodInfo.tracked != false},
    );
  }();
  void $sourceFnChangedName() {
    $sourceNotifierName.value++;
  }''');
    }

    for (final fieldInfo in envFields) {
      // name without env suffix
      final cleanName = fieldInfo.cleanName;

      switch (fieldInfo.envType) {
        case EnvType.read:
          buff.write(
            '\n  late final ${fieldInfo.field.getDartType(dcp)} $cleanName = ${providerPrefix}Provider.of(context, listen: false);',
          );
        case EnvType.watch:
          buff.write('\n  late ${fieldInfo.field.getDartType(dcp)} $cleanName;');
        case EnvType.custom:
          if (!fieldInfo.field.type.startsWith('ValueNotifier') && fieldInfo.customEnvDartType == null) {
            // otherwise use regular value without listening to change
            buff.write('\n  late ${fieldInfo.field.getDartType(dcp)} $cleanName = $_stateRef.${fieldInfo.field.name};');
            continue;
          }

          // if field type is value notifier or class with extended value notifier that
          // explicitly provided the inner env type
          final baseType = fieldInfo.getUnwrappedCustomEnvType(dcp);
          final fieldNameWithEnv = fieldInfo.field.name;
          final effectEnv = effectMethods.where(
            (e) => e.isEnv && (e.depends.contains(fieldNameWithEnv) || e.depends.contains(cleanName)),
          );

          final onChangeBody = [
            if (effectEnv.isNotEmpty && effectEnv.any((e) => e.method.params.isNotEmpty))
              "final payload = {'${fieldInfo.field.name}': $cleanName};",
            '$cleanName = \$${cleanName}Notifier.value;',
            effectEnv
                .map(
                  (effect) => '$_stateRef.${effect.method.name}(${effect.method.params.isNotEmpty ? 'payload' : ''});',
                )
                .toSet()
                .join('\n'),
          ];

          buff.write('''

  late final ValueNotifier<$baseType> \$${cleanName}Notifier = () {
    final notifier = $_stateRef.${fieldInfo.field.name};
    notifier.addListener(\$${cleanName}Changed);
    return notifier;
  }();
  late $baseType $cleanName = \$${cleanName}Notifier.value;

  void \$${cleanName}Changed() {
    ${onChangeBody.join('\n')}
    setState(() {});
  }''');
      }
    }

    return buff.toString();
  }

  String _generateInitStateBody(
    List<StateFieldInfo> stateFields,
    List<ComputedFieldInfo> computedFields,
    List<EnvFieldInfo> envFields,
    List<EffectMethodInfo> effectMethods,
    String providerPrefix,
  ) {
    final buff = StringBuffer();

    for (final fieldInfo in stateFields) {
      if (fieldInfo.isGetter) {
        final name = fieldInfo.field.name;
        buff.write('\n    ${name}State.value = $_stateRef.$name;');
      }
    }

    // trigger late initialization
    buff.writeln();
    for (final fieldInfo in envFields) {
      if (fieldInfo.envType == EnvType.watch) {
        final cleanName = fieldInfo.cleanName;
        buff.write('\n\n    $cleanName = ${providerPrefix}Provider.of(context, listen: true);');
      } else if (fieldInfo.field.type.startsWith('ValueNotifier') || fieldInfo.customEnvDartType != null) {
        buff.write('\n    ${fieldInfo.cleanName};');
      }
    }

    // trigger late initialization
    buff.writeln();
    for (final fieldInfo in computedFields) {
      final name = fieldInfo.field.name;
      buff.write('\n    ${name}State;');
    }

    buff.writeln();
    for (final methodInfo in effectMethods) {
      if (methodInfo.isEnv) continue;
      for (final dep in methodInfo.depends) {
        buff.write('\n    createEffect($dep, $_stateRef.${methodInfo.method.name});');
      }
    }

    return buff.toString();
  }

  String _generateDidChangeDependenciesBody(
    List<EnvFieldInfo> envFields,
    List<EffectMethodInfo> effectMethods,
    String providerPrefix,
  ) {
    var buff = StringBuffer();

    final watchEnvs = envFields.where((e) => e.envType == EnvType.watch).toList();
    final List<EffectMethodInfo> effectCalls = [];
    List<String>? oldValuesVars;

    for (final field in watchEnvs) {
      final cleanName = field.cleanName;
      final fieldNameWithEnv = field.field.name;
      final effects = effectMethods
          .where((e) => e.isEnv && (e.depends.contains(fieldNameWithEnv) || e.depends.contains(cleanName)))
          .toList();
      effectCalls.addAll(effects);

      if (effects.isNotEmpty) {
        (oldValuesVars ??= []).add("'$fieldNameWithEnv': $cleanName,");
      }

      buff.write('\n    $cleanName = ${providerPrefix}Provider.of(context, listen: true);');
    }

    buff.writeln();
    if (effectCalls.any((e) => e.method.params.isNotEmpty)) {
      buff = StringBuffer('\n    final payload = {${oldValuesVars?.join(', ') ?? ''}};\n\n$buff');
    }

    if (effectCalls.isNotEmpty) {
      buff.write(
        effectCalls
            .map(
              (effect) => '    $_stateRef.${effect.method.name}(${effect.method.params.isNotEmpty ? 'payload' : ''});',
            )
            .toSet()
            .join('\n'),
      );
    }

    return buff.toString();
  }

  String _generateDidUpdateWidgetBody(String className, List<StateFieldInfo> stateFields) {
    final buff = StringBuffer();

    for (final fieldInfo in stateFields.where((f) => f.isParam)) {
      final name = fieldInfo.field.name;
      buff.write('''
    if (old.$name != widget.$name) {
${name}State.value = widget.$name;
    }
''');
    }

    return buff.toString();
  }

  String _generateDisposeBody(
    List<StateFieldInfo> stateFields,
    List<ComputedFieldInfo> computedFields,
    List<QueryMethodInfo> queryMethods,
    List<EnvFieldInfo> envFields,
  ) {
    final buff = StringBuffer();

    for (final fieldInfo in stateFields) {
      buff.write('\n    ${fieldInfo.field.name}State.dispose();');
    }

    for (final fieldInfo in computedFields) {
      buff.write('\n    ${fieldInfo.field.name}State.dispose();');
    }

    for (final methodInfo in queryMethods) {
      final name = methodInfo.method.name;
      final isPrivateMethod = name.startsWith('_');
      final sourceNotifierName = '${isPrivateMethod ? '_\$${name.substring(1)}' : '\$$name'}Source';
      final queryName = '${isPrivateMethod ? name.substring(1) : name}Query';

      buff.write('\n    $queryName.dispose();');
      buff.write('\n    $sourceNotifierName.dispose();');
    }

    for (final fieldInfo in envFields.where((e) => e.envType == EnvType.custom)) {
      if (!fieldInfo.field.type.startsWith('ValueNotifier') && fieldInfo.customEnvDartType == null) {
        continue;
      }

      final cleanName = fieldInfo.cleanName;
      buff.write('\n    \$${cleanName}Notifier.removeListener(\$${cleanName}Changed);');
    }

    return buff.toString();
  }
}

/// {@macro widget_state_macro}
const widgetStateMacro = Macro(
  WidgetStateMacro(capability: widgetStateMacroCapability),
);

/// Base capability for [WidgetStateMacro]
const widgetStateMacroCapability = MacroCapability(
  classFields: true,
  filterClassInstanceFields: true,
  filterClassFieldMetadata: 'Prop,Computed,Env',
  filterClassIgnoreSetterOnly: true,
  filterClassIncludeAnnotatedFieldOnly: true,
  classMethods: true,
  filterClassInstanceMethod: true,
  filterClassMethodMetadata: 'Effect,Query',
  filterClassIncludeAnnotatedMethodOnly: true,
  filterMethods: '*',
);
