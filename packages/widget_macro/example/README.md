# widget_macro Examples

This folder contains practical examples demonstrating all features of the widget_macro package.

## 📚 Full Examples

For comprehensive examples and additional use cases, visit
the [GitHub repository](https://github.com/rebaz64/widget_macro/tree/main/examples).

## ✨ Features Demonstrated

This example showcases all major features of widget_macro:

### 🎯 State Management

- **`@state`** - Reactive counter state with automatic UI updates
- **`@param`** - Widget parameter tracking (title parameter)
- **`@tracked`** - State with previous value tracking

### 🧮 Computed Properties

- **`@Computed.depends`** - Derived values that auto-recompute (doubleCounter)

### 💉 Dependency Injection

- **`@Env.read()`** - One-time dependency access from Provider
- **`@Env.watch()`** - Reactive dependency with automatic rebuilds
- **`@Env.custom()`** - Custom injection (e.g., get_it, service locator)
- **`@Env.customNotifier()`** - Custom notifier types with explicit value types

### ⚡ Side Effects

- **`@Effect.by`** - React to state changes (single and multiple dependencies)
- **`@Effect.env`** - React to environment changes with old values tracking
- **`untracked()`** - Update state without triggering effects

### 🔄 Async Queries

- **`@Query.by`** - Automatic async operation management with:
    - Dependency tracking (runs when dependencies change)
    - Debouncing (300ms delay in example)
    - Loading/error/success states
    - Manual refresh capability

## 📁 Key Files

- **`main.dart`** - Complete widget example with all features
- **`model.dart`** - Model macro example for shared state
- **`macro_context.dart`** - Macro configuration setup

## 🚀 Running the Example

```bash
# Navigate to the example directory
cd example

# Get dependencies
flutter pub get

# Run the app
flutter run
```

## 💡 Key Patterns Demonstrated

### Using State

```dart
@state
int get counter => 0;

// In build method
counterState.watch
(
(_, counter, _) => Text('$
counter
'
)
)
```

### Using Computed Properties

```dart
@Computed.depends([#counterState])
int get doubleCounter => counterState.value * 2;
```

### Using Environment Dependencies

```dart
@Env.read()
MyCounter get myCounterEnv => myCounter;

// Access the cached value
Text
('Title: 
${myCounter.
title
}
'
)
```

### Using Queries

```dart
@Query.by([#userIdState], debounce: Duration(milliseconds: 300))
Future<UserProfile> fetchData() async {
  return await api.getProfile(userIdState.value);
}

// In build method
fetchDataQuery.state
(
(value) => value.when(
ready: (data) => Text('Data: $data'),
error: (error, _) => Text('Error: $error'),
loading: () => CircularProgressIndicator(),
),
)
```

### Using Effects

```dart
@Effect.by([#counterState])
void logCounter() {
  print('Counter: ${counterState.value}');
}
```

## 📖 Documentation

For detailed documentation on each feature, see the
main [package documentation](https://pub.dev/packages/widget_macro).

## 🤝 Contributing

Found an issue or want to add more examples? Contributions are welcome! Please visit
the [GitHub repository](https://github.com/rebaz94/widget_macro).