// Accessible by everyone

class PublicAppRoutes {
  static const String splash = '/splash';
  static const String landing = '/landing';
  static const String login = '/login';
  static const String register = '/register';
  static const String unauthorized = '/unauthorized';
  static const String emailVerification = '/email-verification';

  static const publicRoutes = [landing, login, register, unauthorized, emailVerification];
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
  // Command Center
  static const String commandCenter = '/officer/command-center';
  
  // Intel Hub
  static const String intel = '/officer/intel';
  static const String intelHotzone = '/officer/intel/hotzone';
  static const String intelMapGrid = '/officer/intel/map-grid';
  static const String intelSpatialScan = '/officer/intel/spatial-scan';
  
  // Operations
  static const String operations = '/officer/operations';
  
  // Analytics Hub
  static const String analytics = '/officer/analytics';
  static const String analyticsReports = '/officer/analytics/reports';
  static const String analyticsMetrics = '/officer/analytics/metrics';
  static const String analyticsOptimization = '/officer/analytics/optimization';
  
  // Legacy routes for backward compatibility
  static const String dashboard = '/officer/dashboard';
  static const String reports = '/officer/reports';
  static const String reportDetails = '/officer/reports/:id';
  static const String maps = '/officer/maps';
  static const String spatialScan = '/officer/spatial-scan';
  static const String optimization = '/officer/optimization';
  static const String responseLogs = '/officer/response-logs';
  static const String notifications = '/officer/notifications';
  static const String clusters = '/officer/clusters';
  static const String clusterDetails = '/officer/clusters/:id';
  static const String clusterCreateTask = '/officer/clusters/:id/create-task';
  static const String cleanupTasks = '/officer/cleanup-tasks';
  static const String taskDetails = '/officer/cleanup-tasks/:id';
  
  // Profile (Top-level)
  static const String profile = '/officer/profile';

  static const officerRoutes = [
    commandCenter,
    intel,
    intelHotzone,
    intelMapGrid,
    intelSpatialScan,
    operations,
    analytics,
    analyticsReports,
    analyticsMetrics,
    analyticsOptimization,
    profile,
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
  static const String notifications = '/field-crew/notifications';
  static const String syncCenter = '/field-crew/sync-center';
  static const String prepareOffline = '/field-crew/prepare-offline';

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
