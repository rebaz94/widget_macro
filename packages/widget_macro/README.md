# WidgetMacro

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A macro-powered state management solution for Flutter that eliminates boilerplate code.

## Prerequisites

This package uses **macro_kit** which require setup before use. Follow the setup instructions
at [macro_kit](https://pub.dev/packages/macro_kit).

## ✨ Features

- 🎯 **Reactive State Management** - Automatic UI updates with ValueNotifier
- 🧮 **Computed Properties** - Derived values that auto-recompute when dependencies change
- 💉 **Dependency Injection** - Read, watch, or inject from Provider/InheritedWidget or custom
  sources
- ⚡ **Side Effects** - Functions that automatically track and react to state changes
- 🔄 **Async Queries** - Managed asynchronous operations with loading/error states
- 📦 **Zero Boilerplate** - Write StatelessWidget-style code, get StatefulWidget functionality
- 🚀 **Compile-time Safety** - Macros generate code at compile time with full type safety

## 📦 Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  widget_macro: ^latest_version
```

in your `macro_context.dart` add required macros:

```dart
import 'dart:async';
import 'package:macro_kit/macro_kit.dart';
import 'package:widget_macro/widget_macro.dart';

bool get autoRunMacro => true;

List<String> get autoRunMacroCommand => macroFlutterRunnerCommand;

void main() async {
  await setupMacro();
  await keepMacroRunner();
}

Future<void> setupMacro() async {
  await runMacro(
    // TODO: Replace with your package name
    package: PackageInfo('your_package_name'),
    autoRunMacro: autoRunMacro,
    enabled: true,
    macros: {
      'WidgetStateMacro': WidgetStateMacro.initialize,
      'ModelMacro': ModelMacro.initialize,
    },
  );
}
```

## 🚀 Quick Start

### WidgetStateMacro - For Widgets

```dart
import 'package:flutter/material.dart';
import 'package:widget_macro/widget_macro.dart';

part 'my_page.g.dart';

class MyPage extends StatefulWidget {
  const MyPage({super.key});

  @override
  State<MyPage> createState() => _MyPageState();
}

@widgetStateMacro
class _MyPageState extends _BaseMyPageState {
  // use the generated class
  @state
  int get counter => 0;

  void increment() {
    counterState.value++;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: counterState.state((count) => Text('Count: $count')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: increment,
        child: Icon(Icons.add),
      ),
    );
  }
}
```

### ModelMacro - For Shared State

```dart
import 'package:widget_macro/widget_macro.dart';

part 'counter_model.g.dart';

@modelMacro
class Counter with CounterModel {
  Counter() {
    onInitState();
  }

  @state
  int get counter => 0;

  void increment() {
    counterState.value++;
  }
}
```

## 📚 Complete Feature Guide

### 🎯 State Management

#### Basic State

```dart
@state
int get counter => 0;

// Generated: ValueNotifier<int> counterState
// Usage: counterState.value++
```

#### Tracked State (with previous value)

```dart
@tracked
int get history => 0;

// Generated: TrackedValueNotifier<int> historyState
// Access: historyState.value and historyState.previous
```

#### Widget Parameters (WidgetStateMacro only)

```dart
@param
String get title => widget.title;

// Generated: ValueNotifier<String> titleState
// Auto-updates when widget.title changes
```

### 🧮 Computed Properties

Derived values that automatically recompute when dependencies change:

```dart
@state
int get counter => 0;

