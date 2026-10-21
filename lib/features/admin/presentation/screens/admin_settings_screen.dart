import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ecopin_app/core/constants/app_constants.dart';
import 'package:ecopin_app/features/admin/data/admin_repository.dart';
import 'package:ecopin_app/routes/app_routes.dart';
import 'package:ecopin_app/shared/notifications/presentation/widgets/notification_badge_action.dart';
import 'package:ecopin_app/shared/widgets/app_button.dart';
import 'package:ecopin_app/shared/widgets/app_state_view.dart';

class AdminSettingsScreen extends ConsumerStatefulWidget {
  const AdminSettingsScreen({super.key});
  @override
  ConsumerState<AdminSettingsScreen> createState() =>
      _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends ConsumerState<AdminSettingsScreen> {
  final _form = GlobalKey<FormState>();
  final _minimum = TextEditingController();
  final _timeout = TextEditingController();
  final _videoMaximum = TextEditingController();
  final _scroll = ScrollController();
  Map<String, dynamic>? _saved;
  final _rules = <String, bool>{};
  bool _loading = true, _saving = false, _applying = false;
  String? _error, _notice;
  bool _accountRecovery = false;
  static const labels = {
    'password_require_uppercase': 'Require uppercase letters',
    'password_require_lowercase': 'Require lowercase letters',
    'password_require_numbers': 'Require numbers',
    'password_require_special_chars': 'Require special characters',
  };
  bool get _dirty =>
      _saved != null &&
      (_minimum.text.trim() != _saved!['password_min_length'].toString() ||
          _timeout.text.trim() !=
              _saved!['session_timeout_minutes'].toString() ||
          _videoMaximum.text.trim() !=
              (_saved!['report_video_max_seconds'] ?? 10).toString() ||
          labels.keys.any((key) => _rules[key] != _saved![key]));
  @override
  void initState() {
    super.initState();
    _minimum.addListener(_edited);
    _timeout.addListener(_edited);
    _videoMaximum.addListener(_edited);
    _load();
  }

  @override
  void dispose() {
    _minimum.dispose();
    _timeout.dispose();
    _videoMaximum.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _edited() {
    if (!_applying && mounted) {
      setState(() {
        _error = null;
        _notice = null;
      });
    }
  }

  void _apply(Map<String, dynamic> settings) {
    if (settings['password_min_length'] is! num ||
        settings['session_timeout_minutes'] is! num ||
        labels.keys.any((key) => settings[key] is! bool)) {
      throw const FormatException('Incomplete security settings');
    }
    _applying = true;
    _saved = Map.of(settings);
    _minimum.text = settings['password_min_length'].toString();
    _timeout.text = settings['session_timeout_minutes'].toString();
    _videoMaximum.text = (settings['report_video_max_seconds'] ?? 10)
        .toString();
    for (final key in labels.keys) {
      _rules[key] = settings[key] as bool;
    }
    _applying = false;
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _accountRecovery = false;
    });
    try {
      final settings = await ref.read(adminRepositoryProvider).getSettings();
      if (!mounted) return;
      _apply(settings);
      setState(() {
        _loading = false;
        _notice = null;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = adminErrorMessage(error);
          _accountRecovery = adminRequiresAccountRecovery(error);
        });
      }
    }
  }

  String? _validateNumber(String? text, int minimum, int maximum) {
    final number = int.tryParse(text?.trim() ?? '');
    return number == null || number < minimum || number > maximum
        ? 'Enter a whole number from $minimum to $maximum.'
        : null;
  }

  Future<void> _save() async {
    if (_saving || !_dirty) return;
    FocusManager.instance.primaryFocus?.unfocus();
    if (!_form.currentState!.validate()) {
      if (_validateNumber(_minimum.text, 6, 32) != null) {
        _scroll.animateTo(
          0,
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
      _notice = null;
    });
    var acknowledged = false;
    try {
      final result = await ref.read(adminRepositoryProvider).saveSettings({
        ..._saved!,
        'password_min_length': int.parse(_minimum.text.trim()),
        'session_timeout_minutes': int.parse(_timeout.text.trim()),
        'report_video_max_seconds': int.parse(_videoMaximum.text.trim()),
        ..._rules,
      });
      acknowledged = true;
      if (!mounted) return;
      if (result['settings'] is! Map) {
        throw const FormatException('Missing saved settings');
      }
      _apply(Map<String, dynamic>.from(result['settings'] as Map));
      setState(() {
        _saving = false;
        _notice = 'Changes saved';
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _accountRecovery = adminRequiresAccountRecovery(error);
          _error = acknowledged
              ? 'The server accepted the request, but its saved values could not be confirmed. Reload settings to check the result.'
              : adminErrorMessage(error);
        });
      }
    }
  }

  Future<void> _reloadSavedSettings() async {
    if (_saving) return;
    if (_dirty) {
      final discard = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          scrollable: true,
          title: const Text('Reload settings?'),
          content: const Text(
            'Your unsaved edits will be replaced by the latest saved settings.',
          ),
          actions: [
            TextButton(
              autofocus: true,
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Reload'),
            ),
          ],
        ),
      );
      if (discard != true || !mounted) return;
    }
    await _load();
  }

  Widget _numberField(
    String label,
    String key,
    TextEditingController controller,
    int minimum,
    int maximum,
    String help,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(label, style: Theme.of(context).textTheme.labelMedium),
      const SizedBox(height: 8),
      Semantics(
        label: label,
        child: TextFormField(
          key: Key(key),
          controller: controller,
          enabled: !_saving,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          validator: (value) => _validateNumber(value, minimum, maximum),
          decoration: InputDecoration(
            helperText: help,
            helperMaxLines: 4,
            errorMaxLines: 4,
          ),
        ),
      ),
    ],
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('System settings'),
      toolbarHeight:
          MediaQuery.textScalerOf(
                context,
              ).clamp(maxScaleFactor: 1.3).scale(24) *
              2 +
          16,
      actions: const [NotificationBadgeAction(role: UserRole.admin)],
    ),
    body: _loading
        ? const Center(
            child: CircularProgressIndicator(
              semanticsLabel: 'Loading security settings',
            ),
          )
        : _saved == null
        ? AppStateView(
            title: 'Settings unavailable',
            message: _error ?? 'Settings could not be loaded.',
            icon: Icons.info_outline,
            actionLabel: _accountRecovery ? 'Open Account' : 'Try again',
            onAction: _accountRecovery
                ? () => context.go(AdminAppRoutes.profile)
                : _load,
          )
        : SafeArea(
            child: SingleChildScrollView(
              controller: _scroll,
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Form(
                    key: _form,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Password rules',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Set account password rules. Existing passwords stay unchanged.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 24),
                        _numberField(
                          'Minimum password length',
                          'admin-password-minimum',
                          _minimum,
                          6,
                          32,
                          '6–32 characters',
                        ),
                        const SizedBox(height: 16),
                        for (final entry in labels.entries)
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(entry.value),
                            value: _rules[entry.key]!,
                            onChanged: _saving
                                ? null
                                : (value) => setState(() {
                                    _rules[entry.key] = value;
                                    _error = null;
                                    _notice = null;
                                  }),
                          ),
                        const SizedBox(height: 32),
                        Text(
                          'Session setting',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        _numberField(
                          'Web session timeout (minutes)',
                          'admin-session-timeout',
                          _timeout,
                          5,
                          1440,
                          '5–1440 minutes. Used by the existing web session flow.',
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Report videos',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        _numberField(
                          'Maximum video duration (seconds)',
                          'admin-video-maximum',
                          _videoMaximum,
                          5,
                          10,
                          'Choose 5–10 seconds. Every clip must be at least 5 seconds. Applies to new submissions, including previously recorded clips.',
                        ),
                        const SizedBox(height: 24),
                        if (_dirty) ...[
                          Semantics(
                            liveRegion: true,
                            child: Text(
                              'Unsaved changes',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (_error != null) ...[
                          Semantics(
                            liveRegion: true,
                            child: Text(
                              _error!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (_notice != null) ...[
                          Semantics(liveRegion: true, child: Text(_notice!)),
                          const SizedBox(height: 16),
                        ],
                        if (_accountRecovery)
                          AppButton(
                            text: 'Open Account',
                            onPressed: () => context.go(AdminAppRoutes.profile),
                          )
                        else
                          AppButton(
                            text: 'Save changes',
                            isLoading: _saving,
                            onPressed: _dirty && !_saving ? _save : null,
                          ),
                        if (_dirty) ...[
                          const SizedBox(height: 12),
                          AppButton(
                            text: 'Revert changes',
                            variant: ButtonVariant.secondary,
                            onPressed: _saving
                                ? null
                                : () => setState(() {
                                    _apply(_saved!);
                                    _error = null;
                                    _notice = null;
                                  }),
                          ),
                        ],
                        const SizedBox(height: 24),
                        AppButton(
                          text: 'Reload saved settings',
                          variant: ButtonVariant.link,
                          onPressed: _saving ? null : _reloadSavedSettings,
                        ),
                        const Text(
                          'Fleet and algorithm settings remain in the web administration workspace. Unsaved edits are not kept after you leave this screen.',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
  );
}
