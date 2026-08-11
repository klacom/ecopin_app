import 'package:flutter/material.dart';
import 'package:ecopin_app/shared/notifications/presentation/widgets/notification_badge_action.dart';

class FieldCrewTasksScreen extends StatelessWidget {
  const FieldCrewTasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: const [NotificationBadgeAction()],
        
        title: const Text('My Tasks'),
      ),
      body: const Center(
        child: Text('Field Crew Tasks Management'),
      ),
    );
  }
}
