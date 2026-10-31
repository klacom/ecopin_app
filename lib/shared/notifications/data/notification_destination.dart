import 'package:ecopin_app/core/constants/app_constants.dart';
import 'package:ecopin_app/routes/app_routes.dart';

class NotificationDestination {
  const NotificationDestination(this.path, this.label);
  final String path, label;
}

NotificationDestination? notificationDestination(
  Map<String, dynamic> notification,
  UserRole role,
) {
  final id = notification['report_id'];
  if (id is! String || id.trim().isEmpty) return null;
  final encoded = Uri.encodeComponent(id);
  final prefix = switch (role) {
    UserRole.citizen => ProtectedAppRoutes.reports,
    UserRole.fieldCrew => FieldCrewAppRoutes.reports,
    UserRole.officer || UserRole.admin => null,
  };
  // There is no officer or admin mobile route, nor a task ID in the current notification
  // contract. Do not invent a deep link or infer an identifier from the body.
  return prefix == null
      ? null
      : NotificationDestination('$prefix/$encoded', 'Open report');
}
