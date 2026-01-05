import 'package:flutter/foundation.dart';
import 'package:widget_macro/src/core/model_macro.dart';
import 'package:widget_macro/src/core/widget_state_macro.dart';

@internal
class StateFlags {
  StateFlags._();

  static const int tracked = 1 << 0; // 1
  static const int param = 1 << 1; // 2
  static const int public = 1 << 2; // 4
  static const int private = 1 << 3; // 8
}

/// {@template state_annotation}
/// **State annotations** mark getters as reactive properties.
///
/// Annotated getters are wrapped in ValueNotifier, making them reactive.
/// The generated notifier is named with a `State` suffix (e.g., `counter` → `counterState`).
///
/// ## Visibility Control
///
/// By default, generated fields follow the source property's visibility:
/// - Private property (`_counter`) → Private generated field (`_counterState`)
/// - Public property (`counter`) → Public generated field (`counterState`)
///
/// You can override visibility using the `public` parameter:
/// - `public: true` - Force public generation (strips underscore)
/// - `public: false` - Force private generation (adds underscore)
/// - `public: null` (default) - Follow global configuration
///
/// ## Available Annotations
///
/// ### Basic State
/// - `@state` - Creates a standard reactive state property (follows source visibility)
/// - `@statePublic` - Creates a public reactive state property (forces public)
/// - `@statePrivate` - Creates a private reactive state property (forces private)
///
/// ### Tracked State (with previous value)
/// - `@tracked` - Creates tracked state (follows source visibility)
/// - `@trackedPublic` - Creates public tracked state (forces public)
/// - `@trackedPrivate` - Creates private tracked state (forces private)
///
/// ### Widget Parameters (WidgetStateMacro only)
/// - `@param` - Marks a widget parameter (follows source visibility)
/// - `@paramPublic` - Marks a public widget parameter (forces public)
/// - `@paramPrivate` - Marks a private widget parameter (forces private)
/// - `@paramTracked` - Marks a tracked widget parameter (follows source visibility)
/// - `@paramTrackedPublic` - Marks a public tracked widget parameter (forces public)
/// - `@paramTrackedPrivate` - Marks a private tracked widget parameter (forces private)
///
/// ## Examples
///
/// ### Default Behavior (Follow Source)
/// ```dart
/// // Private source → Private generated
/// @state
/// int get _counter => 0;
/// // Generates: ValueNotifier<int> _counterState
///
/// // Public source → Public generated
/// @state
/// int get counter => 0;
/// // Generates: ValueNotifier<int> counterState
/// ```
///
/// ### Force Public Generation
/// ```dart
/// // Private source → Force public generated
/// @statePublic
/// int get _counter => 0;
/// // Generates: ValueNotifier<int> counterState
///
/// // Explicit parameter
/// @Prop(public: true)
/// String get _apiKey => '';
/// // Generates: ValueNotifier<String> apiKeyState
/// ```
///
/// ### Force Private Generation
/// ```dart
/// // Public source → Force private generated
/// @statePrivate
/// int get counter => 0;
/// // Generates: ValueNotifier<int> _counterState
///
/// // Explicit parameter
/// @Prop(public: false)
/// String get apiKey => '';
/// // Generates: ValueNotifier<String> _apiKeyState
/// ```
/// ## Important Notes
/// - Use visibility overrides (`public: true/false`) only when you need different visibility than the source
/// - Most cases should use default behavior (no `public` parameter)
/// - Forcing public is useful for exposing private implementation details
/// - Forcing private is useful for hiding public properties in generated code
/// {@endtemplate}
class Prop {
  /// {@macro state_annotation}
  const Prop({
    bool tracked = false,
    bool? public,
  }) : val =
           (tracked ? StateFlags.tracked : 0) |
           (public == true ? StateFlags.public : 0) | //
           (public == false ? StateFlags.private : 0);

  /// {@macro state_annotation}
  const Prop.param({
    bool tracked = false,
    bool? public,
  }) : val =
           (tracked ? StateFlags.tracked : 0) |
           (public == true ? StateFlags.public : 0) |
           (public == false ? StateFlags.private : 0) |
           StateFlags.param;

  final int val;
}

