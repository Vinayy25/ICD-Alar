import 'dart:math';
import 'package:flutter/material.dart';
import 'package:icd/screens/clipboard.dart';
import 'package:icd/widgets/alar.dart';
import 'package:icd/widgets/chapter_detail_screen/expandable_defination.dart';
import 'package:icd/widgets/chapter_detail_screen/post_coordination.dart';
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
  bool _isDisposed = false;
  // Add these to your class state variables
  List<String> _selectedPostCoordinationCodes = [];
  Map<String, String> _entityLabels =
      {}; // To store entity ID -> label mappings

  // Add these properties to your state class
  Map<String, Map<String, dynamic>> _entityCache = {}; // Cache entity data
  Map<String, bool> _loadingEntities = {}; // Track loading status
  bool _isLoadingAnyEntity = false; // Overall loading flag
  // Add these properties to your _ChapterDetailScreenState class
  Map<String, bool> _entityHasChildren = {}; // Track if entity has children
  Map<String, bool> _expandedEntities = {}; // Track expanded state
  Map<String, List<String>> _entityChildrenUrls = {}; // Store child URLs

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
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
    _isDisposed = true;
    super.dispose();
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

  // Update the _buildPostCoordinationScales method to handle more granular loading states
  Widget _buildPostCoordinationScales(
      BuildContext context, Map<String, dynamic>? data) {
    if (data == null) {
      return const SizedBox.shrink();
    }

    // Show skeleton UI ONLY during initial load (when NO entities are loaded yet)
    final bool isInitialLoading = data['classKind'] == 'category' &&
        data['postcoordinationScale'] != null &&
        _isLoadingAnyEntity &&
        _entityCache.isEmpty;

    if (isInitialLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          // Post-coordination section header with skeleton
          PostCoordiantionGuide(),
          const SizedBox(height: 16),
          // Skeleton loading UI with fixed dimensions
          _buildPostCoordinationSkeleton(context),
        ],
      );
    }

    // If no post-coordination is available, return empty widget
    if (data['classKind'] != 'category' ||
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
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
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
                      icon: const Icon(Icons.copy, size: 20),
                      onPressed: () {
                        // Get base entity information from the data parameter
                        final baseEntityTitle =
                            data?['title']?['@value'] ?? 'Unknown';

                        // Construct a more complete description
                        final description = StringBuffer();

                        // Start with the base code and title
                        description.writeln('$baseCode - $baseEntityTitle');

                        // If we have post-coordination codes, add them with a header
                        if (_selectedPostCoordinationCodes.isNotEmpty) {
                          description.writeln('\nWith post-coordination:');

                          // Add each selected post-coordination code and description
                          for (final url in _selectedPostCoordinationCodes) {
                            final codeLabel =
                                _entityLabels[url] ?? 'Unknown code';
                            description.writeln('• $codeLabel');
                          }
                        }

                        // Save to clipboard history with the enhanced description
                        context.saveToClipboardHistory(
                          code: _buildCompositeCode(baseCode),
                          description: description.toString(),
                        );

                        // Copy the code to clipboard
                        Clipboard.setData(ClipboardData(
                                text: _buildCompositeCode(baseCode)))
                            .then((_) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Combined code copied to clipboard'),
                              behavior: SnackBarBehavior.floating,
                              duration: Duration(seconds: 1),
                            ),
                          );
                        });
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.clear_all, size: 20),
                      onPressed: () {
                        setState(() {
                          _selectedPostCoordinationCodes.clear();
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn(duration: 200.ms).slide(),

        const SizedBox(height: 24),

        // Post-coordination section header
        PostCoordiantionGuide(),

        const SizedBox(height: 16),

        // Each scale section
        ...scales.asMap().entries.map((entry) {
          final scale = entry.value;
          final axisNameUrl = scale['axisName'] as String;
          final axisName = _getAxisDisplayName(axisNameUrl);
          final required = scale['requiredPostcoordination'] == 'true';
          final entities = List<String>.from(scale['scaleEntity'] ?? []);

          // Create description based on required and allowMultiple
          String description = "";
          if (required) {
            description = "(required)";
          } else {
            description = "(use additional code, if desired)";
          }

          // Check if this particular scale is loading - more granular loading state
          final bool isScaleLoading = _isScaleLoading(entities);
          final bool isScaleInitialLoading = isScaleLoading &&
              !entities.any((url) => _entityCache.containsKey(url));

          return AnimatedSize(
            duration: const Duration(milliseconds: 150),
            alignment: Alignment.topCenter,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Axis name and description - always visible
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        "$axisName $description",
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primaryContainer
                            .withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        scale['allowMultipleValues'] == 'AllowAlways'
                            ? "Multiple allowed"
                            : "Single selection",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),

                if (entities.length > 8 && !isScaleInitialLoading) ...[
                  // Search field and "Load all" button - only show if not in initial loading
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
                    ),
                  ),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                const SizedBox(height: 8),

                // Entity list - conditional loading based on scale state
                if (isScaleInitialLoading)
                  // If entire scale is in initial loading, show fixed placeholders
                  _buildEntityLoadingList(min(5, entities.length))
                      .animate()
                      .fadeIn(duration: 200.ms)
                else
                  // Otherwise render each entity with individual loading states
                  Column(
                    children: entities.map((entityUrl) {
                      return _buildEntityItem(entityUrl, scale);
                    }).toList(),
                  ).animate().fadeIn(duration: 200.ms),

                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
              ],
            ),
          ).animate().fadeIn(duration: 300.ms);
        }).toList(),
      ],
    );
  }

  // Add this helper method to check if a specific scale is loading
  bool _isScaleLoading(List<String> entityUrls) {
    // Check if any of the direct child entities are loading
    for (final url in entityUrls) {
      if (_loadingEntities[url] == true) {
        return true;
      }
    }
    return false;
  }

  String _buildCompositeCode(String baseCode) {
    if (_selectedPostCoordinationCodes.isEmpty) return baseCode;

    String result = baseCode;

    // Process each selected code
    for (final url in _selectedPostCoordinationCodes) {
      final entityData = _entityCache[url];
      final code = entityData?['code'] ?? '';

      // Skip if no code is available
      if (code.isEmpty) continue;

      // Use & if the code starts with X, else use /
      if (code.startsWith('X')) {
        result += "&$code";
      } else {
        result += "/$code";
      }
    }

    return result;
  }

  // Update the _toggleEntitySelection method to properly handle nested hierarchies
  void _toggleEntitySelection(String entityUrl, Map<String, dynamic> scale) {
    final allowMultiple = scale['allowMultipleValues'] == 'AllowAlways';
    final entityData = _entityCache[entityUrl];
    final hasCode = entityData?['code'] != null &&
        (entityData?['code'] as String).isNotEmpty;

    // Don't allow selection if no code is available
    if (!hasCode) return;

    setState(() {
      if (_selectedPostCoordinationCodes.contains(entityUrl)) {
        // Remove selection
        _selectedPostCoordinationCodes.remove(entityUrl);
      } else {
        // If multiple selections not allowed, remove any existing selection from this scale
        // including from any nested child at any depth
        if (!allowMultiple) {
          // Get all entities that belong to this scale (including nested ones)
          final scaleEntities = _getAllEntitiesForScale(scale);

          // Remove any selected codes from this scale
          _selectedPostCoordinationCodes
              .removeWhere((url) => scaleEntities.contains(url));
        }

        // Add the new selection
        _selectedPostCoordinationCodes.add(entityUrl);
      }
    });
  }

  // Add this helper method to recursively get all entities that belong to a scale
  Set<String> _getAllEntitiesForScale(Map<String, dynamic> scale) {
    Set<String> result = {};

    // Add direct children from the scale
    if (scale['scaleEntity'] != null && scale['scaleEntity'] is List) {
      final directEntities = List<String>.from(scale['scaleEntity']);
      result.addAll(directEntities);

      // Now recursively check for all nested children
      for (final entityUrl in directEntities) {
        _addAllNestedChildren(entityUrl, result);
      }
    }

    return result;
  }

  // Recursively add all nested children of an entity
  void _addAllNestedChildren(String entityUrl, Set<String> accumulator) {
    // If we have children for this entity
    if (_entityChildrenUrls.containsKey(entityUrl)) {
      final childUrls = _entityChildrenUrls[entityUrl]!;

      // Add all children
      accumulator.addAll(childUrls);

      // Recursively process each child
      for (final childUrl in childUrls) {
        _addAllNestedChildren(childUrl, accumulator);
      }
    }
  }

