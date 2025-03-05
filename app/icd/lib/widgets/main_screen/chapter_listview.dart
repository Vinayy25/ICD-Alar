import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:icd/screens/chapter_detail_screen.dart';
import 'package:icd/state/chapters_state.dart';

class MainScreenChapterListview extends StatelessWidget {
  final Chapters chapters;
  const MainScreenChapterListview({required this.chapters, super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      cacheExtent: 20,
      padding: const EdgeInsets.all(16),
      itemCount: chapters.chapterUrls.length,
      itemBuilder: (context, index) {
        final url = chapters.chapterUrls[index];
        final data = chapters.getDataForUrl(url);

        return OpenContainer(
          transitionDuration: Duration(milliseconds: 300),
          openBuilder: (_, __) => ChapterDetailScreen(
            url: url,
            chapterTitle: data?['title']?['@value'] ?? 'Chapter ${index + 1}',
          ),
          closedElevation: 0,
          closedColor: Colors.transparent,
          middleColor: Theme.of(context).colorScheme.surface,
          transitionType: ContainerTransitionType.fadeThrough,
          closedBuilder: (_, openContainer) => Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 3,
            shadowColor:
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: InkWell(
              onTap: () {
                chapters.loadChapterData(url);
                openContainer();
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Theme.of(context).colorScheme.primary,
                            Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.8),
                          ],
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data != null && data['title'] != null
                                ? data['title']['@value']
                                : 'Chapter ${index + 1}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          if (data != null && data['description'] != null)
                            Text(
                              data['description']['@value'],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: Theme.of(context).colorScheme.primary,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ).animate().fadeIn(delay: Duration(milliseconds: 10 * index)).slideY(
            begin: 0.2, end: 0, delay: Duration(milliseconds: 10 * index));
      },
    );
  }
}
