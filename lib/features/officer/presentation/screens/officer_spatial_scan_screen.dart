import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:ecopin_app/features/officer/providers/officer_spatial_scan_provider.dart';
import 'package:ecopin_app/core/constants/app_constants.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ecopin_app/shared/notifications/presentation/widgets/notification_badge_action.dart';

class OfficerSpatialScanScreen extends ConsumerStatefulWidget {
  const OfficerSpatialScanScreen({super.key});

  @override
  ConsumerState<OfficerSpatialScanScreen> createState() => _OfficerSpatialScanScreenState();
}

class _OfficerSpatialScanScreenState extends ConsumerState<OfficerSpatialScanScreen> {
  String _timeHorizon = 'weekly';
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(spatialScanProvider).loadCurrentPredictions(_timeHorizon);
    });
  }

  void _generateForecast() {
    ref.read(spatialScanProvider).generateForecast(_timeHorizon);
  }

  void _refresh() {
    ref.read(spatialScanProvider).loadCurrentPredictions(_timeHorizon);
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.watch(spatialScanProvider);
    final state = notifier.state;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Spatial Scan'),
        elevation: 0,
        actions: const [NotificationBadgeAction()],
      ),
      body: Column(
        children: [
          _buildControls(state),
          if (state.error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Error: ${state.error}',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          Expanded(
            flex: 2,
            child: Stack(
              children: [
                _buildMap(state),
                if (state.isLoading || state.isGenerating)
                  const Center(child: CircularProgressIndicator()),
              ],
            ),
          ),
          _buildHotspotList(state),
        ],
      ),
    );
  }

  Widget _buildControls(SpatialScanState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _timeHorizon,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Time Horizon',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: const [
                DropdownMenuItem(value: 'daily', child: Text('Daily (24h)', style: TextStyle(fontSize: 12))),
                DropdownMenuItem(value: 'weekly', child: Text('Weekly (7d)', style: TextStyle(fontSize: 12))),
                DropdownMenuItem(value: 'monthly', child: Text('Monthly (30d)', style: TextStyle(fontSize: 12))),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() => _timeHorizon = val);
                  _refresh();
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: (state.isLoading || state.isGenerating) ? null : _generateForecast,
            child: const Text('Generate'),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: (state.isLoading || state.isGenerating) ? null : _refresh,
          ),
        ],
      ),
    );
  }

  Widget _buildMap(SpatialScanState state) {
    List<Marker> markers = [];
    final analyses = state.currentPredictions?['region_analyses'];

    if (analyses != null) {
      Iterable values = analyses is List ? analyses : (analyses as Map).values;
      for (var region in values) {
        if (region['is_hotspot'] == true || (region['risk_score'] ?? 0) > 0) {
          final lat = region['region_center_lat'] ?? region['center_lat'];
          final lng = region['region_center_lng'] ?? region['center_lng'];
          final rank = region['rank'] ?? '?';
          final riskLevel = region['risk_level'] ?? 'low';

          Color color = Colors.green;
          if (riskLevel == 'high') color = Colors.red;
          if (riskLevel == 'medium') color = Colors.orange;

          if (lat != null && lng != null) {
            markers.add(
              Marker(
                point: LatLng(lat, lng),
                width: 30,
                height: 30,
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      '#$rank',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }
        }
      }
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: pasigInitialCenter,
        initialZoom: 13.0,
      ),
      children: [
        TileLayer(
          urlTemplate: Theme.of(context).brightness == Brightness.dark
              ? 'https://api.maptiler.com/maps/streets-v2-dark/{z}/{x}/{y}.png?key=${dotenv.env['MAPTILER_API_KEY'] ?? ''}'
              : 'https://api.maptiler.com/maps/streets-v2/{z}/{x}/{y}.png?key=${dotenv.env['MAPTILER_API_KEY'] ?? ''}',
          userAgentPackageName: 'dev.ecopinas.ecopin_app',
        ),
        MarkerLayer(markers: markers),
      ],
    );
  }

  Widget _buildHotspotList(SpatialScanState state) {
    final analyses = state.currentPredictions?['region_analyses'];
    List<dynamic> hotspots = [];

    if (analyses != null) {
      Iterable values = analyses is List ? analyses : (analyses as Map).values;
      hotspots = values.where((r) => r['is_hotspot'] == true || (r['risk_score'] ?? 0) > 0).toList();
      hotspots.sort((a, b) => (b['risk_score'] ?? 0).compareTo(a['risk_score'] ?? 0));
    }

    if (hotspots.isEmpty) return const SizedBox.shrink();

    return Expanded(
      flex: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Identified Hotspots',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 80), // To clear bottom nav bar
              itemCount: hotspots.length,
              itemBuilder: (context, index) {
                final h = hotspots[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: h['risk_level'] == 'high' 
                        ? Colors.red 
                        : (h['risk_level'] == 'medium' ? Colors.orange : Colors.green),
                    child: Text(
                      '#${h['rank'] ?? '?'}',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                  title: Text('Reports: ${h['report_count'] ?? 0}'),
                  subtitle: Text('Top Issue: ${h['top_issue_type']?.replaceAll('_', ' ') ?? 'N/A'}'),
                  trailing: Text(
                    'Risk: ${h['risk_score'] != null ? (h['risk_score'] * 100).toStringAsFixed(0) : 0}%',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
