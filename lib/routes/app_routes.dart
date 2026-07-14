// Accessible by everyone

class PublicAppRoutes {
  static const String splash = '/splash';
  static const String login = '/login';
  static const String register = '/register';
  static const String unauthorized = '/unauthorized';

  static const publicRoutes = [login, register, unauthorized];
}

// Only accessible by authenticated users

class ProtectedAppRoutes {
  static const String maps = '/maps';
  static const String reports = '/reports';
  static const String notifications = '/notifications';
  static const String profile = '/profile';
  static const String createReport = '/create-report';

  static const protectedRoutes = [maps, reports, notifications, profile, createReport];
}

// LGU-only routes
class LguAppRoutes {
  static const String dashboard = '/lgu/dashboard';
  static const String maps = '/lgu/maps';
  static const String clusters = '/lgu/clusters';
  static const String clusterDetails = '/lgu/clusters/:id';
  static const String cleanupTasks = '/lgu/cleanup-tasks';
  static const String taskDetails = '/lgu/cleanup-tasks/:id';
  static const String createCustomTask = '/lgu/cleanup-tasks/create';
  static const String reports = '/lgu/reports';
  static const String reportDetails = '/lgu/reports/:id';
  static const String responseLogs = '/lgu/response-logs';
  static const String profile = '/lgu/profile';

  static const lguRoutes = [dashboard, maps, clusters, cleanupTasks, reports, responseLogs, profile];
}

// Admin-only routes
class AdminAppRoutes {
  static const String dashboard = '/admin/dashboard';
  static const String users = '/admin/users';
  static const String settings = '/admin/settings';
  static const String auditLogs = '/admin/audit-logs';

  static const adminRoutes = [dashboard, users, settings, auditLogs];
}
