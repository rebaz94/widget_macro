import 'dart:io';

import 'package:macro_kit/macro_kit.dart';
// ignore: depend_on_referenced_packages
import 'package:path/path.dart' as p;
import 'package:widget_macro/src/core/model_macro.dart';
import 'package:widget_macro/src/core/widget_state_macro.dart';

void main() async {
  final rootProject = Directory.current.path;
  final testDir = p.join(rootProject, 'test');

  await runMacro(
    autoRunMacro: false,
    package: PackageInfo.path(testDir),
    macros: {
      'WidgetStateMacro': WidgetStateMacro.initialize,
      'ModelMacro': ModelMacro.initialize,
    },
  );

  final s = Stopwatch()..start();
  final result = await waitUntilRebuildCompleted();
  print('full rebuild completed in: ${s.elapsed.inSeconds}s');

  for (final ctx in result.results) {
    if (!ctx.isSuccess) {
      print('context: ${ctx.context}, has error: ${ctx.error}');
    }
  }
}
