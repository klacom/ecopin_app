import 'package:flutter/material.dart';

import 'package:ecopin_app/features/field_crew/data/models/crew_urgency_observation.dart';

class CrewUrgencyForm extends StatefulWidget {
  const CrewUrgencyForm({
    super.key,
    required this.onSave,
    required this.canSubmit,
  });
  final Future<void> Function(String result, String conditions) onSave;
  final bool canSubmit;
  @override
  State<CrewUrgencyForm> createState() => _CrewUrgencyFormState();
}

class _CrewUrgencyFormState extends State<CrewUrgencyForm> {
  final _conditions = TextEditingController();
  String? _result, _error;
  bool _saving = false, _saved = false;
  @override
  void dispose() {
    _conditions.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving ||
        !widget.canSubmit ||
        _result == null ||
        _conditions.text.trim().length < 3) {
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSave(_result!, _conditions.text.trim());
      if (mounted) {
        setState(() {
          _saved = true;
          _conditions.clear();
          _result = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Could not save the observation. Your conditions are retained; try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'On-site urgency observation',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const Text(
            'Record conditions you observed on site. This is evidence for an officer, not a false-claim finding or a trust deduction.',
          ),
          const Text(
            'Use the Before/After photos below for supporting evidence. Photos still queued may arrive separately.',
          ),
          if (!widget.canSubmit)
            const Text(
              'A current active task assignment is required to submit an observation.',
            ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            key: ValueKey(_saved),
            initialValue: _result,
            isExpanded: true,
            itemHeight: null,
            decoration: const InputDecoration(labelText: 'Observed urgency'),
            items: crewUrgencyLabels.entries
                .map(
                  (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
                )
                .toList(),
            onChanged: _saving || !widget.canSubmit
                ? null
                : (value) => setState(() {
                    _result = value;
                    _saved = false;
                  }),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _conditions,
            enabled: !_saving && widget.canSubmit,
            maxLength: 1500,
            minLines: 3,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: 'Observed conditions / contrary evidence (required)',
            ),
            onChanged: (_) => setState(() => _saved = false),
          ),
          if (_error != null) Text(_error!, semanticsLabel: _error),
          if (_saved)
            const Text(
              'Saved on this device for sync. Officer review starts only after server acceptance.',
            ),
          FilledButton(
            onPressed:
                _saving ||
                    !widget.canSubmit ||
                    _result == null ||
                    _conditions.text.trim().length < 3
                ? null
                : _save,
            child: Text(
              _saving ? 'Saving…' : 'Save observation for officer review',
            ),
          ),
        ],
      ),
    ),
  );
}
