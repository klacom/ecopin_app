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

  static String updatePropertyOwnerConsent(String reportId) {
    return '/api/reports/$reportId/property-owner-consent';
  }

  static String disclosureRequests(String reportId) {
    return '/api/reports/$reportId/disclosure-requests';
  }

  static String respondToDisclosureRequest(String reportId, String disclosureRequestId) {
    return '/api/reports/$reportId/disclosure-requests/$disclosureRequestId/respond';
  }

  static String lguResolveReport(String reportId) {
    return '/api/reports/$reportId/resolve';
  }

  static String citizenCloseReport(String reportId) {
    return '/api/reports/$reportId/close';
  }

  static const String profile = '/api/profile';
  static const String avatar = '/api/profile/avatar';

  static String getCleanupTasksByCluster(String clusterId) {
    return "/api/cleanup-tasks/cluster/$clusterId";
  }

  static const String updateDataConsent = '/api/profile/data-consent';
}
