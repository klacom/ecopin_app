import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecopin_app/core/services/api_service.dart';
import 'package:ecopin_app/shared/widgets/snackbar_helper.dart';

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

  final List<Map<String, dynamic>> _emojis = [
    {'emoji': '😢', 'label': 'Very Dissatisfied', 'rating': 1},
    {'emoji': '😕', 'label': 'Dissatisfied', 'rating': 2},
    {'emoji': '😐', 'label': 'Neutral', 'rating': 3},
    {'emoji': '😊', 'label': 'Satisfied', 'rating': 4},
    {'emoji': '😄', 'label': 'Very Satisfied', 'rating': 5},
  ];

  Future<void> _submitRating() async {
    if (_isLoading) return; // Prevent multiple submissions
    setState(() => _isLoading = true);

    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.citizenCloseReport(widget.reportId, _selectedRating);

      if (!mounted) return;

      SnackbarHelper.showValidMessage(
        'Thank you for your feedback! Report closed successfully.',
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;
      SnackbarHelper.showError('Failed to close report. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rate the Service')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'How was the response to your report?',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              // Emoji selection
              Expanded(
                child: Center(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Calculate appropriate emoji size based on screen width
                      final emojiSize = constraints.maxWidth < 400
                          ? 36.0
                          : 48.0;
                      final labelFontSize = constraints.maxWidth < 400
                          ? 10.0
                          : 12.0;

                      return Wrap(
                        spacing: 16,
                        runSpacing: 24,
                        alignment: WrapAlignment.center,
                        children: _emojis.map((emojiData) {
                          final isSelected =
                              _selectedRating == emojiData['rating'];
                          return GestureDetector(
                            onTap: _isLoading
                                ? null
                                : () {
                                    setState(() {
                                      _selectedRating = emojiData['rating'];
                                    });
                                  },
                            child: Column(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(emojiSize * 0.25),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.blue.withOpacity(0.1)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? Colors.blue
                                          : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                  child: Text(
                                    emojiData['emoji'],
                                    style: TextStyle(fontSize: emojiSize),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  emojiData['label'],
                                  style: TextStyle(
                                    fontSize: labelFontSize,
                                    color: isSelected
                                        ? Colors.blue
                                        : Colors.grey,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),
              ),
              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitRating,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.blue,
                    disabledBackgroundColor: Colors.grey.shade400,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Submit Feedback',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