/// {@template computed_annotation}
/// **Computed** marks a getter as a computed property that automatically recomputes when dependencies change.
///
/// Computed properties are cached and only recalculate when their declared dependencies update.
///
/// ## Parameters
/// - `depends` - List of symbols representing state dependencies (e.g., `[#counterState]`)
///   - Symbols must exactly match valid state field names, otherwise a compile error will occur
///   - Must reference properties marked with `@state`, `@tracked`, `@param`, or `@paramTracked`
///   - Use the generated state field name with `State` suffix (e.g., `counter` → `#counterState`)
/// - `tracked` - Optional. If `true`, tracks previous computed values
///
/// ## Examples
/// ```dart
/// @state
/// int get counter => 0;
///
/// @Computed.depends([#counterState])
/// int get doubleCounter => counterState.value * 2;
///
/// @Computed.depends([#counterState, #multiplierState], tracked: true)
/// int get result => counterState.value * multiplierState.value;
/// // Tracks previous computed value
/// ```
///
/// ## Important Notes
/// - Dependencies must be valid state fields with exact symbol names
/// - Typos or invalid symbols will cause compile-time errors
/// - Symbol names must match the generated state field name (with `State` suffix)
/// {@endtemplate}
class Computed {
  /// {@macro computed_annotation}
  const Computed.depends(
    List<Symbol> depends, {
    bool tracked = false,
    bool? public,
  }) : deps = depends,
       val =
           (tracked == true ? StateFlags.tracked : 0) |
           (public == true ? StateFlags.public : 0) |
           (public == false ? StateFlags.private : 0);

  /// The list of dependency name
  final List<Symbol> deps;

  final int val;
}

/// {@template env_annotation}
/// **Env** marks a getter as a dependency injection point for external values.
///
/// Different constructors provide different injection behaviors:
///
/// ## Constructors
/// - `Env.read()` - One-time access from Provider/InheritedWidget (no rebuilds)
/// - `Env.watch()` - Reactive access from Provider/InheritedWidget (rebuilds on change)
/// - `Env.custom()` - Custom injection source (e.g., get_it, service locator)
/// - `Env.customNotifier(Type)` - Custom notifier with explicit value type
///
/// ## Examples
/// ```dart
/// // WidgetStateMacro - read from context once
/// @Env.read()
/// MyService get myServiceEnv => myService;
///
/// // WidgetStateMacro - watch and rebuild on changes
/// @Env.watch()
/// MyService get myService2Env => myService2;
///
/// // Custom injection without reactivity
/// @Env.custom()
/// MyService get myService3Env {
///   return getIt<MyService>();
/// }
///
/// Custom injection with reactivity
/// @Env.custom()
/// ValueNotifier<MyService> get myService4Env {
///   return getIt();
/// }
///
/// Custom notifier type (explicit value type)
/// @Env.customNotifier(MyService)
/// CustomValueNotifier get myService5Env {
///   return getIt();
/// }
/// ```
///
/// ## Notes
/// - Environment properties should end with `Env` suffix
/// - `@Env.read()` and `@Env.watch()` only work in [WidgetStateMacro] (require BuildContext)
/// - `@Env.custom()` works in both [WidgetStateMacro] and [ModelMacro]
/// - ModelMacro only supports `@Env.custom()` variants (no BuildContext available)
/// {@endtemplate}
class Env {
  /// Reads a dependency once from Provider/InheritedWidget (no rebuilds).
  /// Only available in WidgetStateMacro.
  ///
  /// {@macro env_annotation}
  const Env.read({this.public}) : val = 0, type = null;

  /// Watches a dependency from Provider/InheritedWidget and rebuilds on changes.
  /// Only available in WidgetStateMacro.
  ///
  /// {@macro env_annotation}
  const Env.watch({this.public}) : val = 1, type = null;

  /// Injects a dependency from a custom source (e.g., get_it, service locator).
  /// Available in both WidgetStateMacro and ModelMacro.
  ///
  /// {@macro env_annotation}
  const Env.custom({this.public}) : val = 2, type = null;

  /// Injects a custom notifier with an explicit value type.
  /// Available in both WidgetStateMacro and ModelMacro.
  ///
  /// {@macro env_annotation}
  const Env.customNotifier(this.type, {this.public}) : val = 2;

  /// The environment type
  final int val;

  /// The environment value type.
  ///
  /// Used to explicitly specify the type of wrapped value in custom notifiers.
  /// Required when extending ValueNotifier with a specific type.
  ///
  /// Example:
  /// ```dart
  /// class MyValueNotifier extends ValueNotifier<String> {}
  ///
  /// @Env.customNotifier(String)
  /// MyValueNotifier get myEnv => MyValueNotifier('value');
  /// ```
  final Type? type;

  /// Whether to make generated state public or not.
  ///
  /// default is null, based on global configuration which is public by default
  final bool? public;
}

