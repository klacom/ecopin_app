import 'package:flutter/material.dart';
import 'package:ecopin_app/core/theme/colors.dart';
import 'package:ecopin_app/core/theme/typography.dart';
import 'package:ecopin_app/shared/notifications/presentation/widgets/notification_badge_action.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecopin_app/features/officer/providers/officer_clusters_provider.dart';
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

  @override
  Widget build(BuildContext context) {
    final clustersAsync = ref.watch(officerClustersProvider).clusters;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Hotzone Intel',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        centerTitle: false,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 8.0),
            child: NotificationBadgeAction(),
          )
        ],
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
                      onPressed: () =>
                          ref.read(officerClustersProvider).loadClusters(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (clusters) {
                final filteredClusters = _filterClusters(clusters);
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

  void _showFilterSheet() {
    String tempSeverity = _severityFilter;
    String tempStatus = _statusFilter;
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final officerColor = AppColors.primaryDark;
    final fillColor = isDark ? AppColors.surfaceDark : Colors.grey.shade100;
    final textColor = isDark ? AppColors.textPrimaryDark : Colors.black87;

    final severityOptions = ['all', 'high', 'medium', 'low'];
    final statusOptions = ['all', 'unresolved', 'in_progress', 'resolved'];

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppColors.radiusDialog)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.4,
          maxChildSize: 0.8,
          expand: false,
          builder: (context, scrollController) {
            return StatefulBuilder(
              builder: (ctx, setModalState) {
                return Padding(
                  padding: const EdgeInsets.all(AppColors.spaceLG),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Filters', style: AppTypography.h4.copyWith(color: textColor)),
                      const SizedBox(height: AppColors.spaceLG),
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          children: [
                            Text('Severity', style: AppTypography.label.copyWith(color: Colors.grey)),
                            const SizedBox(height: AppColors.spaceSM),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: severityOptions.map((severity) {
                                final isSelected = tempSeverity == severity;
                                return ChoiceChip(
                                  label: Text(_formatSeverity(severity),
                                      style: TextStyle(
                                          color: isSelected ? Colors.white : textColor)),
                                  selected: isSelected,
                                  selectedColor: officerColor,
                                  backgroundColor: fillColor,
                                  onSelected: (val) {
                                    if (val) setModalState(() => tempSeverity = severity);
                                  },
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: AppColors.spaceLG),
                            Text('Status', style: AppTypography.label.copyWith(color: Colors.grey)),
                            const SizedBox(height: AppColors.spaceSM),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: statusOptions.map((status) {
                                final isSelected = tempStatus == status;
                                return ChoiceChip(
                                  label: Text(_formatStatus(status),
                                      style: TextStyle(
                                          color: isSelected ? Colors.white : textColor)),
                                  selected: isSelected,
                                  selectedColor: officerColor,
                                  backgroundColor: fillColor,
                                  onSelected: (val) {
                                    if (val) setModalState(() => tempStatus = status);
                                  },
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppColors.spaceLG),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _severityFilter = tempSeverity;
                              _statusFilter = tempStatus;
                            });
                            Navigator.pop(ctx);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: officerColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppColors.radiusButton)),
                          ),
                          child: Text('Apply Filters',
                              style: AppTypography.button.copyWith(color: Colors.white)),
                        ),
                      )
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  String _formatSeverity(String val) {
    if (val == 'all') return 'All';
    return val[0].toUpperCase() + val.substring(1);
  }

  String _formatStatus(String val) {
    if (val == 'all') return 'All';
    if (val == 'in_progress') return 'In Progress';
    if (val == 'unresolved') return 'Unresolved';
    if (val == 'resolved') return 'Resolved';
    return val;
  }

  Widget _buildFilters() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final officerColor = AppColors.primaryDark;
    final fillColor = isDark ? AppColors.surfaceDark : Colors.grey.shade100;
    final textColor = isDark ? AppColors.textPrimaryDark : Colors.black87;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (val) {
                    setState(() { _searchQuery = val; });
                  },
                  style: AppTypography.body.copyWith(color: textColor),
                  decoration: InputDecoration(
                    hintText: 'Search clusters...',
                    hintStyle: AppTypography.body.copyWith(color: Colors.grey),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: fillColor,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppColors.radiusInput),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppColors.spaceSM),
              IconButton(
                onPressed: _showFilterSheet,
                icon: const Icon(Icons.filter_list, color: Colors.white),
                style: IconButton.styleFrom(
                  backgroundColor: officerColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppColors.radiusInput)),
                  padding: const EdgeInsets.all(12),
                ),
              )
            ],
          ),
          const SizedBox(height: AppColors.spaceSM),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                if (_searchQuery.isNotEmpty || _severityFilter != 'all' || _statusFilter != 'all')
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ActionChip(
                      label: const Text('Reset', style: TextStyle(color: Colors.white)),
                      backgroundColor: officerColor,
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                          _severityFilter = 'all';
                          _statusFilter = 'all';
                        });
                      },
                    ),
                  ),
                if (_severityFilter != 'all')
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Chip(
                      label: Text(_formatSeverity(_severityFilter), style: TextStyle(color: textColor)),
                      backgroundColor: fillColor,
                      side: BorderSide(color: officerColor),
                      onDeleted: () { setState(() { _severityFilter = 'all'; }); },
                      deleteIconColor: officerColor,
                    ),
                  ),
                if (_statusFilter != 'all')
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Chip(
                      label: Text(_formatStatus(_statusFilter), style: TextStyle(color: textColor)),
                      backgroundColor: fillColor,
                      side: BorderSide(color: officerColor),
                      onDeleted: () { setState(() { _statusFilter = 'all'; }); },
                      deleteIconColor: officerColor,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Cluster> _filterClusters(List<Cluster> clusters) {
    return clusters.where((cluster) {
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

  Widget _buildClusterCard(Cluster cluster) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
        ],
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade100,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          context.go(OfficerAppRoutes.clusterDetails.replaceAll(':id', cluster.id));
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Text(
                          'Cluster ${cluster.id.length > 8 ? '${cluster.id.substring(0, 8)}...' : cluster.id}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        _buildSeverityBadge(cluster.severity),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildStatusBadge(cluster.status),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.bar_chart, size: 16, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Text(
                    '${cluster.reportCount ?? 0} Reports',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (cluster.issueType != null) ...[
                    const SizedBox(width: 16),
                    Icon(Icons.category_outlined, size: 16, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        cluster.issueType!,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
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


