import 'package:ecopin_app/shared/widgets/app_button.dart';
import 'package:flutter/material.dart';
import '../controllers/location_search_controller.dart';

class LocationSearchHeader extends StatelessWidget {
  const LocationSearchHeader({
    super.key,
    required this.model,
    required this.text,
    required this.focus,
    required this.selecting,
    required this.openingSettings,
    required this.onSettings,
    this.pageError,
  });
  final LocationSearchController model;
  final TextEditingController text;
  final FocusNode focus;
  final bool selecting, openingSettings;
  final VoidCallback onSettings;
  final String? pageError;
  @override
  Widget build(BuildContext context) {
    final voice = model.voice;
    final busy =
        selecting || voice.busy || voice.listening || model.removing.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ExcludeSemantics(
            child: Text(
              'Place or address',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          const SizedBox(height: 8),
          Semantics(
            label: 'Place or address',
            child: TextField(
              controller: text,
              focusNode: focus,
              enabled: !busy,
              onChanged: model.search,
              onSubmitted: (_) => model.searchNow(),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Barangay, street or landmark',
                suffixIcon: model.query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear place search',
                        onPressed: busy
                            ? null
                            : () {
                                model.search('');
                                focus.requestFocus();
                              },
                        icon: const Icon(Icons.close),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose a place to center the map.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          AppButton(
            text: voice.listening ? 'Stop listening' : 'Use voice search',
            icon: voice.listening ? Icons.stop_circle_outlined : Icons.mic_none,
            variant: ButtonVariant.secondary,
            isLoading: voice.busy,
            onPressed: selecting || voice.busy
                ? null
                : () {
                    focus.unfocus();
                    voice.toggle();
                  },
          ),
          if (voice.listening) ...[
            const SizedBox(height: 12),
            const _SearchNotice('Listening… Speak a place name.'),
          ],
          if (voice.error != null) ...[
            const SizedBox(height: 12),
            _SearchNotice(voice.error!),
          ],
          if (voice.canOpenSettings)
            AppButton(
              text: 'Open device settings',
              variant: ButtonVariant.link,
              isLoading: openingSettings,
              onPressed: openingSettings || selecting ? null : onSettings,
            ),
          if (pageError != null) ...[
            const SizedBox(height: 12),
            _SearchNotice(pageError!),
          ],
          if (selecting) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(
              semanticsLabel: 'Opening place on the map',
            ),
          ],
        ],
      ),
    );
  }
}

class _SearchNotice extends StatelessWidget {
  const _SearchNotice(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
  );
}
