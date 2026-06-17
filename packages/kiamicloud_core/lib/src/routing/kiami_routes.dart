import '../utils/file_category.dart';

/// Rotas nomeadas da aplicação.
abstract final class KiamiRoutes {
  static const String splash = '/';
  static const String auth = '/auth';
  static const String home = '/home';
  static const String categoryFiles = '/home/category/:categoryId';

  static String categoryFilesFor(KiamiFileCategory category) =>
      '/home/category/${category.routeId}';

  static const String settings = '/settings';
  static const String serverSettings = '/settings/server';
  static const String legalAcceptance = '/legal-acceptance';
  static const String billing = '/billing';
  static const String trash = '/trash';
  static const String shares = '/shares';
  static const String admin = '/admin';
  static const String adminCheckouts = '/admin/checkouts';
  static const String adminSubscriptions = '/admin/subscriptions';
  static const String adminUser = '/admin/users/:uid';

  static String adminUserFor(String uid) => '/admin/users/$uid';
}
