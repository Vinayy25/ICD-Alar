import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:icd/screens/chapter_detail_screen.dart';
import 'package:icd/state/chapters_state.dart';

class SubcategoriesSection extends StatelessWidget {
  final Map<String, dynamic>? data;
  final bool isChapter;
  final bool isBlock;
  final Chapters chapters;

  const SubcategoriesSection(
      {super.key,
      this.data,
      required this.isChapter,
      required this.isBlock,
      required this.chapters});

  @override
  Widget build(BuildContext context) {
    // Cache all the needed data at the beginning of build
    final childUrls = data != null && data!['child'] != null
        ? List<String>.from(data!['child'])
        : <String>[];

    // Pre-fetch all child data at once to prevent accessing chapters during animation
    final childDataList =
        childUrls.map((url) => chapters.getDataForUrl(url)).toList();

    return Column(children: [
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
        chapters.isLoading ? 5 : childUrls.length,
        (index) {
          if (chapters.isLoading) {
            return _buildSkeletonItem();
          }

          final childUrl = childUrls[index];
          final childData = childDataList[index];
          final isChildCategory = childData?['classKind'] == 'category';

          // Capture widget theme data before the transition
          final primaryColor = Theme.of(context).colorScheme.primary;
          final onPrimaryColor = Theme.of(context).colorScheme.onPrimary;
          final surfaceColor = Theme.of(context).colorScheme.surface;

          return OpenContainer(
            transitionDuration: const Duration(milliseconds: 500),
            openBuilder: (_, __) {
              // Use captured data instead of accessing again during transition
              return ChapterDetailScreen(
                url: childUrl,
                chapterTitle: childData?['title']?['@value'] ?? '',
              );
            },
            closedElevation: 0,
            closedColor: Colors.transparent,
            middleColor: surfaceColor,
            transitionType: ContainerTransitionType.fadeThrough,
            closedBuilder: (_, openContainer) {
              // Pre-build all the UI components before transitions
              final codeWidget = isChildCategory && childData?['code'] != null
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            primaryColor,
                            primaryColor.withValues(alpha: 0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withValues(alpha: 0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        childData?['code'] ?? '',
                        style: TextStyle(
                          color: onPrimaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    )
                  : const SizedBox.shrink();

              final definitionWidget =
                  childData?['definition']?['@value'] != null
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            Text(
                              childData!['definition']['@value']
                                      .toString()
                                      .startsWith('!markdown')
                                  ? 'Contains markdown definition...'
                                  : childData['definition']['@value'],
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        )
                      : const SizedBox.shrink();

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
                shadowColor: Colors.black.withValues(alpha: 0.1),
                child: InkWell(
                  onTap: openContainer,
                  borderRadius: BorderRadius.circular(16),
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
                            if (isChildCategory && childData?['code'] != null)
                              codeWidget,
                            Expanded(
                              child: Text(
                                childData?['title']?['@value'] ?? 'Loading...',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: primaryColor,
                            ),
                          ],
                        ),
                        if (childData?['definition']?['@value'] != null)
                          definitionWidget,
                      ],
                    ),
                  ),
                ),
              );
            },
          )
              .animate()
              .fadeIn(delay: Duration(milliseconds: 1000 + (index * 100)))
              .slideY(
                  begin: 0.2,
                  end: 0,
                  duration: 500.ms,
                  curve: Curves.easeOutQuad);
        },
      ),
      const SizedBox(height: 24),
    ]);
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
