import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import '../state/chapters_state.dart';
import '../models/search_result.dart';
import '../widgets/html_text.dart'; // Create this widget for displaying HTML content
import 'chapter_detail_screen.dart';
import 'package:html/parser.dart' as htmlParser;

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  // Add a flag to track if a search has been submitted
  bool _hasSearched = false;
  String _query = '';
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _animationController.forward();

    // Clear search state completely on screen initialization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchController.clear();
      setState(() {
        _query = '';
        _isSearching = false;
        _hasSearched = false;
      });
      try {
        Provider.of<Chapters>(context, listen: false).clearSearch();
      } catch (e) {
        print("Error clearing search: $e");
      }
    });
  }

  @override
  void dispose() {
    // Also clear search state on screen disposal
    try {
      Provider.of<Chapters>(context, listen: false).clearSearch();
    } catch (e) {
      print("Error clearing search on dispose: $e");
    }
    _animationController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    if (query.isEmpty) return;

    setState(() {
      _query = query;
      _isSearching = true;
      _hasSearched = true; // Mark that search was performed
    });

    Provider.of<Chapters>(context, listen: false).searchIcd(query);
  }

  // Update the clear search function
  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _query = '';
      _isSearching = false;
      _hasSearched = false; // Reset search status
    });
    Provider.of<Chapters>(context, listen: false).clearSearch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Search Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  Expanded(
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          setState(() {
                            _query = value;
                          });
                        },
                        onSubmitted: _performSearch,
                        decoration: InputDecoration(
                          hintText: 'Search ICD-11 codes...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _query.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: _clearSearch,
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _performSearch(_query),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                    child: const Text('Search'),
                  ),
                ],
              ),
            ),

            // Search Body
            Expanded(
              child: Consumer<Chapters>(
                builder: (context, chapters, _) {
                  // If searching, show loading
                  if (chapters.isSearching) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // Error handling cases (unchanged)...

                  // If has results, show results
                  if (chapters.searchResults.entities.isNotEmpty) {
                    return _buildSearchResults(chapters.searchResults);
                  }

                  // If search was performed and no results found
                  if (_hasSearched &&
                      _query.isNotEmpty &&
                      !chapters.isSearching) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No results found for "$_query"',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Try using different keywords or check spelling',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                          ),
                        ],
                      ),
                    );
                  }

                  // NEW: If typing but haven't searched yet
                  if (_query.isNotEmpty && !_hasSearched) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.search,
                            size: 64,
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.7),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Press Search to find "$_query"',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.search),
                            label: const Text('Search'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                            ),
                            onPressed: () => _performSearch(_query),
                          ),
                        ],
                      ).animate().fadeIn(duration: 300.ms),
                    );
                  }

                  // Default state - show search suggestions
                  return _buildSearchSuggestions();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchSuggestions() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 200,
            width: 200,
            child: Lottie.asset(
              'assets/search_animation/search_animation.json',
              controller: _animationController,
              onLoaded: (composition) {
                _animationController.duration = composition.duration;
                _animationController.forward();

                // Make it loop
                _animationController.addStatusListener((status) {
                  if (status == AnimationStatus.completed) {
                    _animationController.reset();
                    _animationController.forward();
                  }
                });
              },
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.search,
                  size: 100,
                  color: Colors.grey[400],
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Start typing to search ICD-11',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Search by code, title, or keyword',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ],
      ).animate().fadeIn(duration: 600.ms),
    );
  }

  Widget _buildSearchResults(SearchResult results) {
    return Column(
      children: [
        // Search metadata
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              Text(
                '${results.entities.length} results',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const Spacer(),
              PopupMenuButton(
                child: Row(
                  children: [
                    Text(
                      'Advanced Search',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                    Icon(
                      Icons.arrow_drop_down,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'exact',
                    child: Text('Exact Match'),
                  ),
                  const PopupMenuItem(
                    value: 'contains',
                    child: Text('Contains'),
                  ),
                ],
                onSelected: (value) {
                  // Implement advanced search options
                },
              ),
            ],
          ),
        ),

        // Word suggestions
        if (results.suggestedWords.isNotEmpty)
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: results.suggestedWords.length,
              itemBuilder: (context, index) {
                final word = results.suggestedWords[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ActionChip(
                    label: Text(word),
                    onPressed: () {
                      _searchController.text = word;
                      _performSearch(word);
                    },
                  ),
                );
              },
            ),
          ),

        // Results list
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: results.entities.length,
            itemBuilder: (context, index) {
              final entity = results.entities[index];
              return _buildResultCard(entity, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildResultCard(SearchResultEntity entity, int index) {
    // Parse HTML from title
    final document = htmlParser.parse(entity.title);
    final plainTitle = document.body?.text ?? entity.title;

    // Handle chapter color based on chapter code
    Color chapterColor = Theme.of(context).colorScheme.primary;
    if (entity.chapterCode.isNotEmpty) {
      // Generate a color based on chapter code
      final chapterIndex = int.tryParse(entity.chapterCode) ?? 1;
      // Convert to double explicitly for HSVColor
      final hue = ((chapterIndex * 30) % 360).toDouble();
      chapterColor = HSVColor.fromAHSV(1.0, hue, 0.5, 0.8).toColor();
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: entity.isImportant
            ? BorderSide(color: chapterColor, width: 1.5)
            : BorderSide.none,
      ),
      elevation: entity.isImportant ? 3 : 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Make sure we're passing the correct URL and pre-caching the entity
          final chapters = Provider.of<Chapters>(context, listen: false);

          // Pre-cache basic entity data if not already in cache
          if (!chapters.hierarchyData.containsKey(entity.id)) {
            chapters.hierarchyData[entity.id] = {
              'title': {'@value': plainTitle},
              'code': entity.code,
              'classKind':
                  entity.entityType == 1 ? 'postcoordination' : 'category',
            };
          }

          // Navigate to detail screen
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ChapterDetailScreen(
                url: entity.id,
                chapterTitle: plainTitle,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Code and indicators
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: chapterColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      entity.code,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: chapterColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (entity.postcoordinationAvailability > 0)
                    Icon(
                      Icons.extension,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                  const Spacer(),
                  if (entity.isImportant)
                    Icon(
                      Icons.star,
                      size: 16,
                      color: Colors.amber[700],
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // Title with HTML formatting
              HtmlText(
                entity.title,
                style: Theme.of(context).textTheme.titleMedium,
              ),

              // Show first matching property as subtitle if available
              if (entity.matchingProperties.isNotEmpty &&
                  entity.matchingProperties.first.label != plainTitle)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: HtmlText(
                    entity.matchingProperties.first.label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ),

              // Entity type indicator
              if (entity.entityType == 1)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Chip(
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    label: Text(
                      'Postcoordination',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                  ),
                ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(
          delay: Duration(milliseconds: 50 * index),
          duration: 300.ms,
        )
        .slideY(
          begin: 0.1,
          end: 0,
          delay: Duration(milliseconds: 50 * index),
          duration: 300.ms,
          curve: Curves.easeOutQuad,
        );
  }
}
