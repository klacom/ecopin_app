import 'package:ecopin_app/core/theme/colors.dart';
import 'package:flutter/material.dart';

class ReportMapControls extends StatelessWidget {
  const ReportMapControls({
    super.key,
    required this.onSearch,
    required this.onHeatmap,
    required this.onLocate,
    required this.onInfo,
    required this.heatmap,
    required this.locating,
  });
  final VoidCallback onSearch, onHeatmap, onLocate, onInfo;
  final bool heatmap, locating;
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final foreground = dark ? AppColors.linkDark : AppColors.accent;
    Widget tool(
      String label,
      Widget icon,
      VoidCallback? action, {
      bool? toggled,
    }) => Semantics(
      toggled: toggled,
      child: Material(
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        color: toggled == true
            ? AppColors.primary
            : Theme.of(context).colorScheme.surface,
        child: IconButton(
          tooltip: label,
          onPressed: action,
          color: toggled == true ? Colors.white : foreground,
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          icon: icon,
        ),
      ),
    );
    final divider = SizedBox(
      width: 32,
      child: Divider(
        height: 1,
        color: dark ? AppColors.dividerDark : AppColors.dividerLight,
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        tool('Search places', const Icon(Icons.search), onSearch),
        const SizedBox(height: 12),
        Material(
          elevation: 2,
          shadowColor: AppColors.shadowCard,
          color: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: dark ? AppColors.dividerDark : AppColors.dividerLight,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              tool(
                heatmap ? 'Hide report heatmap' : 'Show report heatmap',
                Icon(heatmap ? Icons.layers : Icons.layers_outlined),
                onHeatmap,
                toggled: heatmap,
              ),
              divider,
              tool(
                locating ? 'Finding your location' : 'Center on my location',
                locating
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          semanticsLabel: 'Finding your location',
                        ),
                      )
                    : const Icon(Icons.my_location),
                locating ? null : onLocate,
              ),
              divider,
              tool(
                'Map legend and credits',
                const Icon(Icons.info_outline),
                onInfo,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
