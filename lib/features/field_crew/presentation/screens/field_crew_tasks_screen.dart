import 'package:flutter/material.dart';
import 'package:ecopin_app/shared/notifications/presentation/widgets/notification_badge_action.dart';
import '../widgets/tasks/fc_task_cluster_card.dart';
import 'fc_cluster_detail_screen.dart';

class FieldCrewTasksScreen extends StatelessWidget {
  const FieldCrewTasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          actions: const [NotificationBadgeAction()],
          title: const Text('My Tasks'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Recommended'),
              Tab(text: 'All Tasks'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Recommended Tab
            ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: 2, // Mock 2 clusters
              itemBuilder: (context, index) {
                return FcTaskClusterCard(
                  onTapCard: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FcClusterDetailScreen(),
                      ),
                    );
                  },
                );
              },
            ),
            // All Tasks Tab (Placeholder)
            const Center(
              child: Text('All tasks will be listed here.'),
            ),
          ],
        ),
      ),
    );
  }
}
