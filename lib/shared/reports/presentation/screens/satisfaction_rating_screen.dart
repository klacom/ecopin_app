import 'package:ecopin_app/core/utils/csat_rating_scale.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecopin_app/core/services/api_service.dart';
import 'package:ecopin_app/shared/widgets/snackbar_helper.dart';
import 'package:ecopin_app/shared/widgets/app_button.dart';
import 'package:ecopin_app/shared/reports/providers/report_provider.dart';
import 'package:ecopin_app/shared/reports/data/models/report_model.dart';

class SatisfactionRatingScreen extends ConsumerStatefulWidget {
  final String reportId;
  final ReportModel? report;

  const SatisfactionRatingScreen({
    super.key,
    required this.reportId,
    this.report,
  });

  @override
  ConsumerState<SatisfactionRatingScreen> createState() =>
      _SatisfactionRatingScreenState();
}

class _SatisfactionRatingScreenState
    extends ConsumerState<SatisfactionRatingScreen> {
  int _selectedRating = 3; // Default to neutral
  bool _isLoading = false;
  bool _isFlagging = false;
  String? _error;
  final _flagReasonController = TextEditingController();

  final List<Map<String, dynamic>> _emojis = [
    for (final entry in CsatRatingScale.entries)
      {'emoji': entry.emoji, 'label': entry.label, 'rating': entry.rating},
  ];

  @override
  void dispose() {
    _flagReasonController.dispose();
    super.dispose();
  }

  Future<void> _submitRating() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.citizenCloseReport(widget.reportId, _selectedRating);

      if (!mounted) return;

      SnackbarHelper.showValidMessage(
        'Thank you for your feedback! Report closed successfully.',
      );
      ref.invalidate(reportDetailsProvider(widget.reportId));
      ref.invalidate(myReportsProvider);
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(
        () => _error =
            'Your feedback could not be saved. Your selection is still here. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _flagIncomplete() async {
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Flag Incomplete Cleanup'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Please explain why the cleanup is incomplete. An officer will inspect the location again.',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText:
                      'e.g., Waste still left on sidewalk, overflowed again...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
              child: const Text('Submit Request'),
            ),
          ],
        );
      },
    );

    if (reason == null || reason.isEmpty) return;

    setState(() {
      _isFlagging = true;
      _error = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.citizenFlagIncomplete(widget.reportId, notes: reason);

      if (!mounted) return;

      SnackbarHelper.showValidMessage(
        'Incomplete cleanup reported. An officer will reinspect it.',
      );
      ref.invalidate(reportDetailsProvider(widget.reportId));
      ref.invalidate(myReportsProvider);
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(
        () =>
            _error = 'Failed to submit reinspection request. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() => _isFlagging = false);
      }
    }
  }

  Widget _buildEmojiRatingSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final rating in _emojis)
              Expanded(
                child: GestureDetector(
                  onTap: _isLoading || _isFlagging
                      ? null
                      : () =>
                            setState(() => _selectedRating = rating['rating']),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _selectedRating == rating['rating']
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                                .withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _selectedRating == rating['rating']
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.outlineVariant
                                  .withValues(alpha: 0.4),
                        width: _selectedRating == rating['rating'] ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          rating['emoji'] as String,
                          style: TextStyle(
                            fontSize: _selectedRating == rating['rating']
                                ? 26
                                : 22,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${rating['rating']}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _selectedRating == rating['rating']
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            _emojis.firstWhere((e) => e['rating'] == _selectedRating)['label']
                as String,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Review & Rate Response'),
      centerTitle: false,
      elevation: 0,
    ),
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    
                    Semantics(
                      header: true,
                      child: Text(
                        'How was the cleanup response?',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Select your satisfaction level below to close the report.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildEmojiRatingSelector(),
                    const SizedBox(height: 16),
                    if (_error != null) ...[
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          _error!,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.error,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    AppButton(
                      text: 'Submit feedback and close report',
                      isLoading: _isLoading,
                      onPressed: _isLoading || _isFlagging
                          ? null
                          : _submitRating,
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                        side: BorderSide(
                          color: Theme.of(
                            context,
                          ).colorScheme.error.withValues(alpha: 0.6),
                          width: 1.2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onPressed: _isLoading || _isFlagging
                          ? null
                          : _flagIncomplete,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.flag_rounded,
                            size: 18,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: _isFlagging
                                ? const SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Flag Incomplete / Reinspect',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
}
