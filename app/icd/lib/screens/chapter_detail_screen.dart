import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:icd/widgets/alar.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:animations/animations.dart';
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

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Clear selected post-coordination codes
    _selectedPostCoordinationCodes = [];
    _entityLabels = {};

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
                    children: _selectedPostCoordinationCodes.map((code) {
                      return Chip(
                        label: Text(
                          _entityLabels[code] ?? code,
                          style: TextStyle(fontSize: 12),
                        ),
                        deleteIcon: Icon(Icons.close, size: 16),
                        onDeleted: () {
                          setState(() {
                            _selectedPostCoordinationCodes.remove(code);
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
              ],

              const SizedBox(height: 8),

              // Entity list
              ...entities.map((entity) {
                final entityCode = _extractEntityCode(entity);
                // In a real app, you'd fetch these labels from API
                final label =
                    "Vibrio cholerae code"; // This would be replaced with actual data
                _entityLabels[entityCode] = label; // Store for later use

                final isSelected =
                    _selectedPostCoordinationCodes.contains(entityCode);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedPostCoordinationCodes.remove(entityCode);
                        } else {
                          _selectedPostCoordinationCodes.add(entityCode);
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
                            child: isSelected
                                ? Icon(
                                    Icons.check_box,
                                    color:
                                        Theme.of(context).colorScheme.primary,
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
                            child: RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: entityCode,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                  TextSpan(
                                    text: " $label",
                                    style: TextStyle(
                                      color: Theme.of(context).brightness ==
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

    // Group by axis (in a real app, you'd track which axis each code belongs to)
    // For this example, we'll just assume first code is from first axis
    String result = baseCode;

    // Add first code with &
    if (_selectedPostCoordinationCodes.isNotEmpty) {
      result += "&${_selectedPostCoordinationCodes[0]}";
    }

    // Add subsequent codes with /
    if (_selectedPostCoordinationCodes.length > 1) {
      result += _selectedPostCoordinationCodes
          .sublist(1)
          .map((code) => "/$code")
          .join("");
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
                            AnimatedBuilder(
                              animation: _controller,
                              builder: (context, child) {
                                return Transform.translate(
                                  offset: Offset(
                                    0,
                                    (1 - _controller.value) * -30,
                                  ),
                                  child: Opacity(
                                    opacity: _controller.value,
                                    child: child,
                                  ),
                                );
                              },
                              child: Card(
                                elevation: 4,
                                shadowColor: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.3),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        isChapter
                                            ? Theme.of(context)
                                                .colorScheme
                                                .secondary
                                            : Theme.of(context)
                                                .colorScheme
                                                .primary,
                                        isChapter
                                            ? Theme.of(context)
                                                .colorScheme
                                                .secondary
                                                .withValues(alpha: 0.8)
                                            : Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .withValues(alpha: 0.8),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Row(
                                      children: [
                                        Icon(
                                          isChapter
                                              ? Icons.menu_book
                                              : Icons.qr_code,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onPrimary,
                                          size: 28,
                                        )
                                            .animate()
                                            .fadeIn(
                                                delay: 300.ms, duration: 500.ms)
                                            .scale(
                                                delay: 300.ms,
                                                duration: 500.ms),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            isChapter
                                                ? 'Chapter ${data?['code']}'
                                                : '${data?['code']}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleLarge
                                                ?.copyWith(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onPrimary,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                        ),

                                        AlarLogo(
                                          size: 24,
                                          isAnimated: true,
                                        ),
                                        // Add copy button for disease codes (categories)
                                        if (isCategory)
                                          IconButton(
                                            iconSize: 20,
                                            icon: Icon(
                                              Icons.copy,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onPrimary,
                                            ),
                                            onPressed: () {
                                              final code = data?['code'] ?? '';
                                              // Copy code to clipboard
                                              Clipboard.setData(
                                                      ClipboardData(text: code))
                                                  .then((_) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                        'Code $code copied to clipboard'),
                                                    behavior: SnackBarBehavior
                                                        .floating,
                                                    margin:
                                                        const EdgeInsets.all(8),
                                                    duration: const Duration(
                                                        seconds: 2),
                                                  ),
                                                );
                                              });
                                            },
                                          )
                                              .animate()
                                              .fadeIn(
                                                  delay: 600.ms,
                                                  duration: 500.ms)
                                              .scale(
                                                  delay: 600.ms,
                                                  duration: 300.ms),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            )
                          // For the block code card, add a copy button
                          else if (isBlock && data?['codeRange'] != null)
                            AnimatedBuilder(
                              animation: _controller,
                              builder: (context, child) {
                                return Transform.translate(
                                  offset: Offset(
                                    0,
                                    (1 - _controller.value) * -30,
                                  ),
                                  child: Opacity(
                                    opacity: _controller.value,
                                    child: child,
                                  ),
                                );
                              },
                              child: Card(
                                elevation: 4,
                                shadowColor: Theme.of(context)
                                    .colorScheme
                                    .tertiary
                                    .withValues(alpha: 0.3),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Theme.of(context).colorScheme.tertiary,
                                        Theme.of(context)
                                            .colorScheme
                                            .tertiary
                                            .withValues(alpha: 0.8),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.view_module,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onTertiary,
                                              size: 28,
                                            )
                                                .animate()
                                                .fadeIn(
                                                    delay: 300.ms,
                                                    duration: 500.ms)
                                                .scale(
                                                    delay: 300.ms,
                                                    duration: 500.ms),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                'Block: ${data?['blockId'] ?? ''}',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleLarge
                                                    ?.copyWith(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .onTertiary,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                              ),
                                            ),
                                            // Add the copy button
                                            IconButton(
                                              icon: Icon(
                                                Icons.copy,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onTertiary,
                                              ),
                                              onPressed: () {
                                                final codeRange =
                                                    data?['codeRange'] ?? '';
                                                // Copy code range to clipboard
                                                Clipboard.setData(ClipboardData(
                                                        text: codeRange))
                                                    .then((_) {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                          'Code range $codeRange copied to clipboard'),
                                                      behavior: SnackBarBehavior
                                                          .floating,
                                                      margin:
                                                          const EdgeInsets.all(
                                                              8),
                                                      duration: const Duration(
                                                          seconds: 2),
                                                    ),
                                                  );
                                                });
                                              },
                                            )
                                                .animate()
                                                .fadeIn(
                                                    delay: 600.ms,
                                                    duration: 500.ms)
                                                .scale(
                                                    delay: 600.ms,
                                                    duration: 300.ms),
                                          ],
                                        ),
                                        if (data?['codeRange'] != null) ...[
                                          const SizedBox(height: 8),
                                          Text(
                                            'Code Range: ${data?['codeRange']}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onTertiary,
                                                ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              ),
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
                            Text(
                              isChapter
                                  ? 'Sections'
                                  : isBlock
                                      ? 'Categories'
                                      : 'Subcategories',
                              style: Theme.of(context).textTheme.titleLarge,
                            ).animate().fadeIn(delay: 450.ms),
                            const SizedBox(height: 12),
                            ...List.generate(
                              chapters.isLoading
                                  ? 5
                                  : List<String>.from(data?['child'] ?? [])
                                      .length,
                              (index) {
                                if (chapters.isLoading) {
                                  return _buildSkeletonItem();
                                }

                                final childUrls =
                                    List<String>.from(data!['child']);
                                final childUrl = childUrls[index];
                                final childData =
                                    chapters.getDataForUrl(childUrl);
                                final isChildCategory =
                                    childData?['classKind'] == 'category';

                                return OpenContainer(
                                  transitionDuration:
                                      const Duration(milliseconds: 500),
                                  openBuilder: (_, __) => ChapterDetailScreen(
                                    url: childUrl,
                                    chapterTitle:
                                        childData?['title']?['@value'] ?? '',
                                  ),
                                  closedElevation: 0,
                                  closedColor: Colors.transparent,
                                  middleColor:
                                      Theme.of(context).colorScheme.surface,
                                  transitionType:
                                      ContainerTransitionType.fadeThrough,
                                  closedBuilder: (_, openContainer) => Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 2,
                                    shadowColor:
                                        Colors.black.withValues(alpha: 0.1),
                                    child: InkWell(
                                      onTap: openContainer,
                                      borderRadius: BorderRadius.circular(16),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                          horizontal: 16,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                if (isChildCategory &&
                                                    childData?['code'] != null)
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 10,
                                                        vertical: 5),
                                                    margin:
                                                        const EdgeInsets.only(
                                                            right: 12),
                                                    decoration: BoxDecoration(
                                                      gradient: LinearGradient(
                                                        begin:
                                                            Alignment.topLeft,
                                                        end: Alignment
                                                            .bottomRight,
                                                        colors: [
                                                          Theme.of(context)
                                                              .colorScheme
                                                              .primary,
                                                          Theme.of(context)
                                                              .colorScheme
                                                              .primary
                                                              .withValues(
                                                                  alpha: 0.8),
                                                        ],
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .primary
                                                                  .withValues(
                                                                      alpha:
                                                                          0.3),
                                                          blurRadius: 4,
                                                          offset: const Offset(
                                                              0, 2),
                                                        ),
                                                      ],
                                                    ),
                                                    child: Text(
                                                      childData?['code'] ?? '',
                                                      style: TextStyle(
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .onPrimary,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  ),
                                                Expanded(
                                                  child: Text(
                                                    childData?['title']
                                                            ?['@value'] ??
                                                        'Loading...',
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                ),
                                                Icon(
                                                  Icons.arrow_forward_ios,
                                                  size: 16,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .primary,
                                                ),
                                              ],
                                            ),
                                            if (childData?['definition']
                                                    ?['@value'] !=
                                                null) ...[
                                              const SizedBox(height: 8),
                                              Text(
                                                childData!['definition']
                                                            ['@value']
                                                        .toString()
                                                        .startsWith('!markdown')
                                                    ? 'Contains markdown definition...'
                                                    : childData['definition']
                                                        ['@value'],
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: Colors.grey.shade600,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                                    .animate()
                                    .fadeIn(
                                        delay: Duration(
                                            milliseconds: 1000 + (index * 100)))
                                    .slideY(
                                        begin: 0.2,
                                        end: 0,
                                        duration: 500.ms,
                                        curve: Curves.easeOutQuad);
                              },
                            ),
                            const SizedBox(height: 24),
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
        if (data == null) {
          data = await chapters.loadItemData(url);
        }

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

  Widget _buildSkeletonItem() {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  width: 60,
                  height: 24,
                ),
                Expanded(
                  child: Container(
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              height: 12,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 12,
              width: 200,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
