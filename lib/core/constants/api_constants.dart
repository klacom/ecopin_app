class ApiConstants {
  static const String register = '/api/auth/register';
  static const String login = '/api/auth/login';
  static const String me = '/api/auth/me';
  static const String logout = '/api/auth/logout';
  static const String createReport = '/api/reports';
  static const String getMyReports = '/api/reports/my';
  static const String getPublicReports = '/api/reports/public';

  static String getReportById(String reportId) {
    return '/api/reports/$reportId';
  }

  static String evidenceByReportId(String reportId) {
    return '/api/reports/$reportId/evidence';
  }

  static const String profile = '/api/profile';
  static const String avatar = '/api/profile/avatar';

  static String getCleanupTasksByCluster(String clusterId) {
    return "/api/cleanup-tasks/cluster/$clusterId";
  }
}
