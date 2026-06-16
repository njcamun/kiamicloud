import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../constants/kiami_strings.dart';
import '../features/auth/providers/auth_providers.dart';
import '../features/files/providers/files_providers.dart';
import '../routing/kiami_routes.dart';
import '../theme/kiami_colors.dart';
import '../theme/kiami_decorations.dart';
import '../utils/kiami_platform.dart';
import 'kiami_logo.dart';

/// Sidebar navy com navegacao principal (desktop / drawer).
class KiamiSidebar extends ConsumerWidget {
  const KiamiSidebar({super.key, this.onItemTap});

  final VoidCallback? onItemTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final path = GoRouterState.of(context).uri.path;
    final width = MediaQuery.sizeOf(context).width;
    final nativeDesktop = kiamiIsNativeDesktop();
    final compact = width < 1200;
    final sidebarWidth = compact ? 76.0 : (nativeDesktop ? 288.0 : 268.0);
    final logoHeight = compact ? 44.0 : (nativeDesktop ? 56.0 : 48.0);

    final user = ref.watch(authStateProvider).valueOrNull;
    final profile = ref.watch(kiamiProfileProvider).valueOrNull;

    return Container(
      width: sidebarWidth,
      decoration: const BoxDecoration(
        gradient: KiamiDecorations.sidebarGradient,
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                compact ? 14 : 24,
                nativeDesktop ? 24 : 28,
                compact ? 14 : 24,
                compact ? 16 : 20,
              ),
              child: compact
                  ? Center(
                      child: KiamiLogo(
                        height: logoHeight,
                        showIconOnly: true,
                        variant: KiamiLogoVariant.dark,
                      ),
                    )
                  : KiamiLogo(
                      height: logoHeight,
                      variant: KiamiLogoVariant.dark,
                    ),
            ),
            if (user != null && !compact)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: _SidebarUserBlock(
                  displayName: profile?.displayName ?? user.displayName,
                  email: user.email,
                  initials: user.initials,
                  planName: profile?.plan.name,
                ),
              ),
            if (user != null && compact)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Center(
                  child: Tooltip(
                    message: _greetingLine(
                      profile?.displayName ?? user.displayName,
                    ),
                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor:
                          KiamiColors.primaryBlue.withValues(alpha: 0.35),
                      child: Text(
                        user.initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _NavItem(
                    icon: Icons.folder_outlined,
                    selectedIcon: Icons.folder_rounded,
                    label: KiamiStrings.navFiles,
                    selected: path == KiamiRoutes.home,
                    compact: compact,
                    onTap: () {
                      context.go(KiamiRoutes.home);
                      onItemTap?.call();
                    },
                  ),
                  const SizedBox(height: 6),
                  _NavItem(
                    icon: Icons.settings_outlined,
                    selectedIcon: Icons.settings_rounded,
                    label: KiamiStrings.navSettings,
                    selected: path.startsWith(KiamiRoutes.settings) ||
                        path.startsWith(KiamiRoutes.billing) ||
                        path.startsWith(KiamiRoutes.admin),
                    compact: compact,
                    onTap: () {
                      context.go(KiamiRoutes.settings);
                      onItemTap?.call();
                    },
                  ),
                ],
              ),
            ),
            if (!compact)
              Padding(
                padding: EdgeInsets.fromLTRB(24, 0, 24, nativeDesktop ? 32 : 28),
                child: Text(
                  KiamiStrings.slogan,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: KiamiColors.softWhite.withValues(alpha: 0.55),
                        height: 1.4,
                      ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

String _greetingLine(String? displayName) {
  final name = displayName?.trim();
  if (name != null && name.isNotEmpty) {
    return '${KiamiStrings.dashboardGreeting}, $name';
  }
  return KiamiStrings.dashboardTitle;
}

class _SidebarUserBlock extends StatelessWidget {
  const _SidebarUserBlock({
    required this.displayName,
    required this.email,
    required this.initials,
    this.planName,
  });

  final String? displayName;
  final String? email;
  final String initials;
  final String? planName;

  @override
  Widget build(BuildContext context) {
    final greeting = _greetingLine(displayName);
    final mail = email?.trim();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(KiamiDecorations.radiusMd),
        border: Border.all(
          color: KiamiColors.cloudBlue.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: KiamiColors.primaryBlue.withValues(alpha: 0.45),
            child: Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    height: 1.2,
                  ),
                ),
                if (mail != null && mail.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    mail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: KiamiColors.softWhite.withValues(alpha: 0.65),
                      fontSize: 12,
                      height: 1.2,
                    ),
                  ),
                ],
                if (planName != null && planName!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: KiamiColors.cloudBlue.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      planName!,
                      style: const TextStyle(
                        color: KiamiColors.cloudBlue,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = selected
        ? KiamiColors.primaryBlue.withValues(alpha: 0.22)
        : Colors.transparent;
    final glow = selected ? KiamiDecorations.primaryGlow : null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(KiamiDecorations.radiusMd),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 0 : 16,
            vertical: compact ? 14 : 14,
          ),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(KiamiDecorations.radiusMd),
            border: selected
                ? Border.all(
                    color: KiamiColors.cloudBlue.withValues(alpha: 0.35),
                  )
                : null,
            boxShadow: glow,
          ),
          child: compact
              ? Icon(
                  selected ? selectedIcon : icon,
                  color: selected
                      ? KiamiColors.cloudBlue
                      : KiamiColors.softWhite.withValues(alpha: 0.7),
                  size: 26,
                )
              : Row(
                  children: [
                    Icon(
                      selected ? selectedIcon : icon,
                      color: selected
                          ? KiamiColors.cloudBlue
                          : KiamiColors.softWhite.withValues(alpha: 0.75),
                      size: 22,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          color: selected
                              ? Colors.white
                              : KiamiColors.softWhite.withValues(alpha: 0.8),
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.w500,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