// Replace your _loadEntityData method with this enhanced version
  Future<void> _loadEntityData(String entityUrl,
      {bool forceRefresh = false,
      bool loadChildren = true,
      int nestingLevel = 0, // Track nesting level for smart loading
      int maxDepth = 5 // Prevent infinite recursion
      }) async {
    if (!mounted) return; // Stop if widget is no longer mounted
    if (!forceRefresh && _entityCache.containsKey(entityUrl) ||
        nestingLevel > maxDepth) {
      return; // Already loaded or reached max depth
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
      data ??= await chapters.loadItemData(entityUrl);

      if (data != null && mounted) {
        // Add mounted check here too
        setState(() {
          _entityCache[entityUrl] = data!;
          // Update entity labels map
          final code = data['code'] ?? '';
          final title = data['title']?['@value'] ?? 'Unknown';
          _entityLabels[entityUrl] = '$code - $title';

          // Check if this entity has children and NO code - need to load them
          final hasChildren = data['child'] != null &&
              data['child'] is List &&
              (data['child'] as List).isNotEmpty;
          final hasCode = code.isNotEmpty;

          if (hasChildren) {
            // Store for UI expansion regardless of code status
            _entityHasChildren[entityUrl] = true;
            _expandedEntities[entityUrl] = false; // Default collapsed

            // Store child URLs
            List<String> childUrls = List<String>.from(data['child']);
            _entityChildrenUrls[entityUrl] = childUrls;

            // Smart preloading strategy based on nesting level
            if (loadChildren) {
              int preloadCount;
              if (nestingLevel == 0) {
                // First level: Load first few children immediately
                preloadCount = 3;
              } else if (nestingLevel == 1) {
                // Second level: Load fewer children
                preloadCount = 2;
              } else {
                // Deeper levels: Load just one to maintain responsiveness
                preloadCount = 1;
              }

              // Preload immediate children
              for (int i = 0; i < childUrls.length && i < preloadCount; i++) {
                // Load but don't recursively load grandchildren until expanded
                _loadEntityData(childUrls[i],
                    loadChildren: false, nestingLevel: nestingLevel + 1);
              }

              // For no-code parent categories at level 0-1, also check first child
              // to see if it has children (common hierarchical pattern)
              if (!hasCode && nestingLevel <= 1 && childUrls.isNotEmpty) {
                // Check first child for deeper nesting
                _checkForDeepNesting(childUrls.first, nestingLevel + 1);
              }
            }
          }
        });
      }
    } catch (e) {
      print(
          'Error loading entity data for $entityUrl (level $nestingLevel): $e');
    } finally {
      if (mounted) {
        // Important mounted check before setState
        setState(() {
          _loadingEntities[entityUrl] = false;

          // Check if ANY entity is still loading
          bool stillLoading = false;
          _loadingEntities.forEach((key, value) {
            if (value) stillLoading = true;
          });
          _isLoadingAnyEntity = stillLoading;
        });
      }
    }
  }

