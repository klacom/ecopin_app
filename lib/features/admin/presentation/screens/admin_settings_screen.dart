import 'package:flutter/material.dart';
import 'package:ecopin_app/shared/notifications/presentation/widgets/notification_badge_action.dart';

class AdminSettingsScreen extends StatelessWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: const [NotificationBadgeAction()],
        
        title: const Text('System Settings'),
      ),
      body: const Center(
        child: Text('Admin Settings'),
      ),
    );
  }
}
