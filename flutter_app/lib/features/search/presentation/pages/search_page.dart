import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/api_config.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  String _searchQuery = '';
  bool _showFilters = false;

  // Live search state (debounced as-you-type results)
  Timer? _debounce;
  bool _isSearching = false;
  List<Map<String, dynamic>>? _liveResults;

  // Filter state
  String? _selectedGenre;
  String? _selectedStatus;
  String? _selectedYear;
  String _sortBy = 'newest';

  @override
  void initState() {
    super.initState();
    _searchFocus.requestFocus();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    setState(() => _searchQuery = value);

    final query = value.trim();
    if (query.length < 2) {
      setState(() {
        _liveResults = null;
        _isSearching = false;
      });
      return;
    }
    // Live search — wait a beat after the last keystroke, then query.
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _runLiveSearch(query);
    });
  }

  /// Re-run the current query after a filter/sort change.
  void _research() {
    final query = _searchController.text.trim();
    if (query.length < 2) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      _runLiveSearch(query);
    });
  }

  Future<void> _runLiveSearch(String query) async {
    if (!mounted) return;
    setState(() => _isSearching = true);

    try {
      final dio = Dio(BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(milliseconds: 8000),
        receiveTimeout: const Duration(milliseconds: 8000),
      ));
      final response = await dio.get(
        '${ApiConfig.anime}/search',
        queryParameters: {
          'q': query,
          'limit': 24,
          if (_selectedGenre != null) 'genre': _selectedGenre,
          if (_selectedStatus != null) 'status': _selectedStatus,
          if (_selectedYear != null) 'year': _selectedYear,
          'sort': _sortBy,
        },
      );

      final data = response.data['data'];
      final List raw = (data is Map ? data['results'] : data) as List? ?? [];
      if (!mounted || _searchQuery.trim() != query) return;
      setState(() {
        _liveResults = raw
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _isSearching = false;
      });
    } catch (_) {
      // Backend offline (dev/demo) — keep the demo grid, stop the spinner
      if (!mounted) return;
      setState(() {
        _liveResults = null;
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Search Header
            _buildSearchHeader(),

            // Filters
            if (_showFilters) _buildFilters(),

            // Results
            Expanded(
              child: _searchQuery.isEmpty ? _buildRecentSearches() : _buildSearchResults(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _searchFocus.hasFocus
                      ? AppTheme.primaryColor.withOpacity(0.5)
                      : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocus,
                style: TextStyle(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search donghua…',
                  prefixIcon: Icon(Icons.search, color: AppTheme.textHint),
                  suffixIcon: _isSearching
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        )
                      : _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear, color: AppTheme.textHint),
                              onPressed: () {
                                _debounce?.cancel();
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                  _liveResults = null;
                                  _isSearching = false;
                                });
                              },
                            )
                          : null,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
                onChanged: _onQueryChanged,
                onSubmitted: (value) {
                  _debounce?.cancel();
                  final query = value.trim();
                  if (query.length >= 2) _runLiveSearch(query);
                  _saveRecentSearch(query);
                },
              ),
            ),
          ),
          SizedBox(width: 12),
          GestureDetector(
            onTap: () {
              setState(() => _showFilters = !_showFilters);
            },
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _showFilters
                    ? AppTheme.primaryColor.withOpacity(0.2)
                    : AppTheme.cardColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.tune,
                color: _showFilters ? AppTheme.primaryColor : AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: Duration(milliseconds: 300));
  }

  Widget _buildFilters() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Genre Filter
          Text(
            'Genre',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: AppConstants.genres.length,
              itemBuilder: (context, index) {
                final genre = AppConstants.genres[index];
                final isSelected = genre == _selectedGenre;
                return Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(genre),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedGenre = selected ? genre : null;
                      });
                      _research();
                    },
                    selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                    labelStyle: TextStyle(
                      color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                    side: BorderSide.none,
                  ),
                );
              },
            ),
          ),

          SizedBox(height: 12),

          // Status & Sort Row
          Row(
            children: [
              // Status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: AppConstants.animeStatuses.map((status) {
                        final isSelected = status == _selectedStatus;
                        return FilterChip(
                          label: Text(status[0].toUpperCase() + status.substring(1)),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedStatus = selected ? status : null;
                            });
                            _research();
                          },
                          selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                          labelStyle: TextStyle(
                            color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                          side: BorderSide.none,
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              // Sort
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sort',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.cardColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: DropdownButton<String>(
                      value: _sortBy,
                      dropdownColor: AppTheme.surfaceColor,
                      underline: SizedBox(),
                      style: TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                      items: [
                        DropdownMenuItem(value: 'newest', child: Text('Newest')),
                        DropdownMenuItem(value: 'popular', child: Text('Popular')),
                        DropdownMenuItem(value: 'rating', child: Text('Rating')),
                        DropdownMenuItem(value: 'alphabetical', child: Text('A-Z')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _sortBy = value);
                          _research();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: Duration(milliseconds: 300)).slideY(begin: -0.1, end: 0);
  }

  Widget _buildRecentSearches() {
    final recentSearches = ['Battle Through The Heavens', 'Soul Land', 'Martial Master', 'A Record of a Mortal\'s Journey to Immortality'];

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Searches',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: Text('Clear All'),
              ),
            ],
          ),
          SizedBox(height: 12),
          ...recentSearches.map((search) {
            return ListTile(
              contentPadding: EdgeInsets.symmetric(vertical: 4),
              leading: Icon(Icons.history, color: AppTheme.textHint),
              title: Text(
                search,
                style: TextStyle(color: AppTheme.textPrimary),
              ),
              trailing: Icon(Icons.north_west, color: AppTheme.textHint, size: 18),
              onTap: () {
                _searchController.text = search;
                setState(() => _searchQuery = search);
              },
            );
          }),

          SizedBox(height: 24),

          // Trending
          Text(
            'Trending Searches',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: ['Xianxia', 'Cultivation', 'Martial Arts', 'Battle', 'Fantasy', 'Romance'].map((tag) {
              return GestureDetector(
                onTap: () {
                  _searchController.text = tag;
                  setState(() => _searchQuery = tag);
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.textHint.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    ).animate().fadeIn(duration: Duration(milliseconds: 400));
  }

  Widget _buildSearchResults() {
    final results = _liveResults;

    return Column(
      children: [
        // Thin live-search indicator
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: _isSearching ? 2 : 0,
          child: _isSearching
              ? const LinearProgressIndicator(
                  color: AppTheme.primaryColor,
                  backgroundColor: Colors.transparent,
                  minHeight: 2,
                )
              : const SizedBox.shrink(),
        ),
        Expanded(
          child: results != null
              ? (results.isEmpty
                  ? _buildNoResults()
                  : _buildResultGrid(
                      results
                          .map((r) => _SearchResult(
                                id: (r['_id'] ?? r['id'] ?? '').toString(),
                                title: (r['title'] ?? '').toString(),
                                poster: (r['poster'] ?? '').toString(),
                                status: (r['status'] ?? 'Ongoing').toString(),
                              ))
                          .toList(),
                    ))
              : _buildResultGrid(_demoResults),
        ),
      ],
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded,
              size: 64, color: AppTheme.textHint.withOpacity(0.35)),
          const SizedBox(height: 12),
          Text(
            'No results for "$_searchQuery"',
            style: const TextStyle(color: AppTheme.textHint, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildResultGrid(List<_SearchResult> items) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.55,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isOngoing = item.status.toLowerCase() == 'ongoing';
        return GestureDetector(
          onTap: () => context.push('/anime/${item.id}'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: item.poster,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          placeholder: (context, url) => Shimmer.fromColors(
                            baseColor: AppTheme.cardColor,
                            highlightColor: AppTheme.surfaceColor,
                            child: Container(color: AppTheme.cardColor),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: AppTheme.cardColor,
                            child: Icon(Icons.movie, color: AppTheme.textHint),
                          ),
                        ),
                        Positioned(
                          top: 6,
                          left: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: isOngoing
                                  ? AppTheme.primaryColor
                                  : const Color(0xFF3ECF8E),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              item.status.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.7,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item.title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    ).animate().fadeIn(duration: const Duration(milliseconds: 250));
  }

  // Placeholder results shown when the backend is unreachable (dev/demo)
  static final List<_SearchResult> _demoResults = List.generate(
    15,
    (index) => _SearchResult(
      id: 'search_$index',
      title: 'Search Result ${index + 1}',
      poster:
          'https://via.placeholder.com/150x210/22222B/FFFFFF?text=${index + 1}',
      status: index % 3 == 0 ? 'Completed' : 'Ongoing',
    ),
  );

  void _saveRecentSearch(String query) {
    if (query.isNotEmpty) {
      // Save to Hive
    }
  }
}

class _SearchResult {
  final String id;
  final String title;
  final String poster;
  final String status;

  const _SearchResult({
    required this.id,
    required this.title,
    required this.poster,
    required this.status,
  });
}
