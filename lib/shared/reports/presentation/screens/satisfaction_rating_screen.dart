import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecopin_app/core/services/api_service.dart';
import 'package:ecopin_app/shared/widgets/snackbar_helper.dart';
import 'package:ecopin_app/shared/widgets/app_button.dart';
import 'package:ecopin_app/shared/reports/providers/report_provider.dart';

class SatisfactionRatingScreen extends ConsumerStatefulWidget {
  final String reportId;

  const SatisfactionRatingScreen({super.key, required this.reportId});

  @override
  ConsumerState<SatisfactionRatingScreen> createState() =>
      _SatisfactionRatingScreenState();
}

class _SatisfactionRatingScreenState
    extends ConsumerState<SatisfactionRatingScreen> {
  int _selectedRating = 3; // Default to neutral
  bool _isLoading = false;
  String? _error;

  final List<Map<String, dynamic>> _emojis = [
    {'emoji': '😢', 'label': 'Very Dissatisfied', 'rating': 1},
    {'emoji': '😕', 'label': 'Dissatisfied', 'rating': 2},
    {'emoji': '😐', 'label': 'Neutral', 'rating': 3},
    {'emoji': '😊', 'label': 'Satisfied', 'rating': 4},
    {'emoji': '😄', 'label': 'Very Satisfied', 'rating': 5},
  ];

  Future<void> _submitRating() async {
    if (_isLoading) return; // Prevent multiple submissions
    setState(() { _isLoading = true; _error = null; });

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
      setState(() => _error = 'Your feedback could not be saved. Your selection is still here. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Rate the response')),
    body: SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(header: true, child: Text('How was the response to your report?', style: Theme.of(context).textTheme.titleLarge)),
        const SizedBox(height: 16),
        Text('Submitting your feedback closes this report. You will return to its details after your feedback is saved.', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 32),
        for (final rating in _emojis) Padding(padding: const EdgeInsets.only(bottom: 12), child: ChoiceChip(
          label: Text('${rating['emoji']} ${rating['label']}', style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: _selectedRating == rating['rating'] ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurface)),
          selected: _selectedRating == rating['rating'], selectedColor: Theme.of(context).colorScheme.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          onSelected: _isLoading ? null : (selected) { if (selected) setState(() => _selectedRating = rating['rating']); },
        )),
        const SizedBox(height: 24),
        if (_error != null) ...[
          Semantics(liveRegion: true, child: Text(_error!, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.error))),
          const SizedBox(height: 16),
        ],
        AppButton(text: 'Submit feedback and close report', isLoading: _isLoading, onPressed: _isLoading ? null : _submitRating),
      ],
    ))),
  );
}
