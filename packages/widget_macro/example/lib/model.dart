import 'package:widget_macro/widget_macro.dart';

part 'gen/model.g.dart';

@modelMacro
class MyCounter with MyCounterModel {
  MyCounter({
    required this.title,
  }) {
    onInitState();
  }

  @param
  final String title;

  /// Create counterState notifier
  @state
  int get counter => 0;

  /// Recompute value based on counterState
  @Computed.depends([#counterState])
  int get doubleCounter => counterState.value * 2;

  /// Get dependency using any dependency injection like get_it
  @Env.custom()
  CalculatorService get calculatorServiceEnv {
    return CalculatorService();
  }

  /// Get dependency using any dependency injection that
  /// wrapped in a value notifier for reactivity
  @Env.custom()
  ValueNotifier<CalculatorService> get calculatorService2Env {
    return ValueNotifier(CalculatorService());
  }

  /// Get dependency using custom value notifier
  @Env.customNotifier(CalculatorService)
  CustomValueNotifier get myServiceEnv {
    return CustomValueNotifier(CalculatorService());
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
  @Effect.env([#calculatorService2Env])
  void calculatorService2EnvChanged(Map<String, Object?> oldValues) {
    print('Environment of: `calculatorService2Env` changed: ${calculatorService2Env.value}');
  }

  /// React to changes from any specified environment
  @Effect.env([#calculatorService2Env, #myServiceEnv])
  void multipleEnvChanged() {
    print('Multiple env changed');
  }

  /// React to environment change and get old value by name of environment
  @Effect.env([#calculatorService2Env])
  void myCounter2EnvChanged(Map<String, Object?> oldValues) {
    print('Environment of: `calculatorService2` changed, oldValue: ${oldValues['myCounter2']}');
  }

  /// React to change from counterState
  @Query.by([#doubleCounterState], debounce: Duration(milliseconds: 300))
  Future<int> fetchData() async {
    await Future.delayed(const Duration(seconds: 1));
    return counterState.value * 100;
  }

  void incrementCounter() async {
    counterState.value++;
  }
}

class CustomValueNotifier extends ValueNotifier<CalculatorService> {
  CustomValueNotifier(super.value);
}

@modelMacro
class CalculatorService with CalculatorServiceModel {
  CalculatorService() {
    onInitState();
  }

  @state
  int get counter => 0;

  /// Recompute value based on counterState
  @Computed.depends([#counterState])
  int get doubleCounter => counterState.value * 2;
}
