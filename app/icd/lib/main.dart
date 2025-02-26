import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
          primary: const Color(0xFF6750A4), // Deep purple
          secondary: const Color(0xFFCBC2DB), // Light purple
          tertiary: const Color(0xFFEFE9F7), // Very light purple
          surface: const Color(0xFFF7F2FA), // Almost white purple
          background: Colors.white,
          error: const Color(0xFFBA1A1A),
        ),
        fontFamily: 'Montserrat',
        textTheme: const TextTheme(
          headlineSmall: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1D1B20), // Dark text
          ),
          titleMedium: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Color(0xFF49454F), // Medium dark text
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
          color: const Color(0xFFF7F2FA), // Very light purple
        ),
        listTileTheme: const ListTileThemeData(
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF6750A4), // Deep purple
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
        title: const Text('ICD-11 Chapters')
            .animate()
            .fadeIn(duration: 600.ms)
            .slideX(begin: -0.1, end: 0),
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
                    // Show confirmation dialog with animation
                    showModal(
                      context: context,
                      builder: (context) => AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        title: const Text('Clear Cache'),
                        content: const Text(
                            'Are you sure you want to clear all cached data? This will require reloading all data from the server.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary,
                              foregroundColor:
                                  Theme.of(context).colorScheme.onPrimary,
                            ),
                            onPressed: () async {
                              final prefs =
                                  await SharedPreferences.getInstance();
                              await prefs.clear();
                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('Cleared stored data'),
                                    backgroundColor:
                                        Theme.of(context).colorScheme.primary,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    margin: const EdgeInsets.all(8),
                                  ),
                                );
                              }
                            },
                            child: const Text('Clear'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      body: Consumer<Chapters>(
        builder: (context, chapters, _) {
          // Show a loading indicator if chapters aren't initialized yet
          if (!chapters.isInitialized) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading ICD-11 Chapters...'),
                ],
              ),
            );
          }

          // Show error if initialization failed
          if (chapters.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red),
                  SizedBox(height: 16),
                  Text('Error: ${chapters.error}'),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      chapters.initializeChapters();
                    },
                    child: Text('Retry'),
                  ),
                ],
              ),
            );
          }

          // Display chapters list
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: chapters.chapterUrls.length,
            itemBuilder: (context, index) {
              final url = chapters.chapterUrls[index];
              final data = chapters.getDataForUrl(url);

              return OpenContainer(
                transitionDuration: Duration(milliseconds: 300),
                openBuilder: (_, __) => ChapterDetailScreen(
                  url: url,
                  chapterTitle:
                      data?['title']?['@value'] ?? 'Chapter ${index + 1}',
                ),
                closedElevation: 0,
                closedColor: Colors.transparent,
                middleColor: Theme.of(context).colorScheme.surface,
                transitionType: ContainerTransitionType.fadeThrough,
                closedBuilder: (_, openContainer) => Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 3,
                  shadowColor:
                      Theme.of(context).colorScheme.primary.withOpacity(0.2),
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
                      padding: const EdgeInsets.symmetric(
                          vertical: 18, horizontal: 20),
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
                                      .withOpacity(0.8),
                                ],
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.onPrimary,
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
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
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
              )
                  .animate()
                  .fadeIn(delay: Duration(milliseconds: 50 * index))
                  .slideY(
                      begin: 0.2,
                      end: 0,
                      delay: Duration(milliseconds: 50 * index));
            },
          );
        },
      ),
    );
  }
}
