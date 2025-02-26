import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/chapters_state.dart';

class ChapterDetailScreen extends StatefulWidget {
  final String url;
  final String chapterTitle;

  const ChapterDetailScreen({
    Key? key,
    required this.url,
    required this.chapterTitle,
  }) : super(key: key);

  @override
  State<ChapterDetailScreen> createState() => _ChapterDetailScreenState();
}

class _ChapterDetailScreenState extends State<ChapterDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Load all data for this screen when it opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<Chapters>().loadScreenData(widget.url);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chapterTitle),
      ),
      body: Consumer<Chapters>(
        builder: (context, chapters, _) {
          if (chapters.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final data = chapters.getDataForUrl(widget.url);
          if (data == null) {
            return const Center(
              child: Text('No data available'),
            );
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
                    ...List<String>.from(data['child']).map((childUrl) {
                      final childData = chapters.getDataForUrl(childUrl);
                      return ListTile(
                        title: Text(
                            childData?['title']?['@value'] ?? 'Loading...'),
                        subtitle: childData?['child'] != null
                            ? Text(
                                '${List<String>.from(childData!['child']).length} subcategories')
                            : null,
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChapterDetailScreen(
                                url: childUrl,
                                chapterTitle:
                                    childData?['title']?['@value'] ?? '',
                              ),
                            ),
                          );
                        },
                      );
                    }).toList(),
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
