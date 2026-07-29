import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:go_router/go_router.dart';
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
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
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
                  hintText: 'Search anime, episodes...',
                  prefixIcon: Icon(Icons.search, color: AppTheme.textHint),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: AppTheme.textHint),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                },
                onSubmitted: (value) {
                  _saveRecentSearch(value);
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
    return GridView.builder(
      padding: EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.55,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
      ),
      itemCount: 15,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () => context.push('/anime/search_$index'),
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
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: 'https://via.placeholder.com/150x210/6C63FF/FFFFFF?text=${index + 1}',
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
                  ),
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Search Result ${index + 1}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 2),
              Row(
                children: [
                  Icon(Icons.star, color: Colors.amber, size: 14),
                  SizedBox(width: 4),
                  Text(
                    '${(7 + index * 0.2).toStringAsFixed(1)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    ).animate().fadeIn(duration: Duration(milliseconds: 400));
  }

  void _saveRecentSearch(String query) {
    if (query.isNotEmpty) {
      // Save to Hive
    }
  }
}
