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
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 2,
              ),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadowCard,
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                markers.length.toString(),
                style: TextStyle(
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