// Add this helper method to check for deep nesting patterns
  Future<void> _checkForDeepNesting(String entityUrl, int nestingLevel) async {
    if (!mounted) return;

    try {
      final chapters = Provider.of<Chapters>(context, listen: false);
      Map<String, dynamic>? data = chapters.getDataForUrl(entityUrl);
      data ??= await chapters.loadItemData(entityUrl);

      if (data != null && mounted) {
        final hasChildren = data['child'] != null &&
            data['child'] is List &&
            (data['child'] as List).isNotEmpty;
        final hasCode = (data['code'] ?? '').isNotEmpty;

        if (hasChildren && !hasCode) {
          // Store metadata for this entity
          setState(() {
            _entityCache[entityUrl] = data!;
            _entityHasChildren[entityUrl] = true;
            _expandedEntities[entityUrl] = false;
            _entityChildrenUrls[entityUrl] = List<String>.from(data['child']);

            final title = data['title']?['@value'] ?? 'Unknown';
            _entityLabels[entityUrl] = '${data['code'] ?? ''} - $title';
          });
        }
      }
    } catch (e) {
      print('Error checking deep nesting for $entityUrl: $e');
    }
  }

// Modify this method to handle expanded state more efficiently
  void _onEntityExpand(String entityUrl) {
    setState(() {
      // Toggle expanded state
      _expandedEntities[entityUrl] = !(_expandedEntities[entityUrl] ?? false);

      // Load children when expanded
      if (_expandedEntities[entityUrl] == true) {
        final childUrls = _entityChildrenUrls[entityUrl] ?? [];
        for (final childUrl in childUrls) {
          if (!_entityCache.containsKey(childUrl)) {
            _loadEntityData(childUrl, loadChildren: true);
          }
        }

        // Also probe one level deeper for nested hierarchies
        _loadDeepNestingOnExpand(childUrls);
      }
    });
  }

