import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/chapters_state.dart';

class ChapterDetailScreen extends StatelessWidget {
  final String url;
  final String chapterTitle;

  const ChapterDetailScreen({
    Key? key,
    required this.url,
    required this.chapterTitle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(chapterTitle),
      ),
      body: Consumer<Chapters>(
        builder: (context, chapters, _) {
          // Preload data when screen initializes
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!chapters.hierarchyData.containsKey(url)) {
              chapters.loadChapterData(url);
            }
          });

          final data = chapters.getDataForUrl(url);

          if (data == null || chapters.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['title']?['@value'] ?? 'No Title',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  if (data['definition']?['@value'] != null) ...[
                    Text(
                      'Definition',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(data['definition']['@value']),
                    const SizedBox(height: 16),
                  ],
                  if (data['child'] != null && data['child'] is List) ...[
                    Text(
                      'Subcategories',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    ...List<String>.from(data['child'])
                        .map(
                          (childUrl) => ListTile(
                            title: Text(chapters.getTitleForUrl(childUrl) ??
                                'Loading...'),
                            trailing: const Icon(Icons.arrow_forward_ios),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChapterDetailScreen(
                                    url: childUrl,
                                    chapterTitle:
                                        chapters.getTitleForUrl(childUrl) ?? '',
                                  ),
                                ),
                              );
                            },
                          ),
                        )
                        .toList(),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