/// {@template effect_annotation}
/// **Effect** marks a method as a side effect that runs when dependencies change.
///
/// Effects automatically track their dependencies and re-execute when those dependencies update.
///
/// ## Constructors
/// - `Effect.by(List<Symbol>)` - Runs when specified state dependencies change
/// - `Effect.env(List<Symbol>)` - Runs when specified environment dependencies change
///
/// ## Parameters
/// - `depends` - List of symbols representing dependencies
///   - Symbols must exactly match valid field names, otherwise a compile error will occur
///   - For `Effect.by`: Must reference state fields (e.g., `#counterState`)
///   - For `Effect.env`: Can reference either the property declaration with `Env` suffix (e.g., `#myServiceEnv`) OR the generated property name
///   - **Recommended:** Use the `Env` suffix version for environment dependencies (e.g., `#myServiceEnv`)
/// - For `Effect.env`, the method can optionally accept `Map<String, Object?> oldValues` parameter
///
/// ## Examples
/// ```dart
/// // React to state changes
/// @Effect.by([#counterState])
/// void logCounter() {
///   print('Counter: ${counterState.value}');
/// }
///
/// // React to multiple dependencies
/// @Effect.by([#counterState, #nameState])
/// void logChanges() {
///   print('Counter: ${counterState.value}, Name: ${nameState.value}');
/// }
///
/// // React to environment changes - recommended approach
/// @Env.custom()
/// MyService get myServiceEnv => getIt<MyService>();
///
/// @Effect.env([#myServiceEnv])  // ✓ Recommended: use Env suffix
/// void onServiceChanged(Map<String, Object?> oldValues) {
///   print('Service changed from ${oldValues['myServiceEnv']} to ${myServiceEnv.value}');
/// }
///
/// // React to environment changes without old values
/// @Effect.env([#myServiceEnv])
/// void onServiceChanged() {
///   print('Service changed: ${myServiceEnv.value}');
/// }
///
/// // Prevent effect recursion with untracked()
/// @Effect.by([#counterState])
/// void autoReset() {
///   if (counterState.value > 10) {
///     untracked(
///       () => counterState.value = 0,
///       effectFns: [autoReset],
///       dependency: counterState,
///     );
///   }
/// }
/// ```
///
/// ## Important Notes
/// - Dependencies must be valid field names with exact symbol matches
/// - Typos or invalid symbols will cause compile-time errors
/// - For `Effect.env`, both declaration name (with `Env` suffix) and generated name work, but using `Env` suffix is recommended
/// - For `Effect.by`, use the generated state field name (with `State` suffix)
/// {@endtemplate}
class Effect {
  /// {@macro effect_annotation}
  const Effect.by(List<Symbol> depends) : env = false, deps = depends;

  /// {@macro effect_annotation}
  const Effect.env(List<Symbol> depends) : env = true, deps = depends;

  /// The list of dependency name
  final List<Symbol> deps;

  /// Whether to used for environment or not
  final bool? env;
}

/// {@template query_annotation}
/// **Query** marks an async method as a reactive query that automatically runs when dependencies change.
///
/// Queries are useful for managing asynchronous operations like API calls, database queries,
/// or any async computation that depends on reactive state. The query result is wrapped in
/// a notifier that tracks loading, success, error, and refreshing states.
///
/// ## Parameters
/// - `depends` - List of symbols representing dependencies (e.g., `[#counterState]`)
///   - Symbols must exactly match valid state field names, otherwise a compile error will occur
///   - Query automatically re-runs when any dependency changes
/// - `debounce` - Optional duration to debounce query execution when dependencies change rapidly
/// - `useRefreshing` - Whether to use refreshing state (default: `true`)
///   - `true`: Stays in current state while refreshing (keeps showing previous data)
///   - `false`: Enters loading state when refreshed (shows loading indicator)
///
/// ## Examples
/// ```dart
/// @state
/// int get userId => 1;
///
/// // Basic query that runs when userId changes
/// @Query.by([#userIdState])
/// Future<User> fetchUser() async {
///   final response = await api.getUser(userIdState.value);
///   return User.fromJson(response);
/// }
/// // Generates: Resource<User> fetchUserQuery
///
/// // Query with debouncing for search
/// @state
/// String get searchTerm => '';
///
/// @Query.by([#searchTermState], debounce: Duration(milliseconds: 300))
/// Future<List<Result>> searchResults() async {
///   if (searchTermState.value.isEmpty) return [];
///   return await api.search(searchTermState.value);
/// }
/// // Waits 300ms after searchTerm stops changing before running
///
/// // Query that shows loading state on refresh
/// @Query.by([#userIdState], useRefreshing: false)
/// Future<UserProfile> fetchProfile() async {
///   return await api.getUserProfile(userIdState.value);
/// }
/// // Shows loading indicator when refreshed
///
/// // Query with multiple dependencies
/// @state
/// int get page => 1;
///
/// @state
/// String get filter => 'all';
///
/// @Query.by([#pageState, #filterState])
/// Future<List<Item>> fetchItems() async {
///   return await api.getItems(
///     page: pageState.value,
///     filter: filterState.value,
///   );
/// }
///
/// // Using the generated query notifier
/// void example() {
///   // Access query state
///   if (fetchUserQuery.isLoading) {
///     // Show loading
///   } else if (fetchUserQuery.hasError) {
///     // Show error: fetchUserQuery.error
///   } else if (fetchUserQuery.hasData) {
///     // Show data: fetchUserQuery.data
///   }
///
///   // Manually refresh
///   fetchUserQuery.refresh();
///
///   // Check if refreshing
///   if (fetchUserQuery.isRefreshing) {
///     // Show refresh indicator
///   }
/// }
/// ```
///
/// ## Query States
/// The generated query notifier provides:
/// - `isLoading` - Initial load in progress
/// - `isRefreshing` - Refresh in progress (if `useRefreshing: true`)
/// - `hasData` - Query completed successfully
/// - `hasError` - Query failed
/// - `data` - The query result (if successful)
/// - `error` - The error (if failed)
/// - `refresh()` - Manually trigger a refresh
///
/// ## Important Notes
/// - Dependencies must be valid state fields with exact symbol names
/// - Queries automatically run on initialization and when dependencies change
/// - Use `debounce` for queries that shouldn't run too frequently (e.g., search)
/// - Set `useRefreshing: false` to show loading state on refresh instead of keeping previous data
/// - The query method must return a `Future<T>` where `T` is the data type
/// - Generated notifier is named `{methodName}Query`
/// - Never invoke the query method directly; always use the generated query notifier that manages execution automatically
/// {@endtemplate}
class Query {
  /// {@macro query_annotation}
  const Query.by(
    List<Symbol> depends, {
    this.debounce,
    this.useRefreshing,
    bool tracked = false,
    bool? public,
  }) : deps = depends,
       val =
           (tracked == true ? StateFlags.tracked : 0) |
           (public == true ? StateFlags.public : 0) |
           (public == false ? StateFlags.private : 0);

