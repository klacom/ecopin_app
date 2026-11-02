import 'dart:io';
import 'package:ecopin_app/shared/widgets/app_dialog.dart';
import 'package:flutter/material.dart';

typedef PhotoReviewChoice = ({String action, String? reason});

/// Shown when the automated photo check cannot confirm (or cannot run on) a
/// photo. Retaking or choosing another photo are the main actions; asking for
/// manual review is a collapsed secondary path that needs an explanation.
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
  bool _requesting = false;

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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return AppDialog(
      stackActions: true,
      title: widget.unavailable
          ? 'Photo check unavailable'
          : 'Unable to verify this photo',
      actions: [
        FilledButton(
          onPressed: () => _choose(widget.unavailable ? 'retry' : 'camera'),
          child: Text(
            widget.unavailable ? 'Retry photo check' : 'Retake photo',
          ),
        ),
        OutlinedButton(
          onPressed: () => _choose('gallery'),
          child: const Text('Choose another photo'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Not now'),
        ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.file(
                  widget.photo,
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                  semanticLabel: 'Photo awaiting review',
                  errorBuilder: (_, _, _) => SizedBox(
                    width: 64,
                    height: 64,
                    child: Center(
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        semanticLabel: 'Photo preview unavailable',
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'This photo is not attached yet.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.unavailable
                ? 'The photo check could not be completed. This does not mean your photo was rejected. Try the check again, or request manual review.'
                : 'The automated check could not confirm that this photo shows the concern you are reporting. AI can miss relevant details. Take another photo focused on the concern, or request manual review.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Semantics(
            button: true,
            expanded: _requesting,
            excludeSemantics: true,
            label: 'Request manual review',
            onTap: () => setState(() => _requesting = !_requesting),
            child: Material(
              color: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color: theme.dividerTheme.color ?? scheme.outlineVariant,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => setState(() => _requesting = !_requesting),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Request manual review',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Icon(
                          _requesting ? Icons.expand_less : Icons.expand_more,
                          color: scheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (_requesting) ...[
            const SizedBox(height: 12),
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
                helperText: 'Required. Say what the photo shows and where.',
                helperMaxLines: 2,
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 4),
            Text(
              'A review request is not an approval and requires a connection when you submit.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _reason.text.trim().isEmpty
                  ? null
                  : () => _choose('review'),
              child: const Text('Send for review'),
            ),
          ],
        ],
      ),
    );
  }
}
