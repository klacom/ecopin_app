
import 'package:ecopin_app/core/services/api_service.dart';
import 'package:ecopin_app/features/lgu/providers/lgu_cleanup_tasks_provider.dart';
import 'package:ecopin_app/features/maps/presentation/widgets/report_marker.dart';
import 'package:ecopin_app/features/reports/data/models/report_model.dart';
import 'package:ecopin_app/routes/app_routes.dart';
import 'package:ecopin_app/core/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';

class LguCreateCustomCleanupTaskScreen extends ConsumerStatefulWidget {
  const LguCreateCustomCleanupTaskScreen({super.key});

  @override
  ConsumerState<LguCreateCustomCleanupTaskScreen> createState() =>
      _LguCreateCustomCleanupTaskScreenState();
}

class _LguCreateCustomCleanupTaskScreenState
    extends ConsumerState<LguCreateCustomCleanupTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final Set<String> _selectedReportIds = {};
  List<ReportModel> _reports = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.getPublicReports();
      final List<dynamic> data = response.data is List ? response.data as List : [];
      final allReports = data.map((json) => ReportModel.fromJson(json as Map<String, dynamic>)).toList();
      // Filter to only unresolved reports, like the web version does
      final unresolvedReports = allReports.where((report) => report.status.toLowerCase() == 'unresolved').toList();
      setState(() {
        _reports = unresolvedReports;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _submitTask() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedReportIds.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select at least one report'),
          ),
        );
      }
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.createCustomCleanupTask(
        reportIds: _selectedReportIds.toList(),
        title: _titleController.text,
        description: _descriptionController.text,
      );
      if (!mounted) return;
      // Refresh tasks list before navigating back
      ref.read(lguCleanupTasksProvider).loadTasks();
      context.go(LguAppRoutes.cleanupTasks);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Custom cleanup task created successfully')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create task: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Custom Cleanup Task'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                // Responsive layout: side-by-side if screen is wide, else stacked
                if (constraints.maxWidth > 800) {
                  return Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildMapSection(),
                              const SizedBox(height: 16),
                              _buildSelectedReportsSection(),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFormSection(),
                              const SizedBox(height: 16),
                              _buildInstructions(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                } else {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFormSection(),
                        const SizedBox(height: 24),
                        _buildMapSection(),
                        const SizedBox(height: 16),
                        _buildSelectedReportsSection(),
                        const SizedBox(height: 16),
                        _buildInstructions(),
                      ],
                    ),
                  );
                }
              },
            ),
    );
  }

  Widget _buildFormSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Task Details',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Task Title *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Theme.of(context).dividerColor),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Reports Selected'),
                    Text(
                      '${_selectedReportIds.length}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitTask,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Create Cleanup Task'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: () {
                    context.pop();
                  },
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapSection() {
    // Calculate initial center based on reports, or default to Pasig initial center
    LatLng initialCenter = pasigInitialCenter;
    if (_reports.isNotEmpty) {
      double sumLat = 0;
      double sumLng = 0;
      for (var report in _reports) {
        sumLat += report.location.latitude;
        sumLng += report.location.longitude;
      }
      initialCenter = LatLng(sumLat / _reports.length, sumLng / _reports.length);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Reports',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              height: 400,
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(8),
              ),
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: initialCenter,
                  initialZoom: 15.0,
                  minZoom: 14,
                  maxZoom: 18,
                  cameraConstraint: CameraConstraint.contain(bounds: pasigBounds),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'dev.ecopinas.ecopin_app',
                    tileBounds: pasigBounds,
                  ),
                  MarkerLayer(
                    markers: _reports.map((report) {
                      final isSelected = _selectedReportIds.contains(report.id);
                      return Marker(
                        point: report.location,
                        width: 44,
                        height: 44,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              if (_selectedReportIds.contains(report.id)) {
                                _selectedReportIds.remove(report.id);
                              } else {
                                _selectedReportIds.add(report.id);
                              }
                            });
                          },
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              ReportMarker(status: report.status),
                              if (isSelected)
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 3),
                                  ),
                                  width: 44,
                                  height: 44,
                                  child: const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedReportsSection() {
    final selectedReports = _reports.where((report) => _selectedReportIds.contains(report.id)).toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    'Selected Reports (${_selectedReportIds.length})',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                if (_selectedReportIds.isNotEmpty)
                  Flexible(
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedReportIds.clear();
                        });
                      },
                      child: const Text(
                        'Clear Selection',
                        style: TextStyle(color: Colors.red),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (selectedReports.isEmpty)
              const Text(
                'No reports selected. Click on map pins to select reports.',
                style: TextStyle(color: Colors.grey),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: selectedReports.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final report = selectedReports[index];
                  return ListTile(
                    title: Text(report.title),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(report.issueType ?? 'Unknown issue'),
                        Text(
                          '${report.location.latitude.toStringAsFixed(6)}, ${report.location.longitude.toStringAsFixed(6)}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          _selectedReportIds.remove(report.id);
                        });
                      },
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    return Card(
      color: Colors.blue.shade50,
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Instructions',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('• Tap on report pins on the map to select them'),
            Text('• Select any unresolved reports for the cleanup task'),
            Text('• Enter a title for your cleanup task'),
            Text('• Click "Create Cleanup Task" to finalize'),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _mapController.dispose();
    super.dispose();
  }
}