  /// The list of dependency names that trigger the query to re-run.
  ///
  /// Must reference valid state fields. Query automatically executes
  /// when any of these dependencies change.
  final List<Symbol> deps;

  /// Optional debounce duration for the query.
  ///
  /// When set, the query will only run after dependencies have stopped
  /// changing for this duration. Useful for expensive operations like
  /// search queries or API calls that shouldn't run on every keystroke.
  ///
  /// Example:
  /// ```dart
  /// @Query.by([#searchTermState], debounce: Duration(milliseconds: 300))
  /// ```
  final Duration? debounce;

  /// Controls whether to use refreshing state instead of loading state.
  ///
  /// - `true` (default): Query stays in current state while refreshing,
  ///   allowing you to show previous data with a refresh indicator
  /// - `false`: Query enters loading state when refreshed, hiding previous data
  ///
  /// Example:
  /// ```dart
  /// // Keep showing old data while fetching new data
  /// @Query.by([#pageState], useRefreshing: true)
  ///
  /// // Show loading spinner when fetching new data
  /// @Query.by([#pageState], useRefreshing: false)
  /// ```
  final bool? useRefreshing;

  final int val;
}

/// {@macro state_annotation}
const state = Prop();

/// {@macro state_annotation}
const statePublic = Prop(public: true);

/// {@macro state_annotation}
const statePrivate = Prop(public: false);

/// {@macro state_annotation}
const tracked = Prop(tracked: true);

/// {@macro state_annotation}
const trackedPublic = Prop(tracked: true, public: true);

/// {@macro state_annotation}
const param = Prop.param();

/// {@macro state_annotation}
const paramPublic = Prop.param(public: true);

/// {@macro state_annotation}
const paramPrivate = Prop.param(public: false);

/// {@macro state_annotation}
const paramTracked = Prop.param(tracked: true);

/// {@macro state_annotation}
const paramTrackedPublic = Prop.param(tracked: true, public: true);

/// {@macro state_annotation}
const paramTrackedPrivate = Prop.param(tracked: true, public: false);

/// {@macro query_annotation}
const query = Query.by([]);

/// {@macro query_annotation}
const queryPublic = Query.by([], public: true);

/// {@macro query_annotation}
const queryPrivate = Query.by([], public: false);

/// Reads a dependency once from Provider/InheritedWidget (no rebuilds).
/// Only available in WidgetStateMacro.
///
/// {@macro env_annotation}
const envRead = Env.read();

/// Watches a dependency from Provider/InheritedWidget and rebuilds on changes.
/// Only available in WidgetStateMacro.
///
/// {@macro env_annotation}
const envWatch = Env.watch();

/// Injects a dependency from a custom source (e.g., get_it, service locator).
/// Available in both WidgetStateMacro and ModelMacro.
///
/// {@macro env_annotation}
const envCustom = Env.custom();
