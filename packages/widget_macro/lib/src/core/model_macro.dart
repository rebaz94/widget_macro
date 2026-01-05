import 'dart:async';

import 'package:macro_kit/macro_kit.dart';
import 'package:widget_macro/src/core/config.dart';
import 'package:widget_macro/src/core/shared.dart';

/// {@template model_macro}
/// **ModelMacro** generates reactive state management for regular classes without boilerplate.
///
/// Apply this macro to a regular class to automatically generate:
/// - **Reactive state fields** - Wrapped in ValueNotifier for automatic updates
/// - **Computed properties** - Auto-recompute when dependencies change
/// - **Dependency injection** - Inject dependencies from custom sources (no BuildContext required)
/// - **Side effects** - Functions that automatically track and react to state changes
/// - **Async queries** - Automatically managed asynchronous operations with loading/error states
///
/// ## Usage
///
/// 1. Create a regular class
/// 2. Apply `@modelMacro` to your class
/// 3. Mix in the generated model (class name suffixed with `Model`)
///
/// ## Example
///
/// ```dart
/// // 1. Create your class and apply macro
/// @modelMacro
/// class MyCounter with MyCounterModel {
///   MyCounter() {
///     initState();
///   }
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
///   // Custom injection (e.g., get_it, service locator)
///   // Note: Only @Env.custom() is supported (no BuildContext available)
///   @Env.custom()
///   MyService get myServiceEnv {
///     return getIt<MyService>();
///   }
///
///   // Custom injection with reactivity
///   @Env.custom()
///   ValueNotifier<MyService> get myService2Env {
///     return getIt();
///   }
///
///   // Custom notifier type for advanced use cases
///   @Env.customNotifier(MyService)
///   CustomValueNotifier get myService3Env {
///     return CustomValueNotifier(getIt<MyService>());
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
///   // Query with debouncing for API calls
///   @state
///   String get searchTerm => '';
///
///   @Query.by([#searchTermState], debounce: Duration(milliseconds: 300))
///   Future<List<Result>> searchResults() async {
///     if (searchTermState.value.isEmpty) return [];
///     return await api.search(searchTermState.value);
///   }
///
///   // Query with tracked previous results
///   @Query.by([#counterState], tracked: true)
///   Future<Stats> fetchStats() async {
///     return await api.getStats(counterState.value);
///   }
///   // Access: fetchStatsQuery.data and fetchStatsQuery.previous
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
///   @Effect.env([#myServiceEnv])
///   void myServiceEnvChanged(Map<String, Object?> oldValues) {
///     print('Environment myServiceEnv changed: ${myServiceEnv.value}');
///     print('Old value: ${oldValues['myServiceEnv']}');
///   }
///
///   // Using queries in methods
///   void checkData() {
///     if (fetchUserDataQuery.value.isLoading) {
///       print('Loading user data...');
///     } else if (fetchUserDataQuery.value.hasError) {
///       print('Error: ${fetchUserDataQuery.error}');
///     } else if (fetchUserDataQuery.value.hasData) {
///       print('User: ${fetchUserDataQuery.data.name}');
///     }
///
///     // Manually refresh
///     fetchUserDataQuery.refresh();
///   }
/// }
/// ```
///
/// ## Key Features
///
/// ### State Management
/// - `@state` - Creates a ValueNotifier for reactive state
/// - `@tracked` - Creates a TrackedValueNotifier that tracks previous values
/// - `@Computed.depends([...])` - Derives values from state
///
/// ### Dependency Injection
/// - `@Env.custom()` - Custom injection source (get_it, etc.)
/// - `@Env.customNotifier(Type)` - Custom notifier implementation
///
/// **Note:** Only `@Env.custom()` variants are supported in models since no BuildContext is available.
/// Use `@Env.read()` and `@Env.watch()` only in WidgetStateMacro.
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
/// - The class must mix in `{ClassName}Model` (auto-generated)
/// - Must call `initState()` in constructor to initialize reactive state
/// - Call `dispose()` when done to clean up resources
/// - Environment properties should end with `Env` suffix
/// - State fields automatically get a `State` suffix (e.g., `counter` → `counterState`)
/// - Query methods get a `Query` suffix (e.g., `fetchUser` → `fetchUserQuery`)
/// - Models can be shared across multiple widgets for app-wide state management
/// - **Never access environment fields directly** (e.g., `myServiceEnv`). Always use the generated property without the `Env` suffix (e.g., `myService`) to access the cached/resolved value
/// - **Never invoke query methods directly**. Always use the generated query notifier (e.g., `fetchUserDataQuery`) which manages execution automatically
/// {@endtemplate}
class ModelMacro extends MacroGenerator {
  const ModelMacro({super.capability = modelMacroCapability});

