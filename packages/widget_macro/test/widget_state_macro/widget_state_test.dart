import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widget_macro/widget_macro.dart';

import '../model_macro/model.dart';
import 'widget_state.dart';

void main() {
  group('MyHomePage Widget Tests', () {
    late MyCounter testCounter;

    setUp(() {
      testCounter = MyCounter(title: 'Test Counter 1');
    });

    tearDown(() {
      testCounter.dispose();
    });

    Widget createTestWidget({String title = 'Test Title'}) {
      return MultiProvider(
        providers: [
          Provider<MyCounter>.value(value: testCounter),
        ],
        child: MaterialApp(
          home: MyHomePage(title: title),
        ),
      );
    }

    testWidgets(
      'Widget initializes with correct title',
      (tester) => tester.runAsync(() async {
        await tester.pumpWidget(createTestWidget(title: 'Hello World'));
        await tester.pumpDelayed();
        expect(find.text('Hello World'), findsOneWidget);
      }),
    );

    group('State Management', () {
      testWidgets(
        '@param - title parameter is tracked and displayed',
        (tester) => tester.runAsync(() async {
          await tester.pumpWidget(createTestWidget(title: 'Initial Title'));
          await tester.pumpDelayed();

          expect(find.text('Initial Title'), findsOneWidget);

          // Rebuild with new title
          await tester.pumpWidget(createTestWidget(title: 'Updated Title'));
          expect(find.text('Updated Title'), findsOneWidget);
        }),
      );

      testWidgets(
        '@state - counter initializes at 0',
        (tester) => tester.runAsync(() async {
          await tester.pumpWidget(createTestWidget());
          await tester.pumpDelayed();

          expect(find.text('0'), findsAtLeast(2));
        }),
      );

      testWidgets(
        '@state - counter increments on button press',
        (tester) => tester.runAsync(() async {
          await tester.pumpWidget(createTestWidget());
          await tester.pumpDelayed();

          expect(find.text('0'), findsAtLeast(2));

          await tester.tap(find.byIcon(Icons.add));
          await tester.pump();

          expect(find.text('1'), findsOneWidget);

          await tester.tap(find.byIcon(Icons.add));
          await tester.pump();

          expect(find.text('2'), findsOneWidget);

          await tester.pumpDelayed();
        }),
      );

      testWidgets(
        '@state - counter updates trigger UI rebuild',
        (tester) => tester.runAsync(() async {
          await tester.pumpWidget(createTestWidget());
          await tester.pumpDelayed();

          // Find the state and update directly
          final state = tester.state<MyHomePageState>(find.byType(MyHomePage));

          state.counterState.value = 5;
          await tester.pump();

          expect(find.text('5'), findsOneWidget);
          await tester.pumpDelayed();
        }),
      );
    });

    group('Computed Properties', () {
      testWidgets(
        '@Computed.depends - doubleCounter displays correctly',
        (tester) => tester.runAsync(() async {
          await tester.pumpWidget(createTestWidget());
          await tester.pumpDelayed();

          // Initial state: counter = 0, doubleCounter = 0
          expect(find.text('0'), findsNWidgets(2)); // counter and doubleCounter

          await tester.tap(find.byIcon(Icons.add));
          await tester.pump();

          // After increment: counter = 1, doubleCounter = 2
          expect(find.text('1'), findsOneWidget);
          expect(find.text('2'), findsOneWidget);

          await tester.pumpDelayed();
        }),
      );

      testWidgets(
        '@Computed.depends - updates reactively',
        (tester) => tester.runAsync(() async {
          await tester.pumpWidget(createTestWidget());
          await tester.pumpDelayed();

          final state = tester.state<MyHomePageState>(find.byType(MyHomePage));

          state.counterState.value = 7;
          await tester.pump();

          expect(find.text('7'), findsOneWidget);
          expect(find.text('14'), findsOneWidget); // doubleCounter

          await tester.pumpDelayed();
        }),
      );
    });

    group('Environment Injection', () {
      testWidgets(
        '@Env.read() - reads MyCounter from Provider',
        (tester) => tester.runAsync(() async {
          await tester.pumpWidget(createTestWidget());
          await tester.pumpDelayed();

          expect(find.text('Test Counter 1'), findsAtLeast(2));
        }),
      );

      testWidgets(
        '@Env.read() with override - reads MyCounter from Provider',
        (tester) => tester.runAsync(() async {
          await tester.pumpWidget(createTestWidget());
          await tester.pumpDelayed();

          final state = tester.state<MyHomePageState>(find.byType(MyHomePage));

          // Verify myCounterAnotherWay also works
          expect(state.myCounterAnotherWay.title, 'Test Counter 1');
        }),
      );

      testWidgets(
        '@Env.watch() - watches MyCounter changes',
        (tester) => tester.runAsync(() async {
          await tester.pumpWidget(createTestWidget());
          await tester.pumpDelayed();

          expect(find.text('Test Title'), findsAtLeast(1));
          expect(find.text('Test Counter 2'), findsNothing);

          // Update the watched counter
          testCounter.titleState.value = 'Updated Counter 2';
          await tester.pumpAndSettle();

          expect(find.text('Updated Counter 2'), findsOneWidget);
        }),
      );

      testWidgets(
        '@Env.custom() - creates custom instance',
        (tester) => tester.runAsync(() async {
          await tester.pumpWidget(createTestWidget());
          await tester.pumpDelayed();

          expect(find.text('Hello'), findsOneWidget);
        }),
      );

      testWidgets(
        '@Env.custom() with ValueNotifier - uses cached value',
        (tester) => tester.runAsync(() async {
          await tester.pumpWidget(createTestWidget());
          await tester.pumpDelayed();

          final state = tester.state<MyHomePageState>(find.byType(MyHomePage));

          // Access multiple times should return same instance
          final first = state.myCounter4;
          final second = state.myCounter4;

          expect(identical(first, second), true);
        }),
      );

      testWidgets(
        'Generated properties without Env suffix work correctly',
        (tester) => tester.runAsync(() async {
          await tester.pumpWidget(createTestWidget());
          await tester.pumpDelayed();

          final state = tester.state<MyHomePageState>(find.byType(MyHomePage));

          // Verify we can access via generated properties
          expect(state.myCounter.title, 'Test Counter 1');
          expect(state.myCounter2.title, 'Test Counter 1');
          expect(state.myCounter3.title, 'Hello');
          expect(state.myCounter4.title, 'Merhaba');
        }),
      );
    });

    group('UI Interactions', () {
      testWidgets(
        'FloatingActionButton increments counter',
        (tester) => tester.runAsync(() async {
          await tester.pumpWidget(createTestWidget());
          await tester.pumpDelayed();

          expect(find.text('0'), findsNWidgets(2));

          await tester.tap(find.byType(FloatingActionButton));
          await tester.pump();

          expect(find.text('1'), findsOneWidget);

          await tester.pumpDelayed();
        }),
      );

      testWidgets(
        'Multiple increments work correctly',
        (tester) => tester.runAsync(() async {
          await tester.pumpWidget(createTestWidget());
          await tester.pumpDelayed();

          for (int i = 1; i <= 5; i++) {
            await tester.tap(find.byIcon(Icons.add));
            await tester.pump();
            expect(find.text('$i'), findsOneWidget);
            expect(find.text('${i * 2}'), findsOneWidget); // doubleCounter
            await tester.pumpDelayed();
          }

          await tester.pumpDelayed();
        }),
      );

      testWidgets(
        'Tooltip shows on FloatingActionButton',
        (tester) => tester.runAsync(() async {
          await tester.pumpWidget(createTestWidget());
          await tester.pumpDelayed();

          expect(find.byTooltip('Increment'), findsOneWidget);
        }),
      );

      group('ValueNotifier Extensions', () {
        testWidgets(
          'counterState.watch() rebuilds on change',
          (tester) => tester.runAsync(() async {
            await tester.pumpWidget(createTestWidget());
            await tester.pumpDelayed();

            final state = tester.state<MyHomePageState>(find.byType(MyHomePage));

            state.counterState.value = 42;
            await tester.pumpDelayed();

            expect(find.text('42'), findsNothing);

            await tester.pumpDelayed();
          }),
        );

        testWidgets(
          'titleState.watch() rebuilds on change',
          (tester) => tester.runAsync(() async {
            await tester.pumpWidget(createTestWidget(title: 'Original'));
            await tester.pumpDelayed();

            final state = tester.state<MyHomePageState>(find.byType(MyHomePage));

            state.titleState.value = 'Modified';
            await tester.pump();

            expect(find.text('Modified'), findsOneWidget);
            expect(find.text('Original'), findsNothing);
          }),
        );
      });

      group('Side Effects', () {
        testWidgets(
          '@Effect.by - auto-reset at 10',
          (tester) => tester.runAsync(() async {
            await tester.pumpWidget(createTestWidget());
            await tester.pumpDelayed();

            final state = tester.state<MyHomePageState>(find.byType(MyHomePage));

            // Set counter to 15 (should trigger auto-reset to 0)
            state.counterState.value = 15;
            await tester.pumpDelayed();

            expect(state.counterState.value, 0);
            expect(find.text('0'), findsNWidgets(2));
          }),
        );

        testWidgets(
          '@Effect.env - reacts to environment changes',
          (tester) => tester.runAsync(() async {
            await tester.pumpWidget(createTestWidget());
            await tester.pumpDelayed();

            final state = tester.state<MyHomePageState>(find.byType(MyHomePage));

            // Change myCounter4
            state.$myCounter4Notifier.value = MyCounter(title: 'Changed');
            await tester.pumpAndSettle();

            // Effect should have logged the change
            expect(state.myCounter4.title, 'Changed');
          }),
        );
      });

      group('Widget Structure', () {
        testWidgets(
          'Contains all required UI elements',
          (tester) => tester.runAsync(() async {
            await tester.pumpWidget(createTestWidget());
            await tester.pumpDelayed();

            expect(find.byType(Scaffold), findsOneWidget);
            expect(find.byType(AppBar), findsOneWidget);
            expect(find.text('You have pushed the button this many times:'), findsOneWidget);
            expect(find.byType(FloatingActionButton), findsOneWidget);
          }),
        );
      });

      group('State Lifecycle', () {
        testWidgets(
          'State initializes correctly',
          (tester) => tester.runAsync(() async {
            await tester.pumpWidget(createTestWidget());
            await tester.pumpDelayed();

            final state = tester.state<MyHomePageState>(find.byType(MyHomePage));

            expect(state.counterState, isNotNull);
            expect(state.titleState, isNotNull);
            expect(state.doubleCounterState, isNotNull);
          }),
        );

        testWidgets(
          'State persists during rebuilds',
          (tester) => tester.runAsync(() async {
            await tester.pumpWidget(createTestWidget());
            await tester.pumpDelayed();

            final state = tester.state<MyHomePageState>(find.byType(MyHomePage));
            state.counterState.value = 7;
            await tester.pumpDelayed();

            // Trigger a rebuild
            await tester.pumpWidget(createTestWidget());

            expect(state.counterState.value, 7);

            await tester.pumpDelayed();
          }),
        );
      });

      group('Query Tests', () {
        testWidgets('fetchDataQuery - initial loading state', (WidgetTester tester) async {
          await tester.pumpWidget(createTestWidget());
          await tester.pumpAndSettle(Duration(milliseconds: 30));
          expect(find.text('Loading...'), findsOneWidget);
          expect(find.text('Fetch Data: 0'), findsNothing);

          await tester.pumpAndSettle(Duration(milliseconds: 30));
          expect(find.text('Fetch Data: 0'), findsOneWidget);

        });

        testWidgets('fetchDataQuery - loads data successfully', (WidgetTester tester) async {
          await tester.pumpWidget(createTestWidget());
          await tester.pumpAndSettle(Duration(milliseconds: 60));
          expect(find.text('Loading...'), findsNothing);
          expect(find.text('Fetch Data: 0'), findsOneWidget);
        });

        testWidgets('fetchDataQuery - multiple increments', (WidgetTester tester) async {
          await tester.pumpWidget(createTestWidget());

          // Wait for initial load
          await tester.pumpAndSettle();
          expect(find.text('Fetch Data: 0'), findsOneWidget);

          // Increment counter multiple times
          for (int i = 1; i <= 3; i++) {
            await tester.tap(find.byType(FloatingActionButton));
            await tester.pump();
            await tester.pumpAndSettle();

            expect(find.text('Fetch Data: ${i * 10}'), findsOneWidget);
          }
        });
      });
    });
  });
}

extension _WidgetTesterX on WidgetTester {
  Future<void> pumpDelayed({
    Duration delay = const Duration(seconds: 1),
  }) async {
    await Future.delayed(delay);
    await pumpAndSettle();
  }
}
