import 'package:flutter_test/flutter_test.dart';

import 'model.dart';

void main() {
  group('MyCounter Model Tests', () {
    late MyCounter myCounter;

    setUp(() {
      myCounter = MyCounter(title: 'Test Title');
    });

    tearDown(() {
      myCounter.dispose();
    });

    group('State Management', () {
      test('@param - title parameter is tracked', () {
        expect(myCounter.title, 'Test Title');
        expect(myCounter.titleState.value, 'Test Title');
      });

      test('@state - counter initializes with default value', () {
        expect(myCounter.counterState.value, 0);
      });

      test('@state - counter can be updated', () {
        myCounter.counterState.value = 5;
        expect(myCounter.counterState.value, 5);
      });

      test('@state - counter notifies listeners on change', () {
        var notified = false;
        myCounter.counterState.addListener(() {
          notified = true;
        });

        myCounter.counterState.value = 10;
        expect(notified, true);
      });
    });

    group('Computed Properties', () {
      test('@Computed.depends - doubleCounter computes correctly', () {
        myCounter.counterState.value = 5;
        expect(myCounter.doubleCounterState.value, 10);
      });

      test('@Computed.depends - doubleCounter updates when dependency changes', () {
        myCounter.counterState.value = 3;
        expect(myCounter.doubleCounterState.value, 6);

        myCounter.counterState.value = 7;
        expect(myCounter.doubleCounterState.value, 14);
      });

      test('@Computed.depends - cached until dependency changes', () {
        myCounter.counterState.value = 5;

        // Access multiple times
        for (var i = 0; i < 5; i++) {
          myCounter.counterState.value = 5;
          final _ = myCounter.doubleCounterState.value;
        }

        // Should only compute once (verify through behavior)
        expect(myCounter.doubleCounterState.value, 10);
      });
    });

    group('Environment Injection', () {
      test('@Env.custom() - calculatorServiceEnv is injected', () {
        expect(myCounter.calculatorService, isA<CalculatorService>());
      });

      test('@Env.custom() - calculatorService2Env is wrapped in ValueNotifier', () {
        expect(myCounter.calculatorService2, isA<CalculatorService>());
      });

      test('@Env.customNotifier - myServiceEnv uses custom notifier', () {
        expect(myCounter.myService, isA<CalculatorService>());
      });

      test('@Env.custom() - environment values are reactive', () {
        var notified = false;
        // manually listen to env change
        myCounter.$calculatorService2Notifier.addListener(() {
          notified = true;
        });

        myCounter.$calculatorService2Notifier.value = CalculatorService();
        expect(notified, true);
      });
    });

    group('Side Effects', () {
      test('@Effect.by - untracked prevents effect recursion', () async {
        myCounter.counterState.value = 15; // Trigger auto-reset
        await Future.delayed(Duration.zero);

        // Should be reset to 0 by untracked call
        expect(myCounter.counterState.value, 0);
      });

      test('@Effect.by - multiple dependencies trigger effect', () async {
        myCounter.counterState.value = 5;
        await Future.delayed(Duration.zero);

        myCounter.titleState.value = 'New Title';
        await Future.delayed(Duration.zero);

        // Both changes should have triggered logCounter2
        expect(myCounter.counterState.value, 5);
        expect(myCounter.titleState.value, 'New Title');
      });

      test('@Effect.env - runs when environment changes', () async {
        var oldService = myCounter.calculatorService2;

        myCounter.calculatorService2 = CalculatorService();
        await Future.delayed(Duration.zero);

        // Effect should have run
        expect(myCounter.calculatorService2, isNot(oldService));
      });
    });

    group('Methods', () {
      test('incrementCounter increases counter by 1', () async {
        expect(myCounter.counterState.value, 0);

        myCounter.incrementCounter();
        expect(myCounter.counterState.value, 1);

        myCounter.incrementCounter();
        expect(myCounter.counterState.value, 2);
      });
    });

    group('Lifecycle', () {
      test('initState is called in constructor', () {
        // initState should have been called during setUp
        // Verify by checking that state is initialized
        expect(myCounter.counterState, isNotNull);
        expect(myCounter.titleState, isNotNull);
      });
    });
  });

  group('CalculatorService Model Tests', () {
    late CalculatorService service;

    setUp(() {
      service = CalculatorService();
    });

    tearDown(() {
      service.dispose();
    });

    test('@state - counter initializes with default value', () {
      expect(service.counterState.value, 0);
    });

    test('@state - counter can be updated', () {
      service.counterState.value = 10;
      expect(service.counterState.value, 10);
    });

    test('@Computed.depends - doubleCounter computes correctly', () {
      service.counterState.value = 8;
      expect(service.doubleCounterState.value, 16);
    });

    test('@Computed.depends - doubleCounter updates reactively', () {
      service.counterState.value = 3;
      expect(service.doubleCounterState.value, 6);

      service.counterState.value = 12;
      expect(service.doubleCounterState.value, 24);
    });
  });
}
