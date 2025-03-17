import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:icd/widgets/alar.dart';
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

// Fix 1: Correct the mixin declaration - remove generic parameter
class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode(); // Add this focus node
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
      duration: const Duration(milliseconds: 100),
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

      // Request focus to automatically show keyboard
      _searchFocusNode.requestFocus();

      try {
        Provider.of<Chapters>(context, listen: false).clearSearch();
      } catch (e) {
        print("Error clearing search: $e");
      }
    }); // Fix: Missing closing parenthesis
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
    _searchFocusNode.dispose(); // Dispose the focus node
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
      resizeToAvoidBottomInset: true, // Add this line to handle keyboard
      body: SafeArea(
        child: Column(
          children: [
            // Search Header with ALAR branding
            Padding(
              padding: const EdgeInsets.only(
                  top: 16.0, left: 16, right: 16.0, bottom: 8.0),
              child: Column(
                children: [
                  Container(
                    height: 60,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                          spreadRadius: 1,
                        ),
                      ],
                      border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.1),
                      ),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_rounded),
                          iconSize: 20,
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                        Expanded(
                          child: Container(
                            height: 45,
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.black12
                                  : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TextField(
                              controller: _searchController,
                              focusNode: _searchFocusNode, // Add focus node
                              onChanged: (value) {
                                setState(() {
                                  _query = value;
                                });
                              },
                              onSubmitted: _performSearch,
                              style: TextStyle(fontSize: 16),
                              decoration: InputDecoration(
                                hintText: 'Search ICD-11 codes...',
                                hintStyle: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 16,
                                ),
                                prefixIcon: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  padding: const EdgeInsets.all(12),
                                  child: Icon(
                                    Icons.search_rounded,
                                    color: _query.isNotEmpty
                                        ? Theme.of(context).colorScheme.primary
                                        : Colors.grey.shade400,
                                  ),
                                ),
                                suffixIcon: _query.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear_rounded),
                                        color: Colors.grey.shade600,
                                        onPressed: _clearSearch,
                                      )
                                    : null,
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: 45,
                          width: _query.isEmpty ? 0 : 60,
                          margin: EdgeInsets.only(right: 8),
                          curve: Curves.easeInOut,
                          child: _query.isEmpty
                              ? const SizedBox.shrink()
                              : Material(
                                  color: Theme.of(context).colorScheme.primary,
                                  borderRadius: BorderRadius.circular(12),
                                  elevation: 0,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () => _performSearch(_query),
                                    child: const Center(
                                      child: Icon(
                                        Icons.search_rounded,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),

                  // Added smart suggestions when typing
                  if (_query.isNotEmpty &&
                      !_hasSearched &&
                      !Provider.of<Chapters>(context).isSearching)
                    _buildSmartSuggestions(_query),
                ],
              ),
            ),

            // Make search body scrollable when keyboard appears
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
                    return SingleChildScrollView(
                      // Wrap in ScrollView
                      child: Center(
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
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  // NEW: If typing but haven't searched yet
                  if (_query.isNotEmpty && !_hasSearched) {
                    return SingleChildScrollView(
                      // Wrap in ScrollView
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.search,
                              size: 64,
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.7),
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
                      ),
                    );
                  }

                  // Default state - show search suggestions with scrollability
                  return SingleChildScrollView(
                    // Wrap in ScrollView
                    child: _buildSearchSuggestions(),
                  );
                },
              ),
            ),

            // Conditionally show footer only when keyboard is not visible
            if (MediaQuery.of(context).viewInsets.bottom == 0)
              const AlarFooter(isMinimal: true),
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
          // Replace lottie animation with a cleaner design
          Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Animated rings
                ...List.generate(3, (index) {
                  return Container(
                    width: 180 - index * 40,
                    height: 180 - index * 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.1 + index * 0.1),
                        width: 2,
                      ),
                    ),
                  )
                      .animate(
                        onPlay: (controller) => controller.repeat(),
                      )
                      .scale(
                        begin: const Offset(0.8, 0.8),
                        end: const Offset(1.2, 1.2),
                        duration: Duration(seconds: 2 + index),
                        curve: Curves.easeInOut,
                      )
                      .fadeIn(
                        duration: 800.ms,
                      );
                }),

                // Search icon
                Icon(
                  Icons.search_rounded,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ).animate().fadeIn(duration: 600.ms).scale(
                      begin: const Offset(0.5, 0.5),
                      end: const Offset(1.0, 1.0),
                      duration: 600.ms,
                      curve: Curves.elasticOut,
                    ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // App logo and text with cleaner layout
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                  Theme.of(context)
                      .colorScheme
                      .secondary
                      .withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AlarLogo(size: 30),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Search ICD-11',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    Text(
                      'Start typing to search',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Quick access chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: ['Diabetes', 'Heart Disease', 'COVID-19', 'Mental Health']
                .map((term) => ActionChip(
                      avatar: Icon(Icons.trending_up_rounded,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary),
                      label: Text(term),
                      elevation: 0,
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.1),
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      onPressed: () {
                        _searchController.text = term;
                        _performSearch(term);
                      },
                    ))
                .toList(),
          ),
        ],
      ).animate().fadeIn(duration: 600.ms),
    );
  }

  Widget _buildSmartSuggestions(String query) {
    // These would ideally come from an API or local database
    final suggestions = [
      'Diabetes mellitus',
      'Hypertension',
      'Asthma',
      'Depression',
    ]
        .where((s) => s.toLowerCase().contains(query.toLowerCase()))
        .take(3)
        .toList();

    if (suggestions.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              'Suggestions',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          ...suggestions.map((suggestion) => ListTile(
                dense: true,
                leading: Icon(Icons.history, color: Colors.grey.shade400),
                title: Text(suggestion),
                onTap: () {
                  _searchController.text = suggestion;
                  _performSearch(suggestion);
                },
              )),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms).slideY(begin: -0.1, end: 0);
  }

  Widget _buildSearchResults(SearchResult results) {
    return Column(
      children: [
        // Modern filter bar with animations
        Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.format_list_numbered_rounded,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${results.entities.length} results',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Material(
                color: Colors.transparent,
                child: PopupMenuButton(
                  offset: Offset(0, 10),
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  position: PopupMenuPosition.under,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.tune_rounded,
                          size: 18,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Filter',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'exact',
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle_outline_rounded,
                            size: 18,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text('Exact Match'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'contains',
                      child: Row(
                        children: [
                          Icon(
                            Icons.search_rounded,
                            size: 18,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text('Contains'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'code_only',
                      child: Row(
                        children: [
                          Icon(
                            Icons.tag_rounded,
                            size: 18,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text('Code Only'),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    // Implement advanced search options
                  },
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1, end: 0),

        // Word suggestions with improved styling
        if (results.suggestedWords.isNotEmpty)
          Container(
            height: 48,
            margin: const EdgeInsets.only(top: 8, bottom: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: results.suggestedWords.length,
              itemBuilder: (context, index) {
                final word = results.suggestedWords[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ActionChip(
                    avatar: Icon(
                      Icons.psychology_alt_rounded,
                      size: 18,
                      color: Theme.of(context).colorScheme.primaryContainer,
                    ),
                    label: Text(word),
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .secondaryContainer
                        .withValues(alpha: 0.3),
                    labelStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                    onPressed: () {
                      _searchController.text = word;
                      _performSearch(word);
                    },
                  ),
                )
                    .animate()
                    .fadeIn(
                      delay: Duration(milliseconds: 50 * index),
                      duration: 300.ms,
                    )
                    .slideX(
                      begin: 0.2,
                      end: 0,
                      delay: Duration(milliseconds: 50 * index),
                      duration: 300.ms,
                    );
              },
            ),
          ),

        // Results list with enhanced cards
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
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

  Widget buildSkeletonLoader({
    required double height,
    required double width,
    BorderRadius? borderRadius,
  }) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? BorderRadius.circular(4),
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey.shade800.withValues(alpha: 0.6)
            : Colors.grey.shade300,
      ),
    );
  }

  Widget _buildResultCard(SearchResultEntity entity, int index) {
    // Parse HTML from title
    final document = htmlParser.parse(entity.title);
    final plainTitle = document.body?.text ?? entity.title;

    // Handle chapter color based on chapter code with improved color algorithm
    Color chapterColor = Theme.of(context).colorScheme.primary;
    if (entity.chapterCode.isNotEmpty) {
      final chapterIndex = int.tryParse(entity.chapterCode) ?? 1;
      final hue = ((chapterIndex * 37) % 360).toDouble();
      chapterColor = HSVColor.fromAHSV(1.0, hue, 0.65, 0.85).toColor();
    }

    // Secondary color for gradient
    final secondaryColor =
        HSVColor.fromColor(chapterColor).withSaturation(0.5).toColor();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Colorful accent line for visual hierarchy
          if (entity.isImportant)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 4,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [chapterColor, secondaryColor],
                  ),
                ),
              ),
            ),

          // Main content with improved layout
          Padding(
            padding:
                EdgeInsets.fromLTRB(entity.isImportant ? 20 : 16, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Code and indicators
                Row(
                  children: [
                    // Modern code display
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            chapterColor.withValues(alpha: 0.2),
                            secondaryColor.withValues(alpha: 0.2),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: chapterColor.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        entity.code,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: chapterColor,
                        ),
                      ),
                    ),

                    // Post-coordination indicator
                    if (entity.postcoordinationAvailability > 0)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .tertiaryContainer
                              .withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Icon(
                          Icons.extension_rounded,
                          size: 16,
                          color: Theme.of(context).colorScheme.tertiary,
                        ),
                      ),

                    const Spacer(),

                    // Importance indicator
                    if (entity.isImportant)
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star_rounded,
                              size: 16,
                              color: Colors.amber.shade800,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Important',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.amber.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 12),

                // Title with HTML formatting
                HtmlText(
                  entity.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                ),

                // Show first matching property as subtitle if available
                if (entity.matchingProperties.isNotEmpty &&
                    entity.matchingProperties.first.label != plainTitle)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .background
                          .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.grey.shade200,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: HtmlText(
                            entity.matchingProperties.first.label,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey.shade700,
                                      height: 1.4,
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Entity type indicator with modern badge
                if (entity.entityType == 1)
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.secondary,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.category_rounded,
                          size: 14,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Postcoordination',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Clickable overlay for better touch feedback
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  // Navigate to detail screen (existing code)
                  final chapters =
                      Provider.of<Chapters>(context, listen: false);

                  if (!chapters.hierarchyData.containsKey(entity.id)) {
                    chapters.hierarchyData[entity.id] = {
                      'title': {'@value': plainTitle},
                      'code': entity.code,
                      'classKind': entity.entityType == 1
                          ? 'postcoordination'
                          : 'category',
                    };
                  }

                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ChapterDetailScreen(
                        url: entity.id,
                        chapterTitle: plainTitle,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    )
        .animate() // Remove the onPlay handler that causes repeating animation
        .fadeIn(
          delay: Duration(milliseconds: 50 * index),
          duration: 300.ms,
        )
        .moveY(
          begin: 20,
          end: 0,
          delay: Duration(milliseconds: 50 * index),
          duration: 300.ms,
          curve: Curves.easeOutQuad,
        );
  }
}
