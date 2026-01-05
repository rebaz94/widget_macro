import 'package:flutter/material.dart';
import 'package:todo/domain/todo.dart';
import 'package:todo/model/todo_model.dart';
import 'package:todo/widgets/todo_item.dart';
import 'package:widget_macro/widget_macro.dart';

part '../gen/widgets/todos_list.g.dart';

class TodoList extends StatefulWidget {
  const TodoList({
    super.key,
    this.onTodoToggle,
  });

  final ValueChanged<String>? onTodoToggle;

  @override
  State<TodoList> createState() => _TodoListState();
}

@widgetStateMacro
class _TodoListState extends _BaseTodoListState {
  @override
  @Env.read()
  TodoModel get todosController;

  @override
  @Env.watch()
  ValueNotifier<TodosFilter> get activeFilter;

  // Given a [filter] return the correct list of todos
  ValueNotifier<List<Todo>> mapFilterToTodosList(TodosFilter filter) {
    switch (filter) {
      case TodosFilter.all:
        return todosController.todosState;
      case TodosFilter.incomplete:
        return todosController.incompleteTodosState;
      case TodosFilter.completed:
        return todosController.completedTodosState;
    }
  }

  @override
  Widget build(BuildContext context) {
    // rebuilds every time the activeFilter value changes
    return ValueListenableBuilder(
      valueListenable: activeFilter,
      builder: (context, activeFilter, _) {
        // react to the correct list of todos list
        final todosNotifier = mapFilterToTodosList(activeFilter);
        return todosNotifier.state(
          (todos) => ListView.builder(
            itemCount: todos.length,
            itemBuilder: (BuildContext context, int index) {
              final todo = todos[index];
              return TodoItem(
                todo: todo,
                onStatusChanged: (_) {
                  widget.onTodoToggle?.call(todo.id);
                },
              );
            },
          ),
        );
      },
    );
  }
}
