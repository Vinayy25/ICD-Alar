import 'package:animations/animations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_advanced_drawer/flutter_advanced_drawer.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:icd/firebase_options.dart';
import 'package:icd/screens/auth_screen.dart';
import 'package:icd/screens/clipboard.dart';
import 'package:icd/screens/contribute_to_developer.dart';
import 'package:icd/screens/feedback_screen.dart';
import 'package:icd/screens/get_premium.dart';
import 'package:icd/screens/search_screen.dart';
import 'package:icd/state/auth_state.dart';
import 'package:icd/widgets/alar.dart';
import 'package:icd/widgets/main_screen/chapter_listview.dart';
import 'package:icd/widgets/main_screen/floating_search.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/chapter_detail_screen.dart';
import 'state/chapters_state.dart';
import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:lottie/lottie.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => Chapters()),
        ChangeNotifierProvider(create: (context) => AuthStateProvider()),
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
      title: 'ICD Alar',
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
      home: Consumer<AuthStateProvider>(
        builder: (context, provider, child) {
          if (provider.isAuthenticated) {
            print("isNewUser: ${provider.email}");
            return Home();
          } else {
            return LoginPage(
              authProvider: provider,
            );
          }
        },
      ),
    );
  }
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with SingleTickerProviderStateMixin {
  final _advancedDrawerController = AdvancedDrawerController();
  int _bottomNavIndex = 0;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;

  final List<IconData> iconList = [
    Icons.home,
    Icons.person,
  ];

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimation = CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdvancedDrawer(
      initialDrawerScale: 0.8,
      backdropColor: Colors.deepPurple,
      drawerSlideRatio: 0.2,
      drawer: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
              ],
            ),
          ),
          child: ListTileTheme(
            textColor: Colors.white,
            iconColor: Colors.white,
            // Replace Column with ListView for scrolling capability
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                Container(
                    margin: const EdgeInsets.only(
                      top: 24.0,
                      bottom: 24.0,
                    ),
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                      color: Colors.white,

                      shape: BoxShape.rectangle,
                      // borderRadius: BorderRadius.circular(30),
                    ),
                    child: Image.asset(
                        fit: BoxFit.cover, 'assets/icons/alar_logo_nobg.png')),

                Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  child: Text(
                    "ICD-11 Browser",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),

                Divider(color: Colors.white30),

                ListTile(
                  onTap: () {
                    _advancedDrawerController.hideDrawer();
                  },
                  leading: const Icon(Icons.home),
                  title: const Text('Home'),
                ),

                ListTile(
                  onTap: () async {
                    // Show history of viewed codes - implement later
                    _advancedDrawerController.hideDrawer();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('History feature coming soon'),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  leading: const Icon(Icons.history),
                  title: const Text('History'),
                ),

                ListTile(
                  onTap: () async {
                    // Clear the cache after confirmation
                    _advancedDrawerController.hideDrawer();
                    showModal(
                      context: context,
                      builder: (context) => AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        title: const Text('Clear Cache'),
                        content: const Text(
                          'Are you sure you want to clear all cached data? This will require reloading all data from the server.',
                        ),
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
                  leading: const Icon(Icons.cleaning_services),
                  title: const Text('Clear Cache'),
                ),
                //premium screen
                ListTile(
                  onTap: () {
                    _advancedDrawerController.hideDrawer();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => GetPremiumScreen()),
                    );
                  },
                  leading: const Icon(Icons.feedback),
                  title: const Text('Get Premium'),
                ),

                // Medical Tools Section
                Divider(color: Colors.white30),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    "Medical Tools",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ),

                ListTile(
                  onTap: () {
                    _advancedDrawerController.hideDrawer();
                    // Navigate to search screen
                    Navigator.of(context).push(
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            const SearchScreen(),
                        transitionsBuilder:
                            (context, animation, secondaryAnimation, child) {
                          const begin = Offset(0.0, 1.0);
                          const end = Offset.zero;
                          const curve = Curves.easeOutQuint;

                          var tween = Tween(begin: begin, end: end)
                              .chain(CurveTween(curve: curve));

                          return SlideTransition(
                            position: animation.drive(tween),
                            child: child,
                          );
                        },
                      ),
                    );
                  },
                  leading: const Icon(Icons.search),
                  title: const Text('ICD Search'),
                ),

                ListTile(
                  onTap: () {
                    _advancedDrawerController.hideDrawer();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            const Text('Offline codes feature coming soon'),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  leading: const Icon(Icons.download),
                  title: const Text('Download Offline Data'),
                ),

                // Add to your navigation or drawer menu
                ListTile(
                  leading: Icon(Icons.favorite),
                  title: Text('Support Development'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ContributeToDeveloper()),
                    );
                  },
                ),

                Divider(color: Colors.white30),
                ListTile(
                  onTap: () {
                    // Close the drawer first
                    _advancedDrawerController.hideDrawer();

                    // Show confirmation dialog
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        title: const Text('Sign Out'),
                        content: const Text(
                          'Are you sure you want to sign out?',
                        ),
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
                              // Close the dialog
                              Navigator.pop(context);

                              // Get the auth provider and sign out
                              final authProvider =
                                  Provider.of<AuthStateProvider>(context,
                                      listen: false);
                              authProvider.signOut();

                              // No need to navigate as the Consumer in MyApp will
                              // automatically switch to LoginPage when isAuthenticated is false
                            },
                            child: const Text('Sign Out'),
                          ),
                        ],
                      ),
                    );
                  },
                  leading: const Icon(Icons.logout),
                  title: const Text('Sign Out'),
                ),

                // Contact & About Section
                Divider(color: Colors.white30),

                ListTile(
                  onTap: () {
                    _advancedDrawerController.hideDrawer();
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return Dialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.8,
                              minWidth: 280,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Contact Developer',
                                    style:
                                        Theme.of(context).textTheme.titleLarge,
                                  ),
                                  const SizedBox(height: 16),
                                  Text('Name: Vinayachandra'),
                                  const SizedBox(height: 12),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.email, size: 16),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: SelectableText(
                                          'vinaychandra166@gmail.com',
                                          style: const TextStyle(
                                            decoration:
                                                TextDecoration.underline,
                                            color: Colors.blue,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  // Change this
                                  Wrap(
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      const Icon(Icons.phone, size: 16),
                                      const SizedBox(width: 8),
                                      SelectableText(
                                          '7996336041'), // No Flexible here, which is good
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      child: const Text('Close'),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                  leading: const Icon(Icons.contact_mail),
                  title: const Text('Contact Developer'),
                ),

                ListTile(
                  onTap: () {
                    _advancedDrawerController.hideDrawer();
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text('About ICD-11 Browser'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('ICD-11 Browser'),
                              const SizedBox(height: 8),
                              Text('Version 1.0.0'),
                              const SizedBox(height: 16),
                              Text(
                                  'This application is licensed under GNU General Public License v3.0'),
                              const SizedBox(height: 8),
                              Text('Source available at:',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              SelectableText(
                                  'https://github.com/Vinayy25/ICD-Alar.git'),
                            ],
                          ),
                          actions: <Widget>[
                            TextButton(
                              child: Text('Close'),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                            TextButton(
                              child: Text('View License'),
                              onPressed: () {
                                Navigator.of(context).pop();
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: Text('GNU GPL v3 License'),
                                      content: Container(
                                        width: double.maxFinite,
                                        height: 400,
                                        child: SingleChildScrollView(
                                          child: Text(
                                              'GNU GENERAL PUBLIC LICENSE\n'
                                              'Version 3, 29 June 2007\n\n'
                                              'Copyright (C) 2007 Free Software Foundation, Inc. <https://fsf.org/>\n'
                                              'Everyone is permitted to copy and distribute verbatim copies of this license document, but changing it is not allowed.\n\n'
                                              'This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.\n\n'
                                              'This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.\n\n'
                                              'You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.'),
                                        ),
                                      ),
                                      actions: <Widget>[
                                        TextButton(
                                          child: Text('Close'),
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        );
                      },
                    );
                  },
                  leading: const Icon(Icons.info),
                  title: const Text('About'),
                ),

                // Add padding at the bottom for better spacing
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
      backdrop: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
              Theme.of(context).colorScheme.secondary.withValues(alpha: 0.5),
            ],
          ),
        ),
      ),
      controller: _advancedDrawerController,
      animationCurve: Curves.easeInOut,
      animationDuration: const Duration(milliseconds: 300),
      animateChildDecoration: true,
      rtlOpening: false,
      disabledGestures: false,
      childDecoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8.0,
          ),
        ],
        borderRadius: const BorderRadius.all(Radius.circular(16)),
      ),
      child: Scaffold(
        // Update the appbar to include the drawer toggle button
        appBar: AppBar(
          leading: IconButton(
            onPressed: _handleMenuButtonPressed,
            icon: ValueListenableBuilder<AdvancedDrawerValue>(
              valueListenable: _advancedDrawerController,
              builder: (_, value, __) {
                return AnimatedSwitcher(
                  duration: Duration(milliseconds: 250),
                  child: value.visible
                      ? Icon(Icons.clear, key: ValueKey('close'))
                      : Icon(Icons.menu, key: ValueKey('menu')),
                );
              },
            ),
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('ICD-11 Browser')
                  .animate()
                  .fadeIn(duration: 600.ms)
                  .slideX(begin: -0.1, end: 0),
              AlarLogo(
                isAnimated: true,
                size: 28,
              ),
              const SizedBox(width: 12),
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
          // Remove the clear cache action from app bar since it's now in the drawer
        ),
        // Rest of your existing Scaffold body
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
            return MainScreenChapterListview(
              chapters: chapters,
            );
          },
        ),
        floatingActionButton: FloatingActionSearchButton(
            fabAnimationController: _fabAnimationController,
            fabAnimation: _fabAnimation),

        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBottomNavigationBar.builder(
              itemCount: 2,
              tabBuilder: (int index, bool isActive) {
                final color = isActive
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey.shade400;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      index == 0 ? Icons.home : Icons.file_copy_outlined,
                      size: 24,
                      color: color,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      index == 0 ? "Home" : "Clipboard",
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                      ),
                    ),
                  ],
                );
              },
              activeIndex: _bottomNavIndex,
              gapLocation: GapLocation.center,
              notchSmoothness: NotchSmoothness.verySmoothEdge, // Smoother notch
              leftCornerRadius: 32,
              rightCornerRadius: 32,
              backgroundColor: Theme.of(context).colorScheme.surface,
              onTap: (index) {
                setState(() => _bottomNavIndex = index);

                switch (index) {
                  case 0: // Home
                    _advancedDrawerController.hideDrawer();
                    break;
                  case 1: // feedback
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => ClipboardScreen()));
                    break;
                }
              },
              shadow: BoxShadow(
                offset: const Offset(0, -10),
                blurRadius: 10,
                color: Colors.purple.withValues(alpha: 0.1),
              ),
              splashRadius: 0, // Disable splash effect
              splashColor: Colors.transparent,
              elevation: 16,
            ),
          ],
        ),
      ),
    );
  }

  void _handleMenuButtonPressed() {
    _advancedDrawerController.showDrawer();
  }
}
