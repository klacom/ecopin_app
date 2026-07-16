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
  static const String changePassword = '/api/auth/change-password';

  // LGU API Constants
  static const String systemStats = '/api/admin/stats';
  static const String clusters = '/api/clusters';
  static const String cleanupTasks = '/api/cleanup-tasks';
  static const String createCustomCleanupTask = '/api/cleanup-tasks/custom';
  static const String responseLogs = '/api/response-logs';
  static const String reports = '/api/reports';
  static const String satisfactionAnalytics = '/api/reports/analytics/satisfaction';

  static String clusterById(String clusterId) {
    return '/api/clusters/$clusterId';
  }

  static String cleanupTaskById(String taskId) {
    return '/api/cleanup-tasks/$taskId';
  }

  static String cleanupTaskUploadPhoto(String taskId) {
    return '/api/cleanup-tasks/$taskId/photo';
  }

  static String markCleanupTaskComplete(String taskId) {
    return '/api/cleanup-tasks/$taskId/complete';
  }

  static String updateReportStatus(String reportId) {
    return '/api/reports/$reportId/status';
  }

  static String updateReportValidation(String reportId) {
    return '/api/reports/$reportId/validation';
  }

  static String updateReportLifecycleStage(String reportId) {
    return '/api/reports/$reportId/lifecycle-stage';
  }

  static String acknowledgeComplaint(String reportId) {
    return '/api/reports/$reportId/acknowledge';
  }

  static String agencyResponses(String reportId) {
    return '/api/reports/$reportId/agency-responses';
  }

  static String updateReportNotes(String reportId) {
    return '/api/reports/$reportId/notes';
  }

  static String uploadReportPhoto(String reportId) {
    return '/api/reports/$reportId/photo';
  }

  static String batchCompleteReportsByCluster(String clusterId) {
    return '/api/reports/cluster/$clusterId/complete';
  }
}
