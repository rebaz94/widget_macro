/// A macro-powered state management solution for Flutter that eliminates boilerplate code.
///
/// This package provides two main macros:
///
/// 1. **[WidgetStateMacro]** - Applied to StatefulWidget State classes to automatically generate
///    reactive state management, side effects, and dependency injection.
///
/// 2. **[ModelMacro]** - Applied to regular classes to manage state outside of widgets.
///    Works like [WidgetStateMacro] but creates shareable models for app-wide state management.
library;

import 'package:widget_macro/src/core/widget_state_macro.dart';

export 'package:flutter/foundation.dart' show ValueNotifier, protected, mustCallSuper;
export 'package:provider/provider.dart';
// ignore: depend_on_referenced_packages
export 'package:meta/meta.dart' show mustBeOverridden;

export './src/core/annotation.dart' hide Prop, StateFlags;
export './src/core/base.dart' show BaseStateMixin, EffectFnInfo, MacroEffectUtils;
export './src/core/model_macro.dart' show ModelMacro, modelMacro, modelMacroCapability;
export './src/core/widget_state_macro.dart' show WidgetStateMacro, widgetStateMacro, widgetStateMacroCapability;
export './src/extensions/value_notifier.dart';
export './src/core/resource.dart';
