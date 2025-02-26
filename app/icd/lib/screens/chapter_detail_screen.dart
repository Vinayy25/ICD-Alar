import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:animations/animations.dart';
import 'package:flutter_animate/flutter_animate.dart' hide ShimmerEffect;
import '../state/chapters_state.dart';

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

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chapterTitle),
        elevation: 0,
        scrolledUnderElevation: 4,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primary.withOpacity(0.8),
              ],
            ),
          ),
        ),
      ),
      body: Consumer<Chapters>(
        builder: (context, chapters, _) {
          final data = chapters.getDataForUrl(widget.url);
          final isCategory = data?['classKind'] == 'category';

          return Skeletonizer(
            enabled: chapters.isLoading,
            effect: const ShimmerEffect(),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Display code prominently if it's a category
                    if (isCategory && data?['code'] != null)
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
                              .withOpacity(0.3),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Theme.of(context).colorScheme.primary,
                                  Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(0.8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.qr_code,
                                    color:
                                        Theme.of(context).colorScheme.onPrimary,
                                    size: 28,
                                  )
                                      .animate()
                                      .fadeIn(delay: 300.ms, duration: 500.ms)
                                      .scale(delay: 300.ms, duration: 500.ms),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Code: ${data?['code']}',
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
                    )
                        .animate()
                        .fadeIn(duration: 600.ms)
                        .moveX(begin: -10, end: 0, curve: Curves.easeOutQuad),

                    const SizedBox(height: 24),

                    // Definition section with staggered animation
                    if (data?['definition']?['@value'] != null) ...[
                      Text(
                        'Definition',
                        style: Theme.of(context).textTheme.titleLarge,
                      )
                          .animate()
                          .fadeIn(delay: 300.ms)
                          .moveY(begin: 10, end: 0, curve: Curves.easeOutQuad),
                      const SizedBox(height: 8),
                      Card(
                        elevation: 2,
                        shadowColor: Colors.black.withOpacity(0.1),
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
                          .moveY(begin: 20, end: 0, curve: Curves.easeOutQuad),
                      const SizedBox(height: 24),
                    ],

                    // Metadata sections with staggered animation
                    if (isCategory) ...[
                      if (data?['source'] != null) ...[
                        Text(
                          'Source',
                          style: Theme.of(context).textTheme.titleLarge,
                        ).animate().fadeIn(delay: 500.ms),
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
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ).animate().fadeIn(delay: 600.ms),
                        const SizedBox(height: 24),
                      ],
                      if (data?['browserUrl'] != null) ...[
                        Text(
                          'Reference Link',
                          style: Theme.of(context).textTheme.titleLarge,
                        ).animate().fadeIn(delay: 700.ms),
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

                    // Subcategories section with staggered animation
                    if (data?['child'] != null && data?['child'] is List) ...[
                      Text(
                        'Subcategories',
                        style: Theme.of(context).textTheme.titleLarge,
                      ).animate().fadeIn(delay: 900.ms),
                      const SizedBox(height: 12),
                      ...List.generate(
                        chapters.isLoading
                            ? 5
                            : List<String>.from(data?['child'] ?? []).length,
                        (index) {
                          if (chapters.isLoading) {
                            return _buildSkeletonItem();
                          }

                          final childUrls = List<String>.from(data!['child']);
                          final childUrl = childUrls[index];
                          final childData = chapters.getDataForUrl(childUrl);
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
                            middleColor: Theme.of(context).colorScheme.surface,
                            transitionType: ContainerTransitionType.fadeThrough,
                            closedBuilder: (_, openContainer) => Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 2,
                              shadowColor: Colors.black.withOpacity(0.1),
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
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 5),
                                              margin: const EdgeInsets.only(
                                                  right: 12),
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                  colors: [
                                                    Theme.of(context)
                                                        .colorScheme
                                                        .primary,
                                                    Theme.of(context)
                                                        .colorScheme
                                                        .primary
                                                        .withOpacity(0.8),
                                                  ],
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .primary
                                                        .withOpacity(0.3),
                                                    blurRadius: 4,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: Text(
                                                childData?['code'] ?? '',
                                                style: TextStyle(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onPrimary,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                          Expanded(
                                            child: Text(
                                              childData?['title']?['@value'] ??
                                                  'Loading...',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
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
                                      if (childData?['definition']?['@value'] !=
                                          null) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          childData!['definition']['@value']
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
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSkeletonItem() {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 18,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              height: 14,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              height: 14,
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
