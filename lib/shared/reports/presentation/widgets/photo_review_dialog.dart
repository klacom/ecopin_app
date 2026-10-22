import 'dart:io';
import 'package:flutter/material.dart';

typedef PhotoReviewChoice = ({String action, String? reason});

class PhotoReviewDialog extends StatefulWidget {
  const PhotoReviewDialog({
    super.key,
    required this.photo,
    required this.unavailable,
  });
  final File photo;
  final bool unavailable;

  @override
  State<PhotoReviewDialog> createState() => _PhotoReviewDialogState();
}

class _PhotoReviewDialogState extends State<PhotoReviewDialog> {
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  void _choose(String action) => Navigator.pop<PhotoReviewChoice>(context, (
    action: action,
    reason: action == 'review' ? _reason.text.trim() : null,
  ));

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      widget.unavailable
          ? 'Photo check unavailable'
          : 'Unable to verify this photo',
    ),
    scrollable: true,
    content: SizedBox(
      width: 280,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.file(
            widget.photo,
            height: 120,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => const Text('Photo preview unavailable'),
          ),
          const SizedBox(height: 16),
          Text(
            widget.unavailable
                ? 'The photo check could not be completed. This does not mean your photo was rejected. Try the check again, or request manual review.'
                : 'The automated check could not confirm whether this photo shows the environmental concern you are reporting. AI can miss relevant details. You can take another photo focused on the concern, or request manual review.',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _reason,
            maxLength: 500,
            minLines: 2,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Explanation for manual review',
              hintText:
                  'Describe the concern and where it appears in this photo.',
              helperText: 'Required only when requesting review.',
              helperMaxLines: 2,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          const Text(
            'The photo is not attached yet. A review request is not an approval and requires a connection when you submit.',
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Not now'),
      ),
      if (widget.unavailable)
        TextButton(
          onPressed: () => _choose('retry'),
          child: const Text('Retry photo check'),
        )
      else
        TextButton(
          onPressed: () => _choose('camera'),
          child: const Text('Retake photo'),
        ),
      TextButton(
        onPressed: () => _choose('gallery'),
        child: const Text('Choose another photo'),
      ),
      TextButton(
        onPressed: _reason.text.trim().isEmpty ? null : () => _choose('review'),
        child: const Text('Request manual review'),
      ),
    ],
  );
}
