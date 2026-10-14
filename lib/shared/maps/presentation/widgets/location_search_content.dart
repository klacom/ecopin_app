import 'package:ecopin_app/core/services/location_search_service.dart';
import 'package:ecopin_app/shared/widgets/app_button.dart';
import 'package:ecopin_app/shared/widgets/app_state_view.dart';
import 'package:flutter/material.dart';
import '../controllers/location_search_controller.dart';

class LocationSearchContent extends StatelessWidget {
  const LocationSearchContent({
    super.key,
    required this.model,
    required this.disabled,
    required this.onSelect,
  });
  final LocationSearchController model;
  final bool disabled;
  final void Function(LocationSuggestion) onSelect;
  @override
  Widget build(BuildContext context) {
    final searching = model.hasQuery;
    final rows = searching ? model.suggestions : model.recents;
    final error = searching ? model.searchError : model.recentError;
    final loading = searching ? model.isSearching : model.loadingRecents;
    if (loading && rows.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Semantics(
            liveRegion: true,
            child: Column(
              children: [
                const SizedBox(height: 24),
                CircularProgressIndicator(
                  semanticsLabel: searching
                      ? 'Searching places'
                      : 'Loading recent places',
                ),
                const SizedBox(height: 16),
                Text(
                  searching ? 'Searching places…' : 'Loading recent places…',
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (error != null && rows.isEmpty) {
      return SliverToBoxAdapter(
        child: AppStateView(
          title: searching
              ? 'Place search unavailable'
              : 'Recent places unavailable',
          message: error,
          icon: Icons.search_off,
          actionLabel: searching ? 'Retry search' : 'Reload recent places',
          onAction: disabled
              ? null
              : searching
              ? model.searchNow
              : model.loadRecents,
        ),
      );
    }
    if (rows.isEmpty) {
      return SliverToBoxAdapter(
        child: AppStateView(
          title: searching ? 'No places found' : 'Find a place in Pasig',
          message: searching
              ? 'Try a barangay, street, or nearby landmark.'
              : 'Enter at least 2 characters to search. Places you choose will appear in your recent searches.',
          icon: searching ? Icons.location_off_outlined : Icons.travel_explore,
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      sliver: SliverList.list(
        children: [
          Semantics(
            header: true,
            child: Text(
              searching ? 'Search results · ${rows.length}' : 'Recent places',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          const SizedBox(height: 8),
          if (error != null) ...[
            Semantics(
              liveRegion: true,
              child: Text(
                error,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
            AppButton(
              text: 'Reload recent places',
              variant: ButtonVariant.link,
              onPressed: disabled ? null : model.loadRecents,
            ),
          ],
          for (final row in rows)
            LocationSearchPlaceRow(
              suggestion: row,
              recent: !searching,
              busy: model.removing.contains(row),
              onSelect: disabled || model.removing.isNotEmpty
                  ? null
                  : () => onSelect(row),
              onRemove: disabled || model.removing.isNotEmpty
                  ? null
                  : () => model.removeRecent(row),
            ),
          if (searching)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                '© OpenStreetMap contributors',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
        ],
      ),
    );
  }
}

class LocationSearchPlaceRow extends StatelessWidget {
  const LocationSearchPlaceRow({
    super.key,
    required this.suggestion,
    required this.recent,
    required this.busy,
    required this.onSelect,
    this.onRemove,
  });
  final LocationSuggestion suggestion;
  final bool recent, busy;
  final VoidCallback? onSelect, onRemove;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Expanded(
          child: Semantics(
            button: true,
            onTap: onSelect,
            enabled: onSelect != null,
            label: 'Show ${suggestion.displayName} on the map',
            excludeSemantics: true,
            child: InkWell(
              onTap: onSelect,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 8,
                ),
                child: Row(
                  children: [
                    Icon(
                      recent ? Icons.history : Icons.location_on_outlined,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        suggestion.displayName,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (recent)
          IconButton(
            tooltip: 'Remove ${suggestion.displayName} from recent places',
            onPressed: onRemove,
            icon: busy
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      semanticsLabel: 'Removing recent place',
                    ),
                  )
                : const Icon(Icons.close),
          ),
      ],
    ),
  );
}
