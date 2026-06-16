import 'package:flutter/material.dart';

/// Estado de tema partilhado (light / dark / system).
class KiamiThemeScope extends InheritedWidget {
  const KiamiThemeScope({
    super.key,
    required this.themeMode,
    required this.onThemeModeChanged,
    required super.child,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  static KiamiThemeScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<KiamiThemeScope>();
    assert(scope != null, 'KiamiThemeScope não encontrado na árvore de widgets');
    return scope!;
  }

  @override
  bool updateShouldNotify(KiamiThemeScope oldWidget) =>
      oldWidget.themeMode != themeMode;
}
