import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/theme/app_theme.dart';

class EpisodePage extends ConsumerStatefulWidget {
  final String animeId;

  const EpisodePage({super.key, required this.animeId});

  @override
  ConsumerState<EpisodePage> createState() => _EpisodePageState();
}

class _EpisodePageState extends ConsumerState<EpisodePage>
    with SingleTickerProviderStateMixin {
  late TabController _folderTabController;
  bool _isAscending = true;
  bool _isGridView = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Dummy folders
  final List<Map<String, dynamic>> _folders = [
    {'name': 'Folder 1', 'episodes': List.generate(50, (i) => i + 1)},
    {'name': 'Folder 2', 'episodes': List.generate(50, (i) => i + 51)},
    {'name': 'Folder 3', 'episodes': List.generate(56, (i) => i + 101)},
  ];

  @override
  void initState() {
    super.initState();
    _folderTabController = TabController(length: _folders.length, vsync: this);
  }

  @override
  void dispose() {
    _folderTabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Episodes'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.list : Icons.grid_view),
            onPressed: () => setState(() => _isGridView = !_isGridView),
          ),
          IconButton(
            icon: Icon(_isAscending ? Icons.arrow_upward : Icons.arrow_downward),
            onPressed: () => setState(() => _isAscending = !_isAscending),
          ),
        ],
        bottom: _folders.length > 1
            ? TabBar(
                controller: _folderTabController,
                isScrollable: true,
                indicatorColor: AppTheme.primaryColor,
                labelColor: AppTheme.primaryColor,
                unselectedLabelColor: AppTheme.textSecondary,
                tabs: _folders.map((f) => Tab(text: f['name'])).toList(),
              )
            : null,
      ),
      body: Column(
        children: [
          // Search
          Padding(
            padding: EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search episode...',
                prefixIcon: Icon(Icons.search, color: AppTheme.textHint),
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),

          // Episodes
          Expanded(
            child: TabBarView(
              controller: _folderTabController,
              children: _folders.map((folder) {
                var episodes = folder['episodes'] as List<int>;
                
                if (_searchQuery.isNotEmpty) {
                  final query = int.tryParse(_searchQuery);
                  if (query != null) {
                    episodes = episodes.where((e) => e.toString().contains(_searchQuery)).toList();
                  }
                }

                if (!_isAscending) {
                  episodes = episodes.reversed.toList();
                }

                return _isGridView
                    ? _buildGridView(episodes)
                    : _buildListView(episodes);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListView(List<int> episodes) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16),
      itemCount: episodes.length,
      itemBuilder: (context, index) {
        final ep = episodes[index];
        return Container(
          margin: EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(14),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => context.push('/player/ep_$ep?animeId=${widget.animeId}&episode=$ep'),
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: CachedNetworkImage(
                      imageUrl: 'https://via.placeholder.com/100x60',
                      width: 90,
                      height: 60,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Shimmer.fromColors(
                        baseColor: AppTheme.cardColor,
                        highlightColor: AppTheme.surfaceColor,
                        child: Container(width: 90, height: 60, color: AppTheme.cardColor),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: 90,
                        height: 60,
                        color: AppTheme.surfaceColor,
                        child: Icon(Icons.play_circle_outline, color: AppTheme.textHint),
                      ),
                    ),
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Episode $ep',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Hindi • 1080p • 24 min',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.play_circle_outline, color: AppTheme.primaryColor),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: Icon(Icons.download_outlined, color: AppTheme.textSecondary),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGridView(List<int> episodes) {
    return GridView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: episodes.length,
      itemBuilder: (context, index) {
        final ep = episodes[index];
        return GestureDetector(
          onTap: () => context.push('/player/ep_$ep?animeId=${widget.animeId}&episode=$ep'),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$ep',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Hindi',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppTheme.textHint,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
