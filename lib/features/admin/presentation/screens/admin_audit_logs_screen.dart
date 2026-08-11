import 'package:flutter/material.dart';
import 'package:ecopin_app/shared/notifications/presentation/widgets/notification_badge_action.dart';

class AdminAuditLogsScreen extends StatelessWidget {
  const AdminAuditLogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: const [NotificationBadgeAction()],
        
        title: const Text('Audit Logs'),
      ),
      body: const Center(
        child: Text('Admin Audit Logs'),
      ),
    );
  }
}