  static ModelMacro initialize(MacroConfig config) {
    return ModelMacro(capability: config.capability);
  }

  @override
  final String suffixName = 'Model';
  static const _stateRef = r'$';

  @override
  GeneratedType get generatedType => GeneratedType.clazz;

  @override
  MacroGlobalConfigParser? get globalConfigParser => WidgetMacroConfig.fromJson;

  WidgetMacroConfig _getConfig(MacroState state) {
    final config = state.globalConfig;
    if (config is WidgetMacroConfig) return config;

    return WidgetMacroConfig.defaultConfig;
  }

  @override
  Future<void> init(MacroState state) async {
    if (state.targetType != TargetType.clazz) {
      throw MacroException('ModelMacro can only be applied on class but applied on: ${state.targetType}');
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
    final (dartCorePrefix, flutterCorePrefix, _) = getImportPrefix(state);

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
          final res = parseEnvField(field, dartCorePrefix);
          if (res.envType != EnvType.custom) {
            throw MacroException(
              'Cannot inject environment value without BuildContext. '
              'Use Env.custom for custom model properties defined outside widgets, but received ${res.envType.name}',
            );
          }
          envFields.add(res);
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

    // Generate code
    final buff = StringBuffer();

    _generateStateClass(
      buff: buff,
      state: state,
      className: className,
      baseStateClass: '$className$suffixName',
      stateFields: stateFields,
      computedFields: computedFields,
      envFields: envFields,
      effectMethods: effectMethods,
      queryMethods: queryMethods,
      dartCorePrefix: dartCorePrefix,
      flutterCorePrefix: flutterCorePrefix,
    );

    state.reportGenerated(buff.toString(), canBeCombined: false);
  }

  void _generateStateClass({
    required StringBuffer buff,
    required MacroState state,
    required String className,
    required String baseStateClass,
    required List<StateFieldInfo> stateFields,
    required List<ComputedFieldInfo> computedFields,
    required List<EnvFieldInfo> envFields,
    required List<EffectMethodInfo> effectMethods,
    required List<QueryMethodInfo> queryMethods,
    required String dartCorePrefix,
    required String flutterCorePrefix,
  }) {
    final dcp = dartCorePrefix;
    final fcp = flutterCorePrefix;
    final config = _getConfig(state);

    final generatedStateFields = _generateStateFields(
      config.stateFieldStrategy,
      stateFields,
      computedFields,
      envFields,
      effectMethods,
      queryMethods,
      dcp,
      fcp,
    );

    final template =
        '''
/// A mixin for [$className]. Don't forget to call [initState] in the constructor.
mixin $baseStateClass {
  @${dcp}protected
  @${dcp}pragma('vm:prefer-inline')
  @${dcp}pragma('dart2js:tryInline')
  $className get $_stateRef => this as $className;

  @${dcp}protected
  ${dcp}EffectFnInfo? \$effectFnInfo;
  ${dcp}Set<void Function()> \$untrackedFns = const {};
  
$generatedStateFields

  bool \$initCalled = false; 
  
  @mustCallSuper
  void initState() {
    if (\$initCalled) return;
    \$initCalled = true;
    
    final $_stateRef = this.$_stateRef;
${_generateInitStateBody(config.stateFieldStrategy, envFields, stateFields, computedFields, effectMethods)}
  }

${_generateBaseMethods(dcp, fcp)}

  void dispose() {
${_generateDisposeBody(config.stateFieldStrategy, envFields, stateFields, computedFields, queryMethods, effectMethods)}
  }
}''';

    buff.write(template);
  }

  String _generateBaseMethods(String dcp, String fcp) {
    return '''
  void createEffect(${fcp}ValueNotifier<${dcp}Object?> notifier, void Function() fn) {
    \$effectFnInfo ??= {};
    MacroEffectUtils.createEffect(notifier, fn, \$effectFnInfo!, \$untrackedFns);
  }

  void addEffect(${fcp}ValueNotifier<${dcp}Object?> dependency, void Function() fn) {
    \$effectFnInfo ??= {};
    MacroEffectUtils.removeEffect(dependency, fn, \$effectFnInfo);
    MacroEffectUtils.createEffect(dependency, fn, \$effectFnInfo!, \$untrackedFns);
  }

  void removeEffect(${fcp}ValueNotifier<${dcp}Object?> dependency, void Function() fn) {
    MacroEffectUtils.removeEffect(dependency, fn, \$effectFnInfo);
  }
  
  void untracked(
    void Function() fn, {
    void Function()? effectFn,
    ${dcp}List<void Function()>? effectFns,
  }) async {
    if (\$untrackedFns == const <void Function()>{}) { 
      \$untrackedFns = {};
    }
    MacroEffectUtils.untracked(
      fn,
      effectFn: effectFn,
      effectFns: effectFns,
      effectFnInfo: \$effectFnInfo,
      untrackedFns: \$untrackedFns,
    );
  } 
''';
  }

  String _generateStateFields(
    StateFieldStrategy strategy,
    List<StateFieldInfo> stateFields,
    List<ComputedFieldInfo> computedFields,
    List<EnvFieldInfo> envFields,
    List<EffectMethodInfo> effectMethods,
    List<QueryMethodInfo> queryMethods,
    String dcp,
    String fcp,
  ) {
    final buff = StringBuffer();
    const dash = '--------------------';
    const envComment = '\n// $dash Environments $dash';
    const statesComment = '\n// $dash States $dash------';
    const computedComment = '\n// $dash Computed $dash----';
    const queriesComment = '\n// $dash Queries $dash';

    if (envFields.isNotEmpty) {
      buff.writeln(envComment);
    }
    for (final fieldInfo in envFields) {
      // name without env suffix
      final envName = fieldInfo.getGeneratedStateField(strategy);

      switch (fieldInfo.envType) {
        case EnvType.read:
        case EnvType.watch:
          throw MacroException('Invalid environment type: ${fieldInfo.envType.name}, must be Env.custom');
        case EnvType.custom:
          if (!fieldInfo.field.type.startsWith('ValueNotifier') && fieldInfo.customEnvDartType == null) {
            // use regular value without listening to change
            buff.writeln('late ${fieldInfo.field.getDartType(dcp)} $envName = $_stateRef.${fieldInfo.field.name};');
            continue;
          }

          // field type is value notifier or class that extended value notifier and
          // explicitly provided the inner env type
          final baseType = fieldInfo.getUnwrappedCustomEnvType(dcp);
          final fieldNameWithEnv = fieldInfo.field.name;

          // get effects that react to change from env change
          final effectEnv = effectMethods.where(
            (e) => e.isEnv && (e.depends.contains(fieldNameWithEnv) || e.depends.contains(envName)),
          );

          final (envNotifierName, onChangeFnName) = fieldInfo.envNotifierWithFnName;
          final onChangeBody = [
            if (effectEnv.isNotEmpty && effectEnv.any((e) => e.method.params.isNotEmpty))
              "final payload = {'${fieldInfo.cleanName}': $envName};",
            '$envName = $envNotifierName.value;',
            effectEnv
                .map(
                  (effect) => '$_stateRef.${effect.method.name}(${effect.method.params.isNotEmpty ? 'payload' : ''});',
                )
                .toSet()
                .join('\n'),
          ];

          buff.writeln('''
  late final ${fcp}ValueNotifier<$baseType> $envNotifierName = () {
    final notifier = $_stateRef.${fieldInfo.field.name};
    notifier.addListener($onChangeFnName);
    return notifier;
  }();
  late $baseType $envName = $envNotifierName.value;

  void $onChangeFnName() {
    ${onChangeBody.join('\n')}
  }''');
      }
    }

    if (stateFields.isNotEmpty) {
      buff.writeln(statesComment);
    }
    for (final fieldInfo in stateFields) {
      final field = fieldInfo.field;
      // {name}State
      final genName = fieldInfo.getGeneratedStateField(strategy);

      if (fieldInfo.isGetter && fieldInfo.isPrimitive) {
        final defaultValue = getDefaultValue(field);
        buff.writeln('final $genName = ${fieldInfo.notifierType(dcp)}($defaultValue);');
      } else {
        buff.writeln('late final $genName = ${fieldInfo.notifierType(dcp)}($_stateRef.${field.name});');
      }
    }

    if (computedFields.isNotEmpty) {
      buff.writeln(computedComment);
    }
    for (final fieldInfo in computedFields) {
      // {name}State
      final (genName, onChangeDependsFnName) = fieldInfo.getGeneratedStateField(strategy);
      final fieldName = fieldInfo.field.name;
      final notifierType = fieldInfo.notifierType(dcp, fcp);

      buff.writeln('''
  late final $notifierType $genName = () {
    final state = $notifierType($_stateRef.$fieldName);
${fieldInfo.depends.map((dep) => '$dep.addListener($onChangeDependsFnName);').join('\n')}
    return state;
  }();

  void $onChangeDependsFnName() {
    $genName.value = $_stateRef.$fieldName;
  }''');
    }

    if (queryMethods.isNotEmpty) {
      buff.writeln(queriesComment);
    }
    for (final queryInfo in queryMethods) {
      // {name}Query
      final (queryName, sourceNotifierName, sourceFnChangedName) = queryInfo.getGeneratedStateField(strategy);

      final methodRetType = queryInfo.method.returns.firstOrNull;
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

      buff.writeln('''
  final ${fcp}ValueNotifier<${dcp}int> $sourceNotifierName = ${fcp}ValueNotifier(0);
  late final Resource<$resourceType> $queryName = (){
    ${queryInfo.depends.map((dep) => '    $dep.addListener($sourceFnChangedName);').join('\n')}
    return Resource${isStream ? '.stream' : ''}(
      $_stateRef.${queryInfo.method.name},
      source: $sourceNotifierName,
      useRefreshing: ${queryInfo.useRefreshing ?? true},
      debounceDelay: ${queryInfo.debounceDuration ?? 'null'},
      trackPreviousState: ${queryInfo.isTracked},
    );
  }();
  void $sourceFnChangedName() {
    $sourceNotifierName.value++;
  }''');
    }

    return buff.toString();
  }

  String _generateInitStateBody(
    StateFieldStrategy strategy,
    List<EnvFieldInfo> envFields,
    List<StateFieldInfo> stateFields,
    List<ComputedFieldInfo> computedFields,
    List<EffectMethodInfo> effectMethods,
  ) {
    final buff = StringBuffer();

    // trigger late initialization
    for (final fieldInfo in envFields) {
      if (!fieldInfo.field.type.startsWith('ValueNotifier') && fieldInfo.customEnvDartType == null) {
        continue;
      }

      // name without suffix
      final name = fieldInfo.getGeneratedStateField(strategy);
      buff.writeln('$name;');
    }

    buff.writeln();
    for (final fieldInfo in stateFields) {
      if (fieldInfo.isGetter) {
        // {name}State
        final name = fieldInfo.getGeneratedStateField(strategy);
        buff.writeln('$name.value = $_stateRef.${fieldInfo.field.name};');
      }
    }

    // trigger late initialization
    buff.writeln();
    for (final fieldInfo in computedFields) {
      // {name}State
      final (genName, _) = fieldInfo.getGeneratedStateField(strategy);
      buff.writeln('$genName;');
    }

    buff.writeln();

    for (final methodInfo in effectMethods) {
      if (methodInfo.isEnv) continue;
      for (final dep in methodInfo.depends) {
        buff.writeln('createEffect($dep, $_stateRef.${methodInfo.method.name});');
      }
    }

    return buff.toString();
  }

  String _generateDisposeBody(
    StateFieldStrategy strategy,
    List<EnvFieldInfo> envFields,
    List<StateFieldInfo> stateFields,
    List<ComputedFieldInfo> computedFields,
    List<QueryMethodInfo> queryMethods,
    List<EffectMethodInfo> effectMethods,
  ) {
    final buff = StringBuffer();
    final states = <String>{
      for (final fieldInfo in stateFields) fieldInfo.getGeneratedStateField(strategy),
      for (final fieldInfo in computedFields) fieldInfo.getGeneratedStateField(strategy).$1,
      for (final fieldInfo in queryMethods) fieldInfo.getGeneratedStateField(strategy).$1,
    };

    // dispose effects
    for (final effect in effectMethods) {
      if (effect.isEnv) continue;

      final dependencies = effect.depends
          .mapNonNull((dep) => states.contains(dep) ? null : 'removeEffect($dep, $_stateRef.${effect.method.name});')
          .join('\n');

      if (dependencies.isNotEmpty) {
        buff.writeln(dependencies);
      }
    }

    // dispose query
    for (final queryInfo in queryMethods) {
      final (queryName, sourceNotifierName, sourceFnChangedName) = queryInfo.getGeneratedStateField(strategy);
      final dependencies = queryInfo.depends
          .mapNonNull((dep) => states.contains(dep) ? null : '$dep.removeListener($sourceFnChangedName);')
          .join('\n');

      if (dependencies.isNotEmpty) {
        buff.writeln(dependencies);
      }
      buff.writeln('$queryName.dispose();');
      buff.writeln('$sourceNotifierName.dispose();');
    }

    // dispose states
    for (final fieldInfo in stateFields) {
      // {name}State
      final name = fieldInfo.getGeneratedStateField(strategy);
      buff.writeln('$name.dispose();');
    }

    // dispose computed
    for (final fieldInfo in computedFields) {
      // {name}State
      final (genName, onChangeDependsFnName) = fieldInfo.getGeneratedStateField(strategy);
      final dependencies = fieldInfo.depends
          .mapNonNull((dep) => states.contains(dep) ? null : '$dep.removeListener($onChangeDependsFnName);')
          .join('\n');

      // dispose generated state and remove listener for added dependency
      if (dependencies.isNotEmpty) {
        buff.writeln(dependencies);
      }
      buff.writeln('$genName.dispose();');
    }

    // dispose environment
    for (final fieldInfo in envFields.where((e) => e.envType == EnvType.custom)) {
      if (!fieldInfo.field.type.startsWith('ValueNotifier') && fieldInfo.customEnvDartType == null) {
        continue;
      }

      final (envNotifierName, onChangeFnName) = fieldInfo.envNotifierWithFnName;
      buff.writeln('$envNotifierName.removeListener($onChangeFnName);');
    }

    return buff.toString().trimRight();
  }
}

/// {@macro model_macro}
const modelMacro = Macro(
  ModelMacro(capability: modelMacroCapability),
);

/// Base capability for [ModelMacro]
const modelMacroCapability = MacroCapability(
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
