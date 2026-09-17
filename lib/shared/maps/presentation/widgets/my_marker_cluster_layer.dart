import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:ecopin_app/core/theme/colors.dart';

class MyMarkerClusterLayer extends StatefulWidget {
  final List<Marker> markers;

  const MyMarkerClusterLayer({super.key, required this.markers});

  @override
  State<MyMarkerClusterLayer> createState() => MyMarkerClusterLayerState();
}

class MyMarkerClusterLayerState extends State<MyMarkerClusterLayer> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MarkerClusterLayerWidget(
      options: MarkerClusterLayerOptions(
        markers: widget.markers,
        builder: (context, markers) {
          return Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              border: Border.all(
                color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark ? AppColors.accent : AppColors.shadowCard,
                  offset: const Offset(4, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                markers.length.toString(),
                style: TextStyle(
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
