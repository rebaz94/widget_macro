import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todo/domain/todo.dart';
import 'package:todo/model/todo_model.dart';
import 'package:todo/widgets/todos_body.dart';

class TodosPage extends StatelessWidget {
  const TodosPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Using Provider here to provide the [TodoModel] to descendants.
    return Provider(
      create: (context) => TodoModel(initialTodos: Todo.sample),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Todos'),
        ),
        body: const Padding(
          padding: EdgeInsets.all(8),
          child: TodosBody(),
        ),
      ),
    );
  }
}
