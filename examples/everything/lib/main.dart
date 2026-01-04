import 'dart:async';

import 'package:flutter/material.dart';
import 'package:widget_macro/widget_macro.dart';

import 'macro_context.dart' as macro;
import 'model.dart';

part 'gen/main.g.dart';

void main() async {
  await macro.setupMacro();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return Provider(
      create: (context) => MyCounter(title: 'Demo'),
      child: MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          colorScheme: .fromSeed(seedColor: Colors.deepPurple),
        ),
        home: const MyHomePage(title: 'Flutter Demo Home Page'),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    super.key,
    required this.title,
  });

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

@widgetStateMacro
class _MyHomePageState extends _BaseMyHomePageState {
  /// Observe title parameter
  @param
  String get title => widget.title;

  /// Create counterState notifier
  @state
  int get counter => 0;

  /// Recompute value based on counterState
  @Computed.depends([#counterState])
  int get doubleCounter => counterState.value * 2;

  /// Read MyCounter using Provider
  @Env.read()
  MyCounter get myCounterEnv => myCounter;

  /// environment should have suffix `Env` or declare like
  @override
  @Env.read()
  MyCounter get myCounterAnotherWay;

  /// Listen to dependency and update when it change
  @Env.watch()
  MyCounter get myCounterWatchedEnv => myCounterWatched;

  /// Get dependency using any dependency injection like get_it
  /// Don't access this field directly to get the value.
  /// Use [myCounterCustom] instead, which caches the injected value.
  /// Accessing [myCounterCustomEnv] directly will create a new instance each time.
  @Env.custom()
  MyCounter get myCounterCustomEnv {
    return MyCounter(title: 'Hello');
  }

  /// Get dependency using any dependency injection that
  /// wrapped in a value notifier for reactivity
  /// use [myCounterCustomWatched] to get the value
  @Env.custom()
  ValueNotifier<MyCounter> get myCounterCustomWatchedEnv {
    return ValueNotifier(MyCounter(title: 'Merhaba'));
  }

  /// Get dependency using custom value notifier
  /// use [myCounterCustomNotifierWatched] to get the value
  @Env.customNotifier(MyCounter)
  MyValueNotifier get myCounterCustomNotifierWatchedEnv {
    return MyValueNotifier(MyCounter(title: 'Bonjour'));
  }

  /// React to change from counterState
  @Effect.by([#counterState])
  void logCounter() {
    print('Counter: ${counterState.value}');
    if (counterState.value > 10) {
      /// use untracked to change counterState without triggering
      /// a dispatch to logCounter and logCounter2
      untracked(
        () => counterState.value = 0,
        effectFns: [logCounter, logCounter2],
      );
    }
  }

  /// React to multiple state change
  @Effect.by([#counterState, #titleState])
  void logCounter2() {
    print('Current + State: ${counterState.value} - ${titleState.value}');
  }

  /// React to environment change
  @Effect.env([#myCounterCustomWatchedEnv])
  void myCounter4EnvChanged(Map<String, Object?> oldValues) {
    print('environment of: `myCounterCustomWatchedEnv` changed: ${myCounterCustomWatchedEnv.value}');
  }

  /// React to changes from any specified environment
  @Effect.env([#myCounterCustomWatchedEnv, #myCounterWatched])
  void multipleEnvChanged() {
    print('multiple env changed');
  }

  /// React to environment change and get old value by name of environment
  @Effect.env([#myCounterWatched])
  void myCounterWatchedChanged(Map<String, Object?> oldValues) {
    print('myCounter2EnvChanged, oldValue: ${oldValues['myCounter2Env']}');
  }

  /// React to change from counterState
  @Query.by([#doubleCounterState], debounce: Duration(milliseconds: 300))
  Future<int> fetchData() async {
    await Future.delayed(const Duration(seconds: 1));
    return counterState.value * 100;
  }

  void _incrementCounter() async {
    counterState.value++;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: titleState.watch((_, value, _) => Text(value)),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            counterState.watch(
              (_, counter, _) => Text('$counter', style: Theme.of(context).textTheme.headlineMedium),
            ),
            doubleCounterState.watch(
              (_, counter, _) => Text('$counter', style: Theme.of(context).textTheme.headlineMedium),
            ),
            Text('MyCounter:Title: ${myCounter.title}'),
            Text('MyCounterWatched:Title: ${myCounterWatchedEnv.title}'),
            Text('MyCounterCustomWatched:Title: ${myCounterCustomEnv.title}'),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('FetchData: '),
                fetchDataQuery.state(
                  (value) => value.when(
                    ready: (data) => Text('Data: $data'),
                    error: (error, stackTrace) => Text('Error: $error'),
                    loading: () => Text('Loading...'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class MyValueNotifier extends ValueNotifier<MyCounter> {
  MyValueNotifier(super.value);
}
