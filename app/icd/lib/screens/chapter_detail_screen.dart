import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:icd/screens/clipboard.dart';
import 'package:icd/widgets/alar.dart';
import 'package:icd/widgets/chapter_detail_screen/show_code_range.dart';
import 'package:icd/widgets/chapter_detail_screen/show_code_section.dart';
import 'package:icd/widgets/chapter_detail_screen/subcategories_section.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../state/chapters_state.dart';
import 'package:flutter/services.dart';

class ChapterDetailScreen extends StatefulWidget {
  final String url;
  final String chapterTitle;

  const ChapterDetailScreen({
    super.key,
    required this.url,
    required this.chapterTitle,
  });

  @override
  State<ChapterDetailScreen> createState() => _ChapterDetailScreenState();
}

class _ChapterDetailScreenState extends State<ChapterDetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Add these to your class state variables
  List<String> _selectedPostCoordinationCodes = [];
  Map<String, String> _entityLabels =
      {}; // To store entity ID -> label mappings

  // Add these properties to your state class
  Map<String, Map<String, dynamic>> _entityCache = {}; // Cache entity data
  Map<String, bool> _loadingEntities = {}; // Track loading status
  bool _isLoadingAnyEntity = false; // Overall loading flag

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Clear caches
    _selectedPostCoordinationCodes = [];
    _entityLabels = {};
    _entityCache = {};
    _loadingEntities = {};

    // Start animations after frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.forward();
      context.read<Chapters>().loadScreenData(widget.url);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Add this helper method to render definition content based on format
  Widget _buildDefinitionWidget(BuildContext context, String? definitionText) {
    if (definitionText == null) {
      return Text('No definition available');
    }

    // Check if the definition is in markdown format
    if (definitionText.trim().startsWith('!markdown')) {
      // Remove the !markdown marker and render as markdown
      final markdownContent =
          definitionText.replaceFirst('!markdown', '').trim();
      return MarkdownBody(
        data: markdownContent,
        styleSheet: MarkdownStyleSheet(
          p: Theme.of(context).textTheme.bodyMedium,
          h1: Theme.of(context).textTheme.headlineSmall,
          h2: Theme.of(context).textTheme.titleLarge,
          h3: Theme.of(context).textTheme.titleMedium,
          strong: const TextStyle(fontWeight: FontWeight.bold),
          em: const TextStyle(fontStyle: FontStyle.italic),
          blockquote: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade700,
                fontStyle: FontStyle.italic,
              ),
          code: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                backgroundColor: Colors.grey.shade200,
              ),
        ),
      );
    }

    // Regular text definition
    return Text(
      definitionText,
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }

  // Add this helper method to extract the axis display name
  String _getAxisDisplayName(String axisName) {
    // Extract the last part after the last slash
    final parts = axisName.split('/');
    String name = parts.last;

    // Convert camelCase to Title Case with spaces
    name = name.replaceAllMapped(RegExp(r'([a-z])([A-Z])'),
        (match) => '${match.group(1)} ${match.group(2)}');

    // Capitalize first letter
    return name[0].toUpperCase() + name.substring(1);
  }

  // Add this helper method to extract the entity code from a URL
  String _extractEntityCode(String entityUrl) {
    final parts = entityUrl.split('/');
    return parts.last.contains('unspecified') ? 'unspecified' : parts.last;
  }

  // Add this new widget to display post-coordination scales
  Widget _buildPostCoordinationScales(
      BuildContext context, Map<String, dynamic>? data) {
    if (data == null ||
        data['classKind'] != 'category' ||
        data['postcoordinationScale'] == null) {
      return const SizedBox.shrink();
    }

    final scales =
        List<Map<String, dynamic>>.from(data['postcoordinationScale']);
    if (scales.isEmpty) return const SizedBox.shrink();

    final baseCode = data['code'] ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),

        // Composite code display (when codes are selected)
        if (_selectedPostCoordinationCodes.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .primaryContainer
                  .withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Combined Code:',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _buildCompositeCode(baseCode),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                            ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.copy, size: 20),
                      onPressed: () {
                        context.saveToClipboardHistory(
                            code: _buildCompositeCode(baseCode),
                            description: _selectedPostCoordinationCodes
                                .map((url) => _entityLabels[url])
                                .join(' '));
                        Clipboard.setData(ClipboardData(
                                text: _buildCompositeCode(baseCode)))
                            .then((_) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content:
                                  Text('Combined code copied to clipboard'),
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        });
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.clear_all, size: 20),
                      onPressed: () {
                        setState(() {
                          _selectedPostCoordinationCodes.clear();
                        });
                      },
                    ),
                  ],
                ),

                // Display selected codes with remove option
                if (_selectedPostCoordinationCodes.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _selectedPostCoordinationCodes.map((url) {
                      final entityData = _entityCache[url];
                      final code = entityData?['code'] ?? '...';
                      final title =
                          entityData?['title']?['@value'] ?? 'Loading...';

                      return Chip(
                        avatar: CircleAvatar(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          child: Text(
                            code.length > 2 ? code.substring(0, 2) : code,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        label: Text(
                          title,
                          style: TextStyle(fontSize: 12),
                        ),
                        deleteIcon: Icon(Icons.close, size: 16),
                        onDeleted: () {
                          setState(() {
                            _selectedPostCoordinationCodes.remove(url);
                          });
                        },
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),

        const SizedBox(height: 24),

        // Post-coordination section header
        Row(
          children: [
            Text(
              'Post-coordination',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(width: 8),
            Text(
              '?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Each scale section
        ...scales.asMap().entries.map((entry) {
          final index = entry.key;
          final scale = entry.value;
          final axisNameUrl = scale['axisName'] as String;
          final axisName = _getAxisDisplayName(axisNameUrl);
          final required = scale['requiredPostcoordination'] == 'true';
          final allowMultiple = scale['allowMultipleValues'] == 'AllowAlways';
          final entities = List<String>.from(scale['scaleEntity'] ?? []);

          // Create description based on required and allowMultiple
          String description = "";
          if (required) {
            description = "(required)";
          } else {
            description = "(use additional code, if desired)";
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Axis name and description
              Text(
                "$axisName $description",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),

              if (entities.length > 8) ...[
                // Add search field for large entity lists
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: TextField(
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'search in axis: $axisName',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Colors.grey.shade300,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    // Implement filtering logic here
                  ),
                ),
                // For large lists, add a "Load all" button
                ElevatedButton.icon(
                  onPressed: () {
                    // Set loading state for all entities
                    setState(() {
                      for (final url in entities) {
                        if (!_entityCache.containsKey(url)) {
                          _loadingEntities[url] = true;
                        }
                      }
                      _isLoadingAnyEntity = true;
                    });

                    // Load all entities for this axis
                    _loadEntitiesForScale(entities);
                  },
                  icon: const Icon(Icons.download, size: 16),
                  label: Text("Load all ${entities.length} options"),
                  style: ElevatedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              const SizedBox(height: 8),

              // Entity list with proper data display
              ...entities.map((entityUrl) {
                // Start loading if not already loaded
                if (!_entityCache.containsKey(entityUrl) &&
                    _loadingEntities[entityUrl] != true) {
                  // Schedule loading after build
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _loadEntityData(entityUrl);
                  });
                }

                final isLoading = _loadingEntities[entityUrl] == true;
                final entityData = _entityCache[entityUrl];

                final entityCode = entityData?['code'] ?? '...';
                final entityTitle = entityData?['title']?['@value'] ??
                    (isLoading ? 'Loading...' : 'Unknown');

                final isSelected =
                    _selectedPostCoordinationCodes.contains(entityUrl);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: InkWell(
                    onTap: isLoading
                        ? null
                        : () {
                            setState(() {
                              if (isSelected) {
                                _selectedPostCoordinationCodes
                                    .remove(entityUrl);
                              } else {
                                _selectedPostCoordinationCodes.add(entityUrl);
                              }
                            });
                          },
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 24,
                            child: isLoading
                                ? SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2))
                                : isSelected
                                    ? Icon(
                                        Icons.check_box,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        size: 20,
                                      )
                                    : Icon(
                                        Icons.check_box_outline_blank,
                                        color: Colors.grey,
                                        size: 20,
                                      ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: isLoading
                                ? Container(
                                    height: 16,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(4),
                                      color: Colors.grey.shade200,
                                    ),
                                  )
                                : RichText(
                                    text: TextSpan(
                                      children: [
                                        TextSpan(
                                          text: entityCode,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                          ),
                                        ),
                                        TextSpan(
                                          text: " $entityTitle",
                                          style: TextStyle(
                                            color:
                                                Theme.of(context).brightness ==
                                                        Brightness.dark
                                                    ? Colors.white
                                                    : Colors.black,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),

              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
            ],
          );
        }).toList(),
      ],
    );
  }

  // Helper method to build composite code string
  String _buildCompositeCode(String baseCode) {
    if (_selectedPostCoordinationCodes.isEmpty) return baseCode;

    String result = baseCode;

    // Sort selection by axis
    final selectedUrls = List<String>.from(_selectedPostCoordinationCodes);

    // Add first code with &
    if (selectedUrls.isNotEmpty) {
      final firstUrl = selectedUrls[0];
      final firstCode =
          _entityCache[firstUrl]?['code'] ?? firstUrl.split('/').last;
      result += "&$firstCode";
    }

    // Add subsequent codes with /
    if (selectedUrls.length > 1) {
      for (int i = 1; i < selectedUrls.length; i++) {
        final url = selectedUrls[i];
        final code = _entityCache[url]?['code'] ?? url.split('/').last;
        result += "/$code";
      }
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Expanded(
              child: Text(
                widget.chapterTitle,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        elevation: 0,
        scrolledUnderElevation: 4,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<Chapters>(
              builder: (context, chapters, _) {
                final data = chapters.getDataForUrl(widget.url);
                final isCategory = data?['classKind'] == 'category';
                final isChapter = data?['classKind'] == 'chapter';
                final isBlock = data?['classKind'] == 'block';

                return Skeletonizer(
                  enabled: chapters.isLoading,
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Display code prominently if it's a category or chapter
                          if ((isCategory || isChapter) &&
                              data?['code'] != null)
                            ShowCodeSection(
                              isChapter: isChapter,
                              isCategory: isCategory,
                              data: data,
                              controller: _controller,
                            )
                          // For the block code card, add a copy button
                          else if (isBlock && data?['codeRange'] != null)
                            ShowCodeRange(
                              data: data,
                              controller: _controller,
                            ),

                          const SizedBox(height: 24),

                          // Title with animated fade-in
                          Text(
                            data?['title']?['@value'] ?? 'Loading title...',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ).animate().fadeIn(duration: 600.ms).moveX(
                              begin: -10, end: 0, curve: Curves.easeOutQuad),

                          const SizedBox(height: 24),

                          // Definition section with staggered animation
                          if (data?['definition']?['@value'] != null) ...[
                            Text(
                              isBlock ? 'Description' : 'Definition',
                              style: Theme.of(context).textTheme.titleLarge,
                            ).animate().fadeIn(delay: 300.ms).moveY(
                                begin: 10, end: 0, curve: Curves.easeOutQuad),
                            const SizedBox(height: 8),
                            Card(
                              elevation: 2,
                              shadowColor: Colors.black.withValues(alpha: 0.1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: _buildDefinitionWidget(
                                  context,
                                  data?['definition']?['@value'],
                                ),
                              ),
                            )
                                .animate()
                                .fadeIn(delay: 400.ms, duration: 800.ms)
                                .moveY(
                                    begin: 20,
                                    end: 0,
                                    curve: Curves.easeOutQuad),
                            const SizedBox(height: 24),
                          ],

                          // Subcategories section - use different label based on class kind
                          if (data?['child'] != null &&
                              data?['child'] is List) ...[
                            SubcategoriesSection(
                              data: data,
                              isChapter: isChapter,
                              isBlock: isBlock,
                              chapters: chapters,
                            )
                          ],

                          // Exclusions section - for any class kind with exclusions
                          if (data?['exclusion'] != null &&
                              data!['exclusion'] is List &&
                              data['exclusion'].isNotEmpty) ...[
                            Text(
                              'Exclusions',
                              style: Theme.of(context).textTheme.titleLarge,
                            ).animate().fadeIn(delay: 550.ms),
                            const SizedBox(height: 8),
                            Card(
                              elevation: 2,
                              shadowColor: Colors.black.withValues(alpha: 0.1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: List.generate(
                                    data['exclusion'].length,
                                    (index) {
                                      final exclusion =
                                          data['exclusion'][index];
                                      final label = exclusion['label']
                                              ?['@value'] ??
                                          'No label';
                                      final reference =
                                          exclusion['linearizationReference'];

                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 12.0),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Icon(
                                              Icons.remove_circle_outline,
                                              size: 18,
                                              color: Colors.red,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: GestureDetector(
                                                onTap: reference != null
                                                    ? () {
                                                        Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (context) =>
                                                                ChapterDetailScreen(
                                                              url: reference,
                                                              chapterTitle:
                                                                  label,
                                                            ),
                                                          ),
                                                        );
                                                      }
                                                    : null,
                                                child: Text(
                                                  label,
                                                  style: reference != null
                                                      ? TextStyle(
                                                          color: Colors
                                                              .blue.shade700,
                                                          decoration:
                                                              TextDecoration
                                                                  .underline,
                                                        )
                                                      : Theme.of(context)
                                                          .textTheme
                                                          .bodyMedium,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ).animate().fadeIn(delay: 500.ms),
                            const SizedBox(height: 24),
                          ],

                          // Coded Elsewhere (foundationChildElsewhere) - for any class kind with this field
                          if (data?['foundationChildElsewhere'] != null &&
                              data!['foundationChildElsewhere'] is List &&
                              data['foundationChildElsewhere'].isNotEmpty) ...[
                            Text(
                              'Coded Elsewhere',
                              style: Theme.of(context).textTheme.titleLarge,
                            ).animate().fadeIn(delay: 650.ms),
                            const SizedBox(height: 8),
                            Card(
                              elevation: 2,
                              shadowColor: Colors.black.withValues(alpha: 0.1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: List.generate(
                                    data['foundationChildElsewhere'].length,
                                    (index) {
                                      final item =
                                          data['foundationChildElsewhere']
                                              [index];
                                      final label = item['label']?['@value'] ??
                                          'No label';
                                      final reference =
                                          item['linearizationReference'];

                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 12.0),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Icon(
                                              Icons.link,
                                              size: 18,
                                              color: Colors.blue,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: GestureDetector(
                                                onTap: reference != null
                                                    ? () {
                                                        Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (context) =>
                                                                ChapterDetailScreen(
                                                              url: reference,
                                                              chapterTitle:
                                                                  label,
                                                            ),
                                                          ),
                                                        );
                                                      }
                                                    : null,
                                                child: Text(
                                                  label,
                                                  style: TextStyle(
                                                    color: Colors.blue.shade700,
                                                    decoration: TextDecoration
                                                        .underline,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ).animate().fadeIn(delay: 600.ms),
                            const SizedBox(height: 24),
                          ],

                          // Related categories in perinatal chapter
                          if (data?['relatedEntitiesInPerinatalChapter'] != null &&
                              data!['relatedEntitiesInPerinatalChapter']
                                  is List &&
                              data['relatedEntitiesInPerinatalChapter']
                                  .isNotEmpty) ...[
                            Text(
                              'Related Categories in Perinatal Chapter',
                              style: Theme.of(context).textTheme.titleLarge,
                            ).animate().fadeIn(delay: 750.ms),
                            const SizedBox(height: 8),
                            Card(
                              elevation: 2,
                              shadowColor: Colors.black.withValues(alpha: 0.1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: FutureBuilder(
                                future: _loadPerinatalRelatedItems(context,
                                    data['relatedEntitiesInPerinatalChapter']),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Padding(
                                      padding: EdgeInsets.all(16.0),
                                      child: Center(
                                          child: CircularProgressIndicator()),
                                    );
                                  }

                                  if (snapshot.hasError ||
                                      snapshot.data == null) {
                                    return Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Text(
                                          'Error loading related items: ${snapshot.error}'),
                                    );
                                  }

                                  final relatedItems = snapshot.data
                                      as List<Map<String, dynamic>>;

                                  return Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: relatedItems
                                          .map((item) => Padding(
                                                padding: const EdgeInsets.only(
                                                    bottom: 12.0),
                                                child: Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    const Icon(Icons.add_link,
                                                        size: 18,
                                                        color: Colors.purple),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: GestureDetector(
                                                        onTap: () {
                                                          if (item['url'] !=
                                                              null) {
                                                            // Navigate to the referenced item
                                                            Navigator.push(
                                                              context,
                                                              MaterialPageRoute(
                                                                builder:
                                                                    (context) =>
                                                                        ChapterDetailScreen(
                                                                  url: item[
                                                                      'url'],
                                                                  chapterTitle:
                                                                      item['title'] ??
                                                                          'Related Item',
                                                                ),
                                                              ),
                                                            );
                                                          }
                                                        },
                                                        child: Text(
                                                          item['title'] ??
                                                              'Unknown Item',
                                                          style: TextStyle(
                                                            color: Colors.purple
                                                                .shade700,
                                                            decoration:
                                                                TextDecoration
                                                                    .underline,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ))
                                          .toList(),
                                    ),
                                  );
                                },
                              ),
                            ).animate().fadeIn(delay: 700.ms),
                            const SizedBox(height: 24),
                          ],

                          // Metadata sections with staggered animation
                          if (isCategory) ...[
                            if (data?['source'] != null) ...[
                              Text(
                                'Source',
                                style: Theme.of(context).textTheme.titleLarge,
                              ).animate().fadeIn(delay: 850.ms),
                              const SizedBox(height: 8),
                              Card(
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Text(
                                    data?['source'] ?? 'Loading source...',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ),
                              ).animate().fadeIn(delay: 600.ms),
                              const SizedBox(height: 24),
                            ],
                            if (data?['browserUrl'] != null) ...[
                              Text(
                                'Reference Link',
                                style: Theme.of(context).textTheme.titleLarge,
                              ).animate().fadeIn(delay: 950.ms),
                              const SizedBox(height: 8),
                              Card(
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Text(
                                    data?['browserUrl'] ?? 'Loading URL...',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: Colors.blue.shade700,
                                          decoration: TextDecoration.underline,
                                        ),
                                  ),
                                ),
                              ).animate().fadeIn(delay: 800.ms),
                              const SizedBox(height: 24),
                            ],
                          ],

                          // Post-Coordination Scales section
                          _buildPostCoordinationScales(context, data),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Add ALAR footer
          const AlarFooter(),
        ],
      ),
    );
  }

  // Helper method to load related items for perinatal chapter
  Future<List<Map<String, dynamic>>> _loadPerinatalRelatedItems(
      BuildContext context, List<dynamic> urls) async {
    final chapters = Provider.of<Chapters>(context, listen: false);
    final results = <Map<String, dynamic>>[];

    for (final url in urls) {
      try {
        // Try to get data from cache first
        Map<String, dynamic>? data = chapters.getDataForUrl(url);

        // If not in cache, load it
        data ??= await chapters.loadItemData(url);

        if (data != null) {
          results.add({
            'title': data['title']?['@value'] ?? 'Unknown Item',
            'url': url,
          });
        }
      } catch (e) {
        print('Error loading related item $url: $e');
      }
    }

    return results;
  }

  // Add this method to fetch entity data
  Future<void> _loadEntityData(String entityUrl,
      {bool forceRefresh = false}) async {
    if (!forceRefresh && _entityCache.containsKey(entityUrl)) {
      return; // Already loaded
    }

    setState(() {
      _loadingEntities[entityUrl] = true;
      _isLoadingAnyEntity = true;
    });

    try {
      final chapters = Provider.of<Chapters>(context, listen: false);
      // First check if data exists in chapters cache
      Map<String, dynamic>? data = chapters.getDataForUrl(entityUrl);

      // If not in cache, load it
      if (data == null) {
        data = await chapters.loadItemData(entityUrl);
      }

      if (data != null) {
        setState(() {
          _entityCache[entityUrl] = data!;
          // Update entity labels map
          final code = data['code'] ?? '';
          final title = data['title']?['@value'] ?? 'Unknown';
          _entityLabels[entityUrl] = '$code - $title';
        });
      }
    } catch (e) {
      print('Error loading entity data for $entityUrl: $e');
    } finally {
      setState(() {
        _loadingEntities[entityUrl] = false;
        _isLoadingAnyEntity =
            _loadingEntities.values.any((isLoading) => isLoading);
      });
    }
  }

  // Add this method to load entities for a scale
  Future<void> _loadEntitiesForScale(List<String> entityUrls) async {
    // Load all entities in parallel with a limit
    final batches = <List<String>>[];
    for (var i = 0; i < entityUrls.length; i += 5) {
      final end = (i + 5 < entityUrls.length) ? i + 5 : entityUrls.length;
      batches.add(entityUrls.sublist(i, end));
    }

    for (final batch in batches) {
      await Future.wait(batch.map((url) => _loadEntityData(url)));
    }
  }
}
