// Accessible by everyone

class PublicAppRoutes {
  static const String splash = '/splash';
  static const String landing = '/landing';
  static const String login = '/login';
  static const String register = '/register';
  static const String unauthorized = '/unauthorized';
  static const String emailVerification = '/email-verification';
  static const String forgotPassword = '/forgot-password';

  static const publicRoutes = [landing, login, register, unauthorized, emailVerification, forgotPassword];
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

// Field Crew routes
class FieldCrewAppRoutes {
  static const String dashboard = '/field-crew/dashboard';
  static const String map = '/field-crew/map';
  static const String tasks = '/field-crew/tasks';
  static const String taskDetail = '/field-crew/tasks/:id';
  static const String reportDetail = '/field-crew/tasks/:id/reports/:reportId';
  static const String reports = '/field-crew/reports';
  static const String rawDataReportDetail = '/field-crew/reports/:reportId';
  static const String profile = '/field-crew/profile';
  static const String performance = '/field-crew/performance';
  static const String notifications = '/field-crew/notifications';
  static const String syncCenter = '/field-crew/sync-center';
  static const String prepareOffline = '/field-crew/prepare-offline';

  static const fieldCrewRoutes = [dashboard, map, tasks, reports, profile, performance, notifications];
}

