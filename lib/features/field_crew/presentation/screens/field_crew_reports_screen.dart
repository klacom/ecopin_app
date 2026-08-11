import 'package:flutter/material.dart';
import 'package:ecopin_app/shared/notifications/presentation/widgets/notification_badge_action.dart';

class FieldCrewReportsScreen extends StatelessWidget {
  const FieldCrewReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: const [NotificationBadgeAction()],
        
        title: const Text('Field Reports'),
      ),
      body: const Center(
        child: Text('Field Crew Reports Overview'),
      ),
    );
  }
}
