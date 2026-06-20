/// Estado de instalação PWA (Web / mobile browser).
class PwaInstallState {
  const PwaInstallState({
    this.isStandalone = false,
    this.canInstallAndroid = false,
    this.showIosHint = false,
    this.dismissed = false,
  });

  final bool isStandalone;
  final bool canInstallAndroid;
  final bool showIosHint;
  final bool dismissed;

  bool get shouldShowBanner =>
      !isStandalone &&
      !dismissed &&
      (canInstallAndroid || showIosHint);

  PwaInstallState copyWith({
    bool? isStandalone,
    bool? canInstallAndroid,
    bool? showIosHint,
    bool? dismissed,
  }) {
    return PwaInstallState(
      isStandalone: isStandalone ?? this.isStandalone,
      canInstallAndroid: canInstallAndroid ?? this.canInstallAndroid,
      showIosHint: showIosHint ?? this.showIosHint,
      dismissed: dismissed ?? this.dismissed,
    );
  }
}
