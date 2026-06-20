import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../routing/kiami_routes.dart';
import '../../../bootstrap/kiami_google_sign_in.dart';
import '../../../firebase/kiami_firebase.dart';
import '../data/firebase_auth_repository.dart';
import '../data/unconfigured_auth_repository.dart';
import '../domain/auth_repository.dart';
import '../domain/kiami_user.dart';
import '../presentation/auth_page.dart';
import '../../dashboard/category_files_page.dart';
import '../../dashboard/dashboard_page.dart';
import '../../../utils/file_category.dart';
import '../../settings/settings_page.dart';
import '../../settings/api_endpoint_settings_page.dart';
import '../../billing/billing_page.dart';
import '../../trash/trash_page.dart';
import '../../admin/admin_page.dart';
import '../../admin/admin_checkouts_page.dart';
import '../../admin/admin_subscriptions_page.dart';
import '../../admin/admin_user_detail_page.dart';
import '../../legal/legal_acceptance_page.dart';
import '../../shell/app_shell.dart';
import '../../splash/splash_page.dart';
import '../../../app/kiami_theme_scope.dart';
import '../../../routing/kiami_router_refresh.dart';
import '../../legal/providers/legal_acceptance_providers.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (KiamiFirebase.isConfigured) {
    return FirebaseAuthRepository(
      googleSignIn: KiamiGoogleSignIn.createInstance(),
    );
  }
  return UnconfiguredAuthRepository();
});

final authStateProvider = StreamProvider<KiamiUser?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

/// Router com redirect baseado no estado de autenticação.
final kiamiRouterProvider = Provider<GoRouter>((ref) {
  final refresh = KiamiRouterRefresh(ref);

  return GoRouter(
    initialLocation: KiamiRoutes.splash,
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authStateProvider);
      final isLoggedIn = auth.valueOrNull != null;
      final path = state.matchedLocation;
      final legalOk = ref.read(legalAcceptanceGateProvider);

      if (auth.isLoading && path != KiamiRoutes.splash) {
        return KiamiRoutes.splash;
      }

      if (path == KiamiRoutes.splash) return null;

      if (!isLoggedIn &&
          path != KiamiRoutes.auth &&
          _isProtectedRoute(path)) {
        return KiamiRoutes.auth;
      }

      if (isLoggedIn && path == KiamiRoutes.auth) {
        return legalOk ? KiamiRoutes.home : KiamiRoutes.legalAcceptance;
      }

      if (isLoggedIn && !legalOk && path != KiamiRoutes.legalAcceptance) {
        return KiamiRoutes.legalAcceptance;
      }

      if (isLoggedIn && legalOk && path == KiamiRoutes.legalAcceptance) {
        return KiamiRoutes.home;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: KiamiRoutes.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: KiamiRoutes.auth,
        builder: (context, state) => const AuthPage(),
      ),
      GoRoute(
        path: KiamiRoutes.legalAcceptance,
        builder: (context, state) => const LegalAcceptancePage(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: KiamiRoutes.home,
            builder: (context, state) => const DashboardPage(),
            routes: [
              GoRoute(
                path: 'category/:categoryId',
                builder: (context, state) {
                  final category = KiamiFileCategory.fromRouteId(
                    state.pathParameters['categoryId'],
                  );
                  if (category == null) {
                    return const DashboardPage();
                  }
                  return CategoryFilesPage(category: category);
                },
              ),
            ],
          ),
          GoRoute(
            path: KiamiRoutes.settings,
            builder: (context, state) {
              final scope = KiamiThemeScope.of(context);
              return SettingsPage(
                themeMode: scope.themeMode,
                onThemeModeChanged: scope.onThemeModeChanged,
              );
            },
            routes: [
              GoRoute(
                path: 'server',
                builder: (context, state) => const ApiEndpointSettingsPage(),
              ),
            ],
          ),
          GoRoute(
            path: KiamiRoutes.billing,
            builder: (context, state) => const BillingPage(),
          ),
          GoRoute(
            path: KiamiRoutes.trash,
            builder: (context, state) => const TrashPage(),
          ),
          GoRoute(
            path: KiamiRoutes.admin,
            builder: (context, state) => const AdminPage(),
            routes: [
              GoRoute(
                path: 'checkouts',
                builder: (context, state) => const AdminCheckoutsPage(),
              ),
              GoRoute(
                path: 'subscriptions',
                builder: (context, state) => const AdminSubscriptionsPage(),
              ),
              GoRoute(
                path: 'users/:uid',
                builder: (context, state) => AdminUserDetailPage(
                  uid: state.pathParameters['uid']!,
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

bool _isProtectedRoute(String path) {
  return path == KiamiRoutes.home ||
      path.startsWith('${KiamiRoutes.home}/category/') ||
      path == KiamiRoutes.settings ||
      path == KiamiRoutes.serverSettings ||
      path == KiamiRoutes.billing ||
      path == KiamiRoutes.trash ||
      path == KiamiRoutes.admin ||
      path.startsWith('${KiamiRoutes.admin}/');
}
