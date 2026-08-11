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

  static const protectedRoutes = [
    maps,
    reports,
    notifications,
    profile,
    createReport,
  ];
}

// Officer routes
class OfficerAppRoutes {
  static const String dashboard = '/officer/dashboard';
  static const String maps = '/officer/maps';
  static const String clusters = '/officer/clusters';
  static const String clusterDetails = '/officer/clusters/:id';
  static const String clusterCreateTask = '/officer/clusters/:id/create-task';
  static const String cleanupTasks = '/officer/cleanup-tasks';
  static const String taskDetails = '/officer/cleanup-tasks/:id';
  static const String createCustomTask = '/officer/cleanup-tasks/create';
  static const String reports = '/officer/reports';
  static const String reportDetails = '/officer/reports/:id';
  static const String responseLogs = '/officer/response-logs';
  static const String analytics = '/officer/analytics';
  static const String profile = '/officer/profile';
  static const String notifications = '/officer/notifications';

  static const officerRoutes = [
    dashboard,
    maps,
    clusters,
    cleanupTasks,
    reports,
    responseLogs,
    analytics,
    profile,
    notifications,
  ];
}

// Field Crew routes
class FieldCrewAppRoutes {
  static const String dashboard = '/field-crew/dashboard';
  static const String map = '/field-crew/map';
  static const String tasks = '/field-crew/tasks';
  static const String reports = '/field-crew/reports';
  static const String profile = '/field-crew/profile';
  static const String notifications = '/field-crew/notifications';

  static const fieldCrewRoutes = [dashboard, map, tasks, reports, profile, notifications];
}

// Admin-only routes
class AdminAppRoutes {
  static const String dashboard = '/admin/dashboard';
  static const String users = '/admin/users';
  static const String settings = '/admin/settings';
  static const String auditLogs = '/admin/audit-logs';
  static const String profile = '/admin/profile';
  static const String notifications = '/admin/notifications';

  static const adminRoutes = [dashboard, users, settings, auditLogs, profile, notifications];
}
