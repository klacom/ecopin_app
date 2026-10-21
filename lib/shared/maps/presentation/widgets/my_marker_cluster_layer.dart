import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:ecopin_app/core/theme/colors.dart';
import 'report_marker.dart';

class MyMarkerClusterLayer extends StatelessWidget {
  const MyMarkerClusterLayer({super.key, required this.markers});
  final List<Marker> markers;
  @override
  Widget build(BuildContext context) => MarkerClusterLayerWidget(
    options: MarkerClusterLayerOptions(
      size: const Size(ReportPinFrame.width, ReportPinFrame.height),
      alignment: Alignment.topCenter,
      polygonOptions: const PolygonOptions(
        borderColor: Colors.transparent,
        color: Colors.transparent,
        borderStrokeWidth: 0,
      ),
      animationsOptions: MediaQuery.disableAnimationsOf(context)
          ? const AnimationsOptions(
              zoom: Duration.zero,
              fitBound: Duration.zero,
              centerMarker: Duration.zero,
              spiderfy: Duration.zero,
            )
          : const AnimationsOptions(),
      markers: markers,
      builder: (_, markers) => Builder(
        builder: (clusterContext) {
          // The installed SDK wraps this child in a public GestureDetector. Reuse
          // its action for keyboard activation, preserving zoom and spiderfying.
          final activate = clusterContext
              .findAncestorWidgetOfExactType<GestureDetector>()
              ?.onTap;
          return ReportClusterBadge(
            count: markers.length,
            onActivate: activate,
          );
        },
      ),
    ),
  );
}

class ReportClusterBadge extends StatefulWidget {
  const ReportClusterBadge({
    super.key,
    required this.count,
    required this.onActivate,
  });
  final int count;
  final VoidCallback? onActivate;
  @override
  State<ReportClusterBadge> createState() => _ReportClusterBadgeState();
}

class _ReportClusterBadgeState extends State<ReportClusterBadge> {
  final _focus = FocusNode();
  bool _focused = false;
  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'View ${widget.count} nearby reports',
    button: widget.onActivate != null,
    onTap: widget.onActivate,
    excludeSemantics: true,
    child: FocusableActionDetector(
      focusNode: _focus,
      enabled: widget.onActivate != null,
      onShowFocusHighlight: (value) => setState(() => _focused = value),
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onActivate?.call();
            return null;
          },
        ),
      },
      child: ReportPinFrame(
        color: AppColors.accent,
        selected: _focused,
        layered: true,
        badge: const Icon(Icons.layers_outlined, size: 14, color: Colors.white),
        child: MediaQuery.withClampedTextScaling(
          maxScaleFactor: 1.3,
          child: Text(
            widget.count > 999 ? '999+' : '${widget.count}',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.linkDark
                  : AppColors.accent,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    ),
  );
}
