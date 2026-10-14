import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:ecopin_app/features/admin/data/admin_page.dart';
import 'package:ecopin_app/shared/widgets/app_button.dart';

String adminDate(dynamic value) {
  final date = value is String ? DateTime.tryParse(value)?.toLocal() : null;
  if (date == null) return 'Unavailable';
  final offset = date.timeZoneOffset.inMinutes;
  final hours = (offset.abs() ~/ 60).toString().padLeft(2, '0');
  final minutes = (offset.abs() % 60).toString().padLeft(2, '0');
  return '${DateFormat('d MMM yyyy, h:mm a').format(date)} UTC${offset < 0 ? '−' : '+'}$hours:$minutes';
}

String adminLabel(dynamic value) {
  if (value is! String || value.isEmpty) return 'Unavailable';
  final text = value.replaceAll('_', ' ');
  return '${text[0].toUpperCase()}${text.substring(1)}';
}

class AdminPageNavigation extends StatelessWidget {
  const AdminPageNavigation({
    super.key,
    required this.data,
    required this.onPage,
    this.busy = false,
    this.visibleCount,
  });
  final AdminPage data;
  final ValueChanged<int> onPage;
  final bool busy;
  final int? visibleCount;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Semantics(
        liveRegion: true,
        child: Text(
          data.total == null
              ? '${data.records.length} records returned. Total unavailable.'
              : '${visibleCount ?? data.records.length} visible of ${data.records.length} loaded · ${data.total} matching records',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
      const SizedBox(height: 12),
      if (data.totalPages == null)
        const Text('Pagination is unavailable for this response.')
      else if (data.totalPages! > 0) ...[
        Text('Page ${data.page} of ${data.totalPages}'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: AppButton(
                text: 'Previous page',
                variant: ButtonVariant.secondary,
                onPressed: busy || data.page <= 1
                    ? null
                    : () => onPage(data.page - 1),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppButton(
                text: 'Next page',
                variant: ButtonVariant.secondary,
                onPressed: busy || data.page >= data.totalPages!
                    ? null
                    : () => onPage(data.page + 1),
              ),
            ),
          ],
        ),
      ],
    ],
  );
}

class AdminSelect extends StatefulWidget {
  const AdminSelect({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });
  final String label, value;
  final Map<String, String> options;
  final ValueChanged<String>? onChanged;
  @override
  State<AdminSelect> createState() => _AdminSelectState();
}

class _AdminSelectState extends State<AdminSelect> {
  final _focus = FocusNode();
  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(widget.label, style: Theme.of(context).textTheme.labelMedium),
      const SizedBox(height: 8),
      Semantics(
        label: widget.label,
        child: DropdownButtonFormField<String>(
          key: ValueKey('${widget.label}:${widget.value}'),
          initialValue: widget.value,
          focusNode: _focus,
          isExpanded: true,
          itemHeight: null,
          menuMaxHeight: 360,
          selectedItemBuilder: (context) => widget.options.entries
              .map(
                (entry) => Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    entry.key == 'admin' ? 'Admin' : entry.value,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          items: widget.options.entries
              .map(
                (entry) => DropdownMenuItem(
                  value: entry.key,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(entry.value),
                  ),
                ),
              )
              .toList(),
          onChanged: widget.onChanged == null
              ? null
              : (value) {
                  if (value == null) return;
                  widget.onChanged!(value);
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted && widget.onChanged != null) {
                      _focus.requestFocus();
                    }
                  });
                },
        ),
      ),
    ],
  );
}

class AdminDetailField extends StatelessWidget {
  const AdminDetailField({
    super.key,
    required this.label,
    required this.value,
    this.technical = false,
  });
  final String label, value;
  final bool technical;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
            if (value != 'Unavailable')
              IconButton(
                tooltip: 'Copy $label',
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                icon: const Icon(Icons.copy_outlined, size: 20),
                onPressed: () async {
                  try {
                    await Clipboard.setData(ClipboardData(text: value));
                    if (context.mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('$label copied')));
                    }
                  } catch (_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'The value could not be copied. Select it and try copying again.',
                          ),
                        ),
                      );
                    }
                  }
                },
              ),
          ],
        ),
        SelectableText(
          value,
          style: technical
              ? Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontFamily: 'monospace',
                  fontFamilyFallback: const [
                    'Roboto Mono',
                    'Menlo',
                    'Consolas',
                    'Outfit',
                  ],
                )
              : Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    ),
  );
}

Future<bool> confirmAdminAction(
  BuildContext context, {
  required String title,
  required String message,
  required String action,
  bool destructive = false,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        scrollable: true,
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            autofocus: true,
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: destructive
                ? TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  )
                : null,
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(action),
          ),
        ],
      ),
    ) ??
    false;
