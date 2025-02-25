import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/chapter_detail_screen.dart';
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

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ICD-11 Chapters'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cleared stored data')),
                );
              }
            },
          ),
        ],
      ),
      body: Consumer<Chapters>(
        builder: (context, chapters, _) {
          return ListView.builder(
            itemCount: chapters.chapterUrls.length,
            itemBuilder: (context, index) {
              final url = chapters.chapterUrls[index];
              final data = chapters.getDataForUrl(url);

              return ListTile(
                title: Text(
                  data != null
                      ? data['title']['@value']
                      : 'Chapter ${index + 1}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  chapters.loadChapterData(url);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChapterDetailScreen(
                        url: url,
                        chapterTitle:
                            data?['title']?['@value'] ?? 'Chapter ${index + 1}',
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
