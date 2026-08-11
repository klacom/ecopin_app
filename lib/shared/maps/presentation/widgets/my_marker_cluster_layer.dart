import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';

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
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                markers.length.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
