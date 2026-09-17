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
    return MarkerClusterLayerWidget(
      options: MarkerClusterLayerOptions(
        markers: widget.markers,
        builder: (context, markers) {
          return Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.accent,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.4),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: Text(
                markers.length.toString(),
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
