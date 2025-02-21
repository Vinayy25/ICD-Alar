import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'state/chapters_state.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => Chapters()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ICD-10',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const Home(),
    );
  }
}

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    final chapters = Provider.of<Chapters>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ICD-10'),
      ),
      body: ListView.builder(
        itemCount: chapters.chapterUrls.length,
        itemBuilder: (context, index) {
          return ExpansionTile(
            title: Text('Chapter ${index + 1}'),
            onExpansionChanged: (expanded) {
              if (expanded) {
                chapters.loadChapterData(chapters.chapterUrls[index]);
                
              }
            },
            children: [
              if (chapters.isLoading &&
                  chapters.selectedChapterUrl == chapters.chapterUrls[index])
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (chapters.error != null &&
                  chapters.selectedChapterUrl == chapters.chapterUrls[index])
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Error: ${chapters.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                )
              else if (chapters.selectedChapterData != null &&
                  chapters.selectedChapterUrl == chapters.chapterUrls[index])
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        chapters.selectedChapterData!['title']?['@value'] ??
                            'No title',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Add more chapter data display here as needed
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
