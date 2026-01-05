import 'package:flutter/material.dart';
import 'package:todo/domain/todo.dart';
import 'package:todo/model/todo_model.dart';
import 'package:todo/widgets/todos_list.dart';
import 'package:todo/widgets/toolbar.dart';
import 'package:widget_macro/widget_macro.dart';

part '../gen/widgets/todos_body.g.dart';

class TodosBody extends StatefulWidget {
  const TodosBody({super.key});

  @override
  State<TodosBody> createState() => _TodosBodyState();
}

@widgetStateMacro
class _TodosBodyState extends _BaseTodosBodyState {
  final textController = TextEditingController();

  @state
  TodosFilter get todosFilter => TodosFilter.all;

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final todoModel = Provider.of<TodoModel>(context);

    // make the active filter visible only to descendants.
    return ChangeNotifierProvider.value(
      value: todosFilterState,
      child: Column(
        children: [
          TextFormField(
            controller: textController,
            decoration: const InputDecoration(
              hintText: 'Write new todo',
            ),
            validator: (v) {
              if (v == null || v.isEmpty) {
                return 'Cannot be empty';
              }
              return null;
            },
            onFieldSubmitted: (task) {
              if (task.isEmpty) return;
              final newTodo = Todo.create(task);
              todoModel.add(newTodo);
              textController.clear();
            },
          ),
          const SizedBox(height: 16),
          const Toolbar(),
          const SizedBox(height: 16),
          Expanded(
            child: TodoList(
              onTodoToggle: todoModel.toggle,
            ),
          ),
        ],
      ),
    );
  }
}
