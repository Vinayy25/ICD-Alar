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
        colorScheme: ColorScheme.light(
          primary: const Color(0xFF6750A4),      // Deep purple
          secondary: const Color(0xFFCBC2DB),    // Light purple
          tertiary: const Color(0xFFEFE9F7),     // Very light purple
          surface: const Color(0xFFF7F2FA),      // Almost white purple
          background: Colors.white,
          error: const Color(0xFFBA1A1A),
        ),
        fontFamily: 'Montserrat',
        textTheme: const TextTheme(
          headlineSmall: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1D1B20),            // Dark text
          ),
          titleMedium: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Color(0xFF49454F),            // Medium dark text
          ),
          bodyMedium: TextStyle(
            fontSize: 16,
            color: Color(0xFF49454F),
          ),
        ),
        cardTheme: CardTheme(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: const Color(0xFFF7F2FA),        // Very light purple
        ),
        listTileTheme: const ListTileThemeData(
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF6750A4),     // Deep purple
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        useMaterial3: true,
        visualDensity: VisualDensity.adaptivePlatformDensity,
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
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('ICD-11 Chapters'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  'Clear cache',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_forever),
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.clear();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Cleared stored data'),
                          backgroundColor: Theme.of(context).colorScheme.primary,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      body: Consumer<Chapters>(
        builder: (context, chapters, _) {
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: chapters.chapterUrls.length,
            itemBuilder: (context, index) {
              final url = chapters.chapterUrls[index];
              final data = chapters.getDataForUrl(url);

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(
                    data != null
                        ? data['title']['@value']
                        : 'Chapter ${index + 1}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
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
                ),
              );
            },
          );
        },
      ),
    );
  }
}
