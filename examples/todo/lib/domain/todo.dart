import 'dart:math';

import 'package:macro_kit/macro_kit.dart';

part '../gen/domain/todo.g.dart';

final _rnd = Random();

@dataClassMacro
class Todo with TodoData {
  const Todo({
    required this.id,
    required this.task,
    required this.completed,
  });

  factory Todo.create(String task) {
    return Todo(id: _rnd.nextInt(100000).toString(), task: task, completed: false);
  }

  final String id;
  final String task;
  final bool completed;

  static List<Todo> get sample {
    return [
      Todo.create('Learn WidgetMacro'),
      Todo.create('Wash the car'),
      Todo.create('Learn MacroKit'),
      Todo.create('Go shopping'),
      Todo.create('Read a book'),
    ];
  }
}

enum TodosFilter { all, incomplete, completed }
