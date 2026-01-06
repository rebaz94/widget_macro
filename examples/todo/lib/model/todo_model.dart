import 'package:todo/domain/todo.dart';
import 'package:widget_macro/widget_macro.dart';

part '../gen/model/todo_model.g.dart';

/// Contains the state of the [todos] list and allows to
/// - `add`: Add a todo in the list of [todos]
/// - `remove`: Removes a todo with the given id from the list of [todos]
/// - `toggle`: Toggles a todo with the given id
@modelMacro
class TodoModel with TodoModelModel {
  TodoModel({
    List<Todo> initialTodos = const [],
  }) {
    onInitState();
    todosState.value = initialTodos;
  }

  @state
  List<Todo> get _todos => [];

  /// The list of completed todos
  @Computed.depends([#todosState])
  List<Todo> get _completedTodos => todosState.value.where((todo) => todo.completed).toList();

  /// The list of incomplete todos
  @Computed.depends([#todosState])
  List<Todo> get _incompleteTodos => todosState.value.where((todo) => !todo.completed).toList();

  /// Add a todo
  void add(Todo todo) {
    todosState.value = todosState.value.toList()..add(todo);
  }

  /// Remove a todo with the given [id]
  void remove(String id) {
    todosState.value = todosState.value.toList()..removeWhere((todo) => todo.id == id);
  }

  /// Toggle a todo with the given [id]
  void toggle(String id) {
    final todoIndex = todosState.value.indexWhere((todo) => todo.id == id);
    final todo = todosState.value[todoIndex];
    todosState.value = todosState.value.toList()..[todoIndex] = todo.copyWith(completed: !todo.completed);
  }
}
