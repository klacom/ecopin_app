import 'package:flutter/material.dart';
import 'package:ecopin_app/core/theme/colors.dart';
import 'package:ecopin_app/shared/notifications/presentation/widgets/notification_badge_action.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecopin_app/features/officer/providers/officer_clusters_provider.dart';
import 'package:ecopin_app/features/officer/presentation/screens/officer_reports_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:ecopin_app/routes/app_routes.dart';

class OfficerClustersScreen extends ConsumerStatefulWidget {
  const OfficerClustersScreen({super.key});

  @override
  ConsumerState<OfficerClustersScreen> createState() => _OfficerClustersScreenState();
}

class _OfficerClustersScreenState extends ConsumerState<OfficerClustersScreen> {
  String _searchQuery = '';
  String _severityFilter = 'all';
  String _statusFilter = 'all';
  int _currentPage = 1;
  static const int _pageSize = 10;

  @override
  Widget build(BuildContext context) {
    final clustersAsync = ref.watch(officerClustersProvider).clusters;
    final reportsAsync = ref.watch(officerReportsProvider).reports;

    return Scaffold(
      appBar: AppBar(
        actions: const [NotificationBadgeAction()],
        title: const Text('Hotzone Intel'), elevation: 0),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: clustersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => _buildError(error.toString(), () => ref.read(officerClustersProvider).loadClusters()),
              data: (clusters) {
                return reportsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => _buildError(error.toString(), () => ref.read(officerReportsProvider).loadReports()),
                  data: (reports) {
                    final processedClusters = clusters.map((c) {
                      final clusterReports = reports.where((r) => r.clusterId == c.id).toList();
                      final resolvedCount = clusterReports.where((r) => r.status == 'resolved').length;
                      final totalCount = clusterReports.length;

                      String status = 'unresolved';
                      if (totalCount == 0) {
                        status = 'unresolved';
                      } else if (resolvedCount == totalCount) status = 'resolved';
                      else if (resolvedCount > 0) status = 'in_progress';

                      return Cluster(
                        id: c.id,
                        issueType: c.issueType,
                        severity: c.severity,
                        reportCount: c.reportCount,
                        createdAt: c.createdAt,
                        status: status,
                      );
                    }).toList();

                    final filteredClusters = _filterClusters(processedClusters);
                    final paginatedClusters = _paginateClusters(filteredClusters);

                    if (filteredClusters.isEmpty) {
                      return const Center(child: Text('No clusters found'));
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        top: 16,
                        bottom: 80,
                      ),
                      itemCount: paginatedClusters.length + 1,
                      itemBuilder: (context, index) {
                        if (index == paginatedClusters.length) {
                          return _buildPaginationControls(filteredClusters.length);
                        }
                        final cluster = paginatedClusters[index];
                        return _buildClusterCard(cluster);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String error, VoidCallback onRetry) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Error: $error'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('Retry'),
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
                _currentPage = 1;
              });
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _severityFilter,
                  isExpanded: true,
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
                      _currentPage = 1;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _statusFilter,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All')),
                    DropdownMenuItem(
                      value: 'unresolved',
                      child: Text('Unresolved'),
                    ),
                    DropdownMenuItem(
                      value: 'in_progress',
                      child: Text('In Progress'),
                    ),
                    DropdownMenuItem(
                      value: 'resolved',
                      child: Text('Resolved'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _statusFilter = value ?? 'all';
                      _currentPage = 1;
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
      if ((cluster.reportCount ?? 0) < 2) return false;

      final matchesSearch =
          _searchQuery.isEmpty ||
          (cluster.issueType?.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ??
              false) ||
          cluster.id.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesSeverity =
          _severityFilter == 'all' || cluster.severity == _severityFilter;

      final matchesStatus =
          _statusFilter == 'all' || cluster.status == _statusFilter;

      return matchesSearch && matchesSeverity && matchesStatus;
    }).toList();
  }

  List<Cluster> _paginateClusters(List<Cluster> clusters) {
    final start = (_currentPage - 1) * _pageSize;
    final end = start + _pageSize;
    if (start >= clusters.length) return [];
    return clusters.sublist(start, end > clusters.length ? clusters.length : end);
  }

  Widget _buildPaginationControls(int totalClusters) {
    final totalPages = (totalClusters / _pageSize).ceil();
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: _currentPage > 1
                ? () {
                    setState(() {
                      _currentPage--;
                    });
                  }
                : null,
            child: const Text('Previous'),
          ),
          const SizedBox(width: 16),
          Text('Page $_currentPage of $totalPages'),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: _currentPage < totalPages
                ? () {
                    setState(() {
                      _currentPage++;
                    });
                  }
                : null,
            child: const Text('Next'),
          ),
        ],
      ),
    );
  }

  Widget _buildClusterCard(Cluster cluster) {
    return Card(
      color: Theme.of(context).colorScheme.surface,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          context.go(OfficerAppRoutes.clusterDetails.replaceAll(':id', cluster.id));
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
        borderRadius: const BorderRadius.all(Radius.circular(AppColors.radiusChip)),
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