@Computed.depends([#counterState])
int get doubleCounter => counterState.value * 2;

@Computed.depends([#counterState], tracked: true)
String get counterText => 'Count: ${counterState.value}';
```

**Important:** Dependencies must use exact symbol names with `State` suffix.

### 💉 Dependency Injection

#### From Provider/InheritedWidget (WidgetStateMacro only)

```dart
// Read once (no rebuilds)
@override
@Env.read()
UserService get userService;

@override
@Env.read()
ShopService get shopService;

// Watch and rebuild on changes, use the generated theme(without env suffix)
@Env.watch()
ThemeData get themeEnv => Theme.of(context);
```

#### Custom Injection (Both macros)

```dart
// Static injection
@Env.custom()
ApiService get apiServiceEnv {
  return getIt<ApiService>();
}

// Reactive injection
@Env.custom()
ValueNotifier<ApiService> get apiService2Env {
  return getIt<ApiService>();
}

// Custom notifier type
@Env.customNotifier(ApiService)
MyValueNotifier get apiService3Env {
  return getIt<ApiService>();
}

// Access: apiService, apiService2, apiService3
```

### ⚡ Side Effects

Functions that run when dependencies change:

#### React to State Changes

```dart
@Effect.by([#counterState])
void logCounter() {
  print('Counter: ${counterState.value}');
}

// Multiple dependencies
@Effect.by([#counterState, #nameState])
void logBoth() {
  print('Counter: ${counterState.value}, Name: ${nameState.value}');
}
```

#### React to Environment Changes

```dart
@Effect.env([#userServiceEnv])
void onUserServiceChanged(Map<String, Object?> oldValues) {
  print('Service changed from ${oldValues['userService']}');
}

// Without old values
@Effect.env([#userServiceEnv])
void onUserServiceChanged() {
  print('Service changed');
}
```

#### Prevent Effect Recursion

```dart
@Effect.by([#counterState])
void autoReset() {
  if (counterState.value > 10) {
    untracked(
          () => counterState.value = 0,
      effectFns: [autoReset],
    );
  }
}
```

### 🔄 Async Queries

Managed asynchronous operations with automatic state tracking:

#### Basic Query

```dart
@state
int get userId => 1;

@Query.by([#userIdState])
Future<User> fetchUser() async {
  final response = await api.getUser(userIdState.value);
  return User.fromJson(response);
}

// Generated: Resource<User> fetchUserQuery

// Usage in build:
Widget build(BuildContext context) {
  return fetchUserQuery.state((user) =>
      user.when(
        ready: (user) => Text('User: ${user.name}'),
        error: (error, _) => Text('Error: $error'),
        loading: () => CircularProgressIndicator(),
      ),
  );
}
```

#### Debounced Query

```dart
@state
String get searchTerm => '';

@Query.by([#searchTermState], debounce: Duration(milliseconds: 300))
Future<List<Result>> searchResults() async {
  if (searchTermState.value.isEmpty) return [];
  return await api.search(searchTermState.value);
}

// Waits 300ms after searchTerm stops changing
```

#### Query with Previous Results

```dart
@Query.by([#pageState], tracked: true)
Future<PageData> fetchPage() async {
  return await api.getPage(pageState.value);
}

// Access: fetchPageQuery.data and fetchPageQuery.previous
```

#### Control Refresh Behavior

```dart
// Keep showing old data while refreshing (default)
@Query.by([#pageState], useRefreshing: true)
Future<Data> fetch1() async {
  //...
}

// Show loading state when refreshing
@Query.by([#pageState], useRefreshing: false)
Future<Data> fetch2() async {
  ///...
}
```

Check [here](https://github.com/rebaz94/widget_macro/tree/main/examples) for more examples.

## 🎯 Best Practices

### ✅ Do's

- Always use generated property names without suffixes for access
- Use `@tracked` when you need previous values
- Use `debounce` for expensive queries (search, API calls)
- Call `onInitState()` in ModelMacro constructors
- Use `untracked()` to prevent effect recursion
- Use exact symbol names with `State` suffix for dependencies

### ❌ Don'ts

- ❌ Don't access environment fields directly (use generated properties)
- ❌ Don't invoke query methods directly (use generated query notifiers)
- ❌ Don't use incorrect symbol names in dependencies (causes compile errors)
- ❌ Don't use `@Env.read()` or `@Env.watch()` in ModelMacro (no BuildContext)
- ❌ Don't forget to extend/mixin generated base classes

## 🔍 Naming Conventions

| Annotation  | Property Name | Generated Name     | Access As                                     |
|-------------|---------------|--------------------|-----------------------------------------------|
| `@state`    | `counter`     | `counterState`     | `counterState.value`                          |
| `@tracked`  | `history`     | `historyState`     | `historyState.value`, `historyState.previous` |
| `@param`    | `title`       | `titleState`       | `titleState.value`                            |
| `@Computed` | `doubleCount` | `doubleCountState` | `doubleCount`                                 |
| `@Env.*`    | `serviceEnv`  | `serviceEnvState`  | `service` (without Env)                       |
| `@Query.by` | `fetchUser()` | `fetchUserQuery`   | `fetchUserQuery.value`                        |

## 🤝 Contributing

Contributions are welcome! Feel free to:

- 🐛 Report bugs and issues
- 💡 Suggest new features
- 🔧 Submit pull requests

## 📄 License

MIT License - see [LICENSE](LICENSE) for details