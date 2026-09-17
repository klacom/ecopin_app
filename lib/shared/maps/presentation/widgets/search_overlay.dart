import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:ecopin_app/core/services/location_search_service.dart';
import 'package:ecopin_app/core/services/recent_searches_service.dart';

class SearchOverlay extends StatefulWidget {
  final MapController mapController;

  const SearchOverlay({super.key, required this.mapController});

  @override
  State<SearchOverlay> createState() => _SearchOverlayState();
}

class _SearchOverlayState extends State<SearchOverlay> {
  final TextEditingController _searchController = TextEditingController();
  final LocationSearchService _searchService = LocationSearchService();
  final RecentSearchesService _recentSearchesService = RecentSearchesService();
  final FocusNode _searchFocusNode = FocusNode();

  List<LocationSuggestion> _suggestions = [];
  List<LocationSuggestion> _recentSearches = [];
  bool _showSuggestions = false;
  Timer? _debounce;
  bool _isSearching = false;

  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
    _initSpeech();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize(
      onError: (error) => debugPrint('Speech to text error: $error'),
      onStatus: (status) {
        if (status == 'notListening' || status == 'done') {
          if (mounted) setState(() => _isListening = false);
        }
      },
    );
    if (mounted) setState(() {});
  }

  void _startListening() async {
    if (!_speechEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Speech recognition not available or permission denied.')),
      );
      return;
    }
    
    // Clear search before starting speech
    _searchController.clear();
    
    await _speechToText.listen(
      onResult: (result) {
        _searchController.text = result.recognizedWords;
        _onSearchChanged(result.recognizedWords);
      },
    );
    if (mounted) setState(() => _isListening = true);
  }

  void _stopListening() async {
    await _speechToText.stop();
    if (mounted) setState(() => _isListening = false);
  }

  Future<void> _loadRecentSearches() async {
    final recent = await _recentSearchesService.getRecentSearches();
    if (mounted) {
      setState(() {
        _recentSearches = recent;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    if (query.length >= 2) {
      setState(() {
        _isSearching = true;
        _showSuggestions = true;
      });
    } else {
      setState(() {
        _isSearching = false;
        _showSuggestions = false;
        _suggestions = [];
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 300), () async {
      if (query.length >= 2) {
        final results = await _searchService.searchLocations(query);
        if (mounted) {
          setState(() {
            _suggestions = results;
            _isSearching = false;
          });
        }
      }
    });
  }

  Future<void> _onSuggestionTap(LocationSuggestion suggestion) async {
    await _recentSearchesService.saveSearch(suggestion);
    widget.mapController.move(suggestion.latLng, 16.0);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _onRemoveRecentSearch(LocationSuggestion suggestion) async {
    await _recentSearchesService.removeSearch(suggestion);
    await _loadRecentSearches();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Monochrome definitions
    final Color bgColor = isDark ? Colors.black : Colors.white;
    final Color fgColor = isDark ? Colors.white : Colors.black;
    final Color hintColor = isDark ? Colors.grey[500]! : Colors.grey[600]!;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Unified Pill Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[900] : const Color(0xFFF0F0F0),
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: fgColor, size: 24),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        onChanged: _onSearchChanged,
                        style: TextStyle(color: fgColor, fontSize: 18),
                        decoration: InputDecoration(
                          hintText: 'Search here',
                          hintStyle: TextStyle(color: hintColor, fontSize: 18),
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ),
                    ),
                    if (_isListening)
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: GestureDetector(
                          onTap: _stopListening,
                          child: const Icon(Icons.mic, color: Color(0xFF3300FF), size: 28),
                        ),
                      )
                    else if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: Icon(Icons.highlight_remove, color: fgColor, size: 24),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    else
                      IconButton(
                        icon: Icon(Icons.mic, color: fgColor, size: 24),
                        onPressed: _startListening,
                      ),
                  ],
                ),
              ),
            ),

            // Content Area
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _buildContentArea(isDark, fgColor, hintColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentArea(bool isDark, Color fgColor, Color hintColor) {
    if (_isSearching) {
      return Center(
        key: const ValueKey('loading'),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: fgColor),
            const SizedBox(height: 16),
            Text(
              'Searching...',
              style: TextStyle(color: hintColor, fontSize: 14),
            ),
          ],
        ),
      );
    }

    if (_showSuggestions) {
      if (_suggestions.isEmpty) {
        return Center(
          key: const ValueKey('empty'),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_off, size: 64, color: hintColor),
              const SizedBox(height: 16),
              Text(
                'No locations found',
                style: TextStyle(
                  color: fgColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Try a different search term',
                style: TextStyle(color: hintColor, fontSize: 14),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        key: const ValueKey('results'),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _suggestions.length,
        itemBuilder: (context, index) {
          final suggestion = _suggestions[index];
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.location_pin, color: fgColor),
            title: Text(
              suggestion.displayName,
              style: TextStyle(color: fgColor, fontSize: 15),
            ),
            onTap: () => _onSuggestionTap(suggestion),
          );
        },
      );
    }
    return _buildRecentSearches(isDark, fgColor, hintColor);
  }

  Widget _buildRecentSearches(bool isDark, Color fgColor, Color hintColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            'Recent Searches',
            style: TextStyle(
              color: fgColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _recentSearches.isEmpty
                ? Center(
                    child: Text(
                      'No recent searches',
                      style: TextStyle(color: hintColor, fontSize: 14),
                    ),
                  )
                : ListView.builder(
                    itemCount: _recentSearches.length,
                    itemBuilder: (context, index) {
                      final search = _recentSearches[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.grey[900]!.withValues(alpha: 0.5)
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: ListTile(
                          leading: Icon(
                            Icons.history,
                            color: hintColor,
                            size: 24,
                          ),
                          title: Text(
                            search.displayName,
                            style: TextStyle(
                              color: fgColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: GestureDetector(
                            onTap: () => _onRemoveRecentSearch(search),
                            child: Icon(
                              Icons.close,
                              color: hintColor,
                              size: 20,
                            ),
                          ),
                          onTap: () => _onSuggestionTap(search),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