// Add this method to smartly load deeper nested structures
  Future<void> _loadDeepNestingOnExpand(List<String> childUrls) async {
    if (!mounted) return;

    // Only process a few children to prevent overwhelming
    final sampleSize = childUrls.length > 3 ? 3 : childUrls.length;
    final sampleUrls = childUrls.take(sampleSize).toList();

    for (final url in sampleUrls) {
      if (_entityCache.containsKey(url)) {
        final entityData = _entityCache[url]!;
        final hasChildren = entityData['child'] != null &&
            entityData['child'] is List &&
            (entityData['child'] as List).isNotEmpty;
        final hasCode = (entityData['code'] ?? '').isNotEmpty;

        if (hasChildren && !hasCode) {
          // It's a category with children - prepare child data
          List<String> grandchildUrls = List<String>.from(entityData['child']);
          _entityChildrenUrls[url] = grandchildUrls;
          _entityHasChildren[url] = true;

          // Preload first couple of grandchildren
          for (int i = 0; i < grandchildUrls.length && i < 2; i++) {
            _loadEntityData(grandchildUrls[i], loadChildren: false);
          }
        }
      }
    }
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

      // Add this to the Scaffold in your ChapterDetailScreen build method
// Inside the Scaffold, after the existing properties like appBar and body:

      floatingActionButton: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            height: 56,
            width: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                  spreadRadius: 2,
                ),
              ],
            ),
            child: FloatingActionButton(
              heroTag: 'homeButton',
              elevation: 0,
              backgroundColor: Colors.transparent,
              splashColor:
                  Theme.of(context).colorScheme.onPrimary.withOpacity(0.4),
              onPressed: () {
                // Add navigation animation
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: Container(
                height: 56,
                width: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Icon(
                  Icons.home_rounded,
                  size: 28,
                ),
              ),
            ),
          )
              .animate(
                autoPlay: true,
                onComplete: (controller) {
                  controller.repeat(reverse: true);
                },
              )
              .scaleXY(
                begin: 1.0,
                end: 1.05,
                duration: 2000.ms,
                curve: Curves.easeInOut,
              )
              .animate(
                target: _controller.value,
              )
              .rotate(
                begin: 0,
                end: 0.00,
                duration: 300.ms,
                curve: Curves.easeOut,
              );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
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
                              overflow: TextOverflow.ellipsis,
                            ).animate().fadeIn(delay: 300.ms).moveY(
                                begin: 10, end: 0, curve: Curves.easeOutQuad),
                            const SizedBox(height: 8),
                            ExpandableDefinition(
                              definitionText: data?['definition']?['@value'],
                              parentContext: context,
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

  // Add this to improve visual display of deep hierarchies
  Widget _buildHierarchyConnector(double indentLevel) {
    if (indentLevel == 0) return const SizedBox.shrink();

    return Positioned(
      left: indentLevel * 16 - 8,
      top: 0,
      bottom: 0,
      width: 0,
      child: Container(
        color: Colors.red,
      ),
    );
  }

  // Add this method to create consistent skeleton loaders for post-coordination items
  Widget _buildPostCoordinationSkeleton(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (scaleIndex) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Axis header skeleton
            Row(
              children: [
                Expanded(
                  child: buildSkeletonLoader(
                    height: 24,
                    width: double.infinity,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 8),
                buildSkeletonLoader(
                  height: 24,
                  width: 80,
                  borderRadius: BorderRadius.circular(12),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Entity items skeletons - create multiple with consistent heights
            ...List.generate(
                5,
                (index) => Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Row(
                        children: [
                          buildSkeletonLoader(
                            height: 20,
                            width: 20,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: buildSkeletonLoader(
                              height: 20,
                              width: double.infinity,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    )),

            const SizedBox(height: 16),
            buildSkeletonLoader(
              height: 1,
              width: double.infinity,
              borderRadius: BorderRadius.circular(0),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

// Add this method to build a list of skeleton placeholders with consistent height
  Widget _buildEntityLoadingList(int count) {
    return Column(
      children: List.generate(
        count,
        (index) => Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            children: [
              buildSkeletonLoader(
                height: 20,
                width: 20,
                borderRadius: BorderRadius.circular(10),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: buildSkeletonLoader(
                  height: 20,
                  width: double.infinity,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

// Add this method to render entity items with proper hierarchy and loading states
  Widget _buildEntityItem(String entityUrl, Map<String, dynamic> scale,
      {double indentLevel = 0}) {
    // Start loading if not already loaded
    if (!_entityCache.containsKey(entityUrl) &&
        _loadingEntities[entityUrl] != true) {
      // Schedule loading after build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          // Only load if still mounted
          _loadEntityData(entityUrl);
        }
      });
    }

    final isLoading = _loadingEntities[entityUrl] == true;
    final entityData = _entityCache[entityUrl];

    final entityCode = entityData?['code'] ?? '';
    final hasCode = entityCode.isNotEmpty;

    final entityTitle = entityData?['title']?['@value'] ??
        (isLoading ? 'Loading...' : 'Unknown');

    final isSelected = _selectedPostCoordinationCodes.contains(entityUrl);
    final allowMultiple = scale['allowMultipleValues'] == 'AllowAlways';
    final hasChildren = _entityHasChildren[entityUrl] == true;
    final isExpanded = _expandedEntities[entityUrl] == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: 4.0, left: indentLevel * 16),
          child: Stack(
            children: [
              if (indentLevel > 0) _buildHierarchyConnector(indentLevel),
              InkWell(
                onTap: isLoading
                    ? null
                    : () {
                        if (hasChildren && !hasCode) {
                          // Toggle expansion for parent categories
                          _onEntityExpand(entityUrl);
                        } else if (hasCode) {
                          // Select/deselect for entities with codes
                          _toggleEntitySelection(entityUrl, scale);
                        }
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
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : hasChildren && !hasCode
                                ? Icon(
                                    isExpanded
                                        ? Icons.expand_more
                                        : Icons.chevron_right,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    size: 20,
                                  )
                                : hasCode
                                    ? isSelected
                                        ? Icon(
                                            allowMultiple
                                                ? Icons.check_box
                                                : Icons.radio_button_checked,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                            size: 20,
                                          )
                                        : Icon(
                                            allowMultiple
                                                ? Icons.check_box_outline_blank
                                                : Icons.radio_button_unchecked,
                                            color: Colors.grey,
                                            size: 20,
                                          )
                                    : const Icon(
                                        Icons.remove,
                                        color: Colors.grey,
                                        size: 20,
                                      ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: isLoading
                            ? buildSkeletonLoader(
                                height: 16,
                                width: double.infinity,
                                borderRadius: BorderRadius.circular(4),
                              )
                            : RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: hasCode
                                          ? entityCode
                                          : hasChildren
                                              ? ''
                                              : '(No code) ',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: hasCode
                                            ? Theme.of(context)
                                                .colorScheme
                                                .primary
                                            : Colors.grey,
                                      ),
                                    ),
                                    TextSpan(
                                      text: hasCode
                                          ? " $entityTitle"
                                          : entityTitle,
                                      style: TextStyle(
                                        color: hasChildren && !hasCode
                                            ? Theme.of(context)
                                                .colorScheme
                                                .primary
                                            : hasCode
                                                ? Theme.of(context)
                                                            .brightness ==
                                                        Brightness.dark
                                                    ? Colors.white
                                                    : Colors.black
                                                : Colors.grey,
                                        fontWeight: hasChildren && !hasCode
                                            ? FontWeight.w500
                                            : FontWeight.normal,
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
            ],
          ),
        ),

        // Show children if expanded
        if (hasChildren &&
            isExpanded &&
            _entityChildrenUrls.containsKey(entityUrl))
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            alignment: Alignment.topCenter,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _entityChildrenUrls[entityUrl]!.map((childUrl) {
                return _buildEntityItem(childUrl, scale,
                    indentLevel: indentLevel + 1);
              }).toList(),
            ),
          ),
      ],
    );
  }
}
