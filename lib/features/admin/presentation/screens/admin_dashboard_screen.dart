import 'package:flutter/material.dart';
import 'package:ecopin_app/shared/notifications/presentation/widgets/notification_badge_action.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: const [NotificationBadgeAction()],
        
        title: const Text('Admin Dashboard'),
      ),
      body: const Center(
        child: Text('Admin Dashboard Overview'),
      ),
    );
  }
}
