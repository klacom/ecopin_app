import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecopin_app/features/lgu/providers/lgu_clusters_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:ecopin_app/routes/app_routes.dart';

class LguClustersScreen extends ConsumerStatefulWidget {
  const LguClustersScreen({super.key});

  @override
  ConsumerState<LguClustersScreen> createState() => _LguClustersScreenState();
}

class _LguClustersScreenState extends ConsumerState<LguClustersScreen> {
  String _searchQuery = '';
  String _severityFilter = 'all';
  String _statusFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final clustersAsync = ref.watch(lguClustersProvider).clusters;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clusters'),
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: clustersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Error: $error'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.read(lguClustersProvider).loadClusters(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (clusters) {
                final filteredClusters = _filterClusters(clusters);
                if (filteredClusters.isEmpty) {
                  return const Center(
                    child: Text('No clusters found'),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 80),
                  itemCount: filteredClusters.length,
                  itemBuilder: (context, index) {
                    final cluster = filteredClusters[index];
                    return _buildClusterCard(cluster);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Search clusters...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _severityFilter,
                  decoration: const InputDecoration(
                    labelText: 'Severity',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All')),
                    DropdownMenuItem(value: 'high', child: Text('High')),
                    DropdownMenuItem(value: 'medium', child: Text('Medium')),
                    DropdownMenuItem(value: 'low', child: Text('Low')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _severityFilter = value ?? 'all';
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _statusFilter,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All')),
                    DropdownMenuItem(value: 'unresolved', child: Text('Unresolved')),
                    DropdownMenuItem(value: 'in_progress', child: Text('In Progress')),
                    DropdownMenuItem(value: 'resolved', child: Text('Resolved')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _statusFilter = value ?? 'all';
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Cluster> _filterClusters(List<Cluster> clusters) {
    return clusters.where((cluster) {
      final matchesSearch = _searchQuery.isEmpty ||
          (cluster.issueType?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
          cluster.id.toLowerCase().contains(_searchQuery.toLowerCase());
      
      final matchesSeverity = _severityFilter == 'all' ||
          cluster.severity == _severityFilter;
      
      final matchesStatus = _statusFilter == 'all' ||
          cluster.status == _statusFilter;
      
      return matchesSearch && matchesSeverity && matchesStatus;
    }).toList();
  }

  Widget _buildClusterCard(Cluster cluster) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          context.go(LguAppRoutes.clusterDetails.replaceAll(':id', cluster.id));
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Cluster ${cluster.id}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildSeverityBadge(cluster.severity),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.description, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    cluster.issueType ?? 'Unknown',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.insert_chart, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${cluster.reportCount ?? 0} reports',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildStatusBadge(cluster.status),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeverityBadge(String? severity) {
    Color color;
    switch (severity) {
      case 'high':
        color = Colors.red;
        break;
      case 'medium':
        color = Colors.orange;
        break;
      case 'low':
        color = Colors.blue;
        break;
      default:
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        severity?.toUpperCase() ?? 'N/A',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String? status) {
    Color color;
    switch (status) {
      case 'resolved':
        color = Colors.green;
        break;
      case 'in_progress':
        color = Colors.orange;
        break;
      case 'unresolved':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status?.replaceAll('_', ' ').toUpperCase() ?? 'N/A',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
