import 'package:ecopin_app/core/constants/app_constants.dart';

// This class provides static methods to check if a user has the necessary permissions to access certain features of the app based on their role. It uses the UserRole enum defined in app_constants.dart to determine the user's role and return a boolean indicating whether they have access to specific features like admin access, report management, and task viewing.

//TODO: This is a very basic implementation. In a real app, we might want to implement a more robust RBAC system that can handle more complex permissions and roles, possibly using a package like 'rbac' or 'permission_handler' for Flutter.
class Permissions {
  static bool canAccessAdmin(UserRole? role) {
    return role == UserRole.admin;
  }

  static bool canManageReports(UserRole? role) {
    return role == UserRole.admin || role == UserRole.officer;
  }

  static bool canViewTasks(UserRole? role) {
    return role == UserRole.admin || role == UserRole.officer || role == UserRole.fieldCrew;
  }
}
