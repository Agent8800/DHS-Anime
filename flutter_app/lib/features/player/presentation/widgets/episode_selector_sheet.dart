import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';

class EpisodeSelectorSheet extends StatefulWidget {
  final int currentEpisode;
  final int totalEpisodes;
  final Function(int) onEpisodeSelect;

  const EpisodeSelectorSheet({
    super.key,
    required this.currentEpisode,
    required this.totalEpisodes,
    required this.onEpisodeSelect,
  });

  @override
  State<EpisodeSelectorSheet> createState() => _EpisodeSelectorSheetState();
}

class _EpisodeSelectorSheetState extends State<EpisodeSelectorSheet> {
  bool _isAscending = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<int> get _episodes {
    var episodes = List.generate(widget.totalEpisodes, (index) => index + 1);
    if (_searchQuery.isNotEmpty) {
      final query = int.tryParse(_searchQuery);
      if (query != null) {
        episodes = episodes.where((e) => e.toString().contains(_searchQuery)).toList();
      }
    }
    if (!_isAscending) {
      episodes = episodes.reversed.toList();
    }
    return episodes;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textHint.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(
                      'Episodes',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    SizedBox(width: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${widget.totalEpisodes}',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Spacer(),
                    // Sort button
                    IconButton(
                      icon: Icon(
                        _isAscending ? Icons.arrow_upward : Icons.arrow_downward,
                        color: AppTheme.textSecondary,
                      ),
                      onPressed: () {
                        setState(() => _isAscending = !_isAscending);
                      },
                    ),
                    // Grid/List toggle
                    IconButton(
                      icon: Icon(Icons.grid_view, color: AppTheme.textSecondary),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),

              // Search
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Search episode...',
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
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                  },
                ),
              ),

              SizedBox(height: 12),

              // Episode Grid
              Expanded(
                child: GridView.builder(
                  controller: scrollController,
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    childAspectRatio: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: _episodes.length,
                  itemBuilder: (context, index) {
                    final episode = _episodes[index];
                    final isCurrent = episode == widget.currentEpisode;

                    return GestureDetector(
                      onTap: () => widget.onEpisodeSelect(episode),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? AppTheme.primaryColor
                              : AppTheme.cardColor,
                          borderRadius: BorderRadius.circular(10),
                          border: isCurrent
                              ? Border.all(color: AppTheme.primaryColor, width: 2)
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            '$episode',
                            style: TextStyle(
                              color: isCurrent ? Colors.white : AppTheme.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ).animate().slideY(begin: 1, end: 0, duration: Duration(milliseconds: 300));
      },
    );
  }
}
