import 'package:flutter/material.dart';
import 'package:todo/pages/todos.dart';

import 'macro_context.dart' as macro;

void main() async {
  await macro.setupMacro();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Todos Example',
      home: TodosPage(),
    );
  }
}
