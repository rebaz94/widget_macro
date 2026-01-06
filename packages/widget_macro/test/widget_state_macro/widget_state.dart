import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:widget_macro/widget_macro.dart';

import '../model_macro/model.dart';

part 'widget_state.g.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    super.key,
    required this.title,
  });

  final String title;

  @override
  State<MyHomePage> createState() => MyHomePageState();
}

@widgetStateMacro
class MyHomePageState extends BaseMyHomePageState {
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
  @override
  @Env.read()
  MyCounter get myCounter;

  /// Listen to dependency and update when it change
  @override
  @Env.watch()
  MyCounter get myCounter2;

  @Env.watch()
  MyCounter get myCounterCustomEnv => Provider.of(context);

  /// environment should have suffix `Env` or declare like
  @override
  @Env.read()
  MyCounter get myCounterAnotherWay;

  /// Get dependency using any dependency injection like get_it
  /// Don't access this field directly to get the value.
  /// Use [myCounter3] instead, which caches the injected value.
  /// Accessing [myCounter3Env] directly will create a new instance each time.
  @Env.custom()
  MyCounter get myCounter3Env {
    return MyCounter(title: 'Hello');
  }

  /// Get dependency using any dependency injection that
  /// wrapped in a value notifier for reactivity
  /// use [myCounter4] to get the value
  @Env.custom()
  ValueNotifier<MyCounter> get myCounter4Env {
    return ValueNotifier(MyCounter(title: 'Merhaba'));
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
  @Effect.env([#myCounter4Env])
  void myCounter4EnvChanged(Map<String, Object?> oldValues) {
    print('environment of: `myCounter4Env` changed: ${myCounter4Env.value}');
  }

  /// React to changes from any specified environment
  @Effect.env([#myCounter4Env, #myCounter2Env])
  void multipleEnvChanged() {
    print('multiple env changed');
  }

  /// React to environment change and get old value by name of environment
  @Effect.env([#myCounter2Env])
  void myCounter2EnvChanged(Map<String, Object?> oldValues) {
    print('myCounter2EnvChanged, oldValue: ${oldValues['myCounter2Env']}');
  }

  @Query.by([#counterState])
  Future<int> fetchData() async {
    await Future.delayed(const Duration(milliseconds: 50));
    return counterState.value * 10;
  }

  void _incrementCounter() async {
    counterState.value++;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: titleState.watch((_, value, _) {
          return Text(value);
        }),
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
            Text(myCounter.title),
            Text(myCounter2.title),
            Text(myCounter3.title),
            myCounter.titleState.watch((_, value, _) {
              return Text(value);
            }),
            fetchDataQuery.state(
              (value) => value.when(
                ready: (data) => Text('Fetch Data: $data'),
                error: (error, stackTrace) => Text(error.toString()),
                loading: () => Text('Loading...'),
              ),
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
