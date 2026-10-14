import 'package:ecopin_app/core/services/location_search_service.dart';
import 'package:ecopin_app/core/services/recent_searches_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:permission_handler/permission_handler.dart';
import '../controllers/location_search_controller.dart';
import '../controllers/location_voice_controller.dart';
import 'location_search_content.dart';
import 'location_search_header.dart';

class SearchOverlay extends StatefulWidget {
  const SearchOverlay({
    super.key,
    required this.mapController,
    this.searchService,
    this.recentSearches,
    this.voiceBackend,
    this.openSettings,
  });
  final MapController mapController;
  final LocationSearchService? searchService;
  final RecentSearchesService? recentSearches;
  final LocationVoiceBackend? voiceBackend;
  final Future<bool> Function()? openSettings;
  @override
  State<SearchOverlay> createState() => _SearchOverlayState();
}

class _SearchOverlayState extends State<SearchOverlay> {
  final _text = TextEditingController();
  final _focus = FocusNode();
  late final LocationSearchController _model;
  bool _selecting = false, _openingSettings = false;
  String? _pageError;
  @override
  void initState() {
    super.initState();
    _model = LocationSearchController(
      searchService: widget.searchService,
      recentSearches: widget.recentSearches,
      voiceBackend: widget.voiceBackend,
    );
    _model.addListener(_syncQuery);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  void _syncQuery() {
    if (_text.text != _model.query) {
      _text.value = TextEditingValue(
        text: _model.query,
        selection: TextSelection.collapsed(offset: _model.query.length),
      );
    }
  }

  @override
  void dispose() {
    _model.removeListener(_syncQuery);
    _model.dispose();
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _select(LocationSuggestion suggestion) async {
    if (_selecting ||
        _model.voice.busy ||
        _model.voice.listening ||
        _model.removing.isNotEmpty) {
      return;
    }
    _focus.unfocus();
    _model.voice.ignoreResults();
    setState(() {
      _selecting = true;
      _pageError = null;
    });
    try {
      widget.mapController.move(suggestion.latLng, 16);
      final saved = await _model.remember(suggestion);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      if (!saved && messenger.mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: const Text(
              'Map opened. This place could not be saved to recent searches.',
            ),
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: 'Dismiss',
              onPressed: messenger.hideCurrentSnackBar,
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _pageError =
              'The map is unavailable. Close search and try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _selecting = false);
    }
  }

  Future<void> _settings() async {
    if (_openingSettings) return;
    setState(() {
      _openingSettings = true;
      _pageError = null;
    });
    try {
      if (!await (widget.openSettings ?? openAppSettings)() && mounted) {
        setState(
          () => _pageError =
              'Device settings could not open. You can still type a place.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _pageError =
              'Device settings could not open. You can still type a place.',
        );
      }
    } finally {
      if (mounted) setState(() => _openingSettings = false);
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _model,
    builder: (context, _) {
      final voice = _model.voice;
      final busy =
          _selecting ||
          voice.busy ||
          voice.listening ||
          _model.removing.isNotEmpty;
      return PopScope(
        canPop: !_selecting,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Search places'),
            leading: IconButton(
              tooltip: 'Close place search',
              icon: const Icon(Icons.arrow_back),
              onPressed: _selecting ? null : () => Navigator.of(context).pop(),
            ),
          ),
          body: SafeArea(
            top: false,
            child: CustomScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                SliverToBoxAdapter(
                  child: LocationSearchHeader(
                    model: _model,
                    text: _text,
                    focus: _focus,
                    selecting: _selecting,
                    openingSettings: _openingSettings,
                    onSettings: _settings,
                    pageError: _pageError,
                  ),
                ),
                LocationSearchContent(
                  model: _model,
                  disabled: busy,
                  onSelect: _select,
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
