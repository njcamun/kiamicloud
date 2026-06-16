import 'package:flutter/material.dart';

/// Wrapper de layout (SafeArea) — mantido para compatibilidade com [AppShell].
class BetaBanner extends StatelessWidget {
  const BetaBanner({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: true,
      bottom: true,
      minimum: EdgeInsets.zero,
      child: child,
    );
  }
}
