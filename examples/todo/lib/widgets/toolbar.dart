import 'package:flutter/material.dart';
import 'package:todo/domain/todo.dart';
import 'package:todo/model/todo_model.dart';
import 'package:widget_macro/widget_macro.dart';

part '../gen/widgets/toolbar.g.dart';

class Toolbar extends StatefulWidget {
  const Toolbar({super.key});

  @override
  State<Toolbar> createState() => _ToolbarState();
}

@widgetStateMacro
class _ToolbarState extends _BaseToolbarState {
  @override
  @Env.read()
  TodoModel get todosModel;

  @override
  @Env.read()
  ValueNotifier<TodosFilter> get currentFilter;

  /// initial index of TabBar based on environment
  late final initialIndex = currentFilter.value.index;

  /// All the derived values, they will react only when the `length` property
  /// changes
  @Computed.depends([#todosModel.todosState])
  int get _allTodosCount => todosModel.todosState.value.length;

  @Computed.depends([#todosModel.incompleteTodosState])
  int get _incompleteTodosCount => todosModel.incompleteTodosState.value.length;

  @Computed.depends([#todosModel.completedTodosState])
  int get _completedTodosCount => todosModel.completedTodosState.value.length;

  @Effect.by([#todosModel.completedTodosState])
  void onCompletedToDoChanged() {
    print('completed todo count changed to: ${completedTodosCountState.value}');
  }

  /// Maps the given [filter] to the correct list of todos
  ValueNotifier<int> mapFilterToTodosList(TodosFilter filter) {
    switch (filter) {
      case TodosFilter.all:
        return allTodosCountState;
      case TodosFilter.incomplete:
        return incompleteTodosCountState;
      case TodosFilter.completed:
        return completedTodosCountState;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: TodosFilter.values.length,
      initialIndex: initialIndex,
      child: TabBar(
        labelColor: Colors.black,
        tabs: TodosFilter.values.map(
          (filter) {
            final todosCount = mapFilterToTodosList(filter);
            // Each tab bar is using its specific todos count signal
            return ValueListenableBuilder(
              valueListenable: mapFilterToTodosList(filter),
              builder: (context, child, _) {
                return Tab(text: '${filter.name} (${todosCount.value})');
              },
            );
          },
        ).toList(),
        onTap: (index) {
          // update the current active filter
          Provider.of<ValueNotifier<TodosFilter>>(context, listen: false).value = TodosFilter.values[index];
        },
      ),
    );
  }
}
