import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/http.dart';
import 'dart:convert';
import '../models/search_result.dart';

class Chapters extends ChangeNotifier {
  final HttpService _httpService = HttpService();
  Map<String, dynamic>? selectedChapterData;
  String? selectedChapterUrl;
  bool isLoading = false;
  String? error;

  // Replace hardcoded lists with dynamic ones
  List<String> chapterUrls = [];
  bool isInitialized = false;

  // Map to store parent-child relationships
  Map<String, List<String>> hierarchyChain = {};

  // Map to store data for each URL
  Map<String, Map<String, dynamic>> hierarchyData = {};

  // Constructor to initialize data
  Chapters() {
    initializeChapters();
  }

  // Initialize chapters from API
  Future<void> initializeChapters() async {
    if (isInitialized) return;

    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      // First check if we have cached root data
      final prefs = await SharedPreferences.getInstance();
      final rootUrl = "https://id.who.int/icd/release/11/2025-01/mms";
      final cachedRoot = prefs.getString(rootUrl);

      Map<String, dynamic> rootData;

      if (cachedRoot != null) {
        rootData = json.decode(cachedRoot);
      } else {
        // Fetch root data from API
        rootData = await _httpService.getIcdData(rootUrl);
        await prefs.setString(rootUrl, json.encode(rootData));
      }

      // Check if root has children
      if (rootData['child'] != null && rootData['child'] is List) {
        // Set chapter URLs from root's children
        chapterUrls = List<String>.from(rootData['child']);

        // Store hierarchy relationship
        hierarchyChain[rootUrl] = chapterUrls;

        // Store root data
        hierarchyData[rootUrl] = rootData;

        // Preload each chapter's basic data for names
        await Future.wait(chapterUrls.map((chapterUrl) async {
          try {
            if (!hierarchyData.containsKey(chapterUrl)) {
              await _loadAndCacheData(chapterUrl);
            }
          } catch (e) {
            print("Error preloading chapter $chapterUrl: $e");
          }
        }));
      }

      setState(() {
        isLoading = false;
        isInitialized = true;
      });
    } catch (e) {
      print("Error initializing chapters: $e");
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  // Get chapter name from data or provide default
  String getChapterName(int index) {
    if (index >= 0 && index < chapterUrls.length) {
      final url = chapterUrls[index];
      final data = hierarchyData[url];
      if (data != null && data['title'] != null) {
        return data['title']['@value'] ?? 'Chapter ${index + 1}';
      }
    }
    return 'Chapter ${index + 1}';
  }

  Future<void> fetchChapterData(String chapterUrl) async {
    try {
      setState(() {
        isLoading = true;
        error = null;
        selectedChapterUrl = chapterUrl;
      });

      // Level 1: Load current chapter data
      Map<String, dynamic> chapterData;
      if (!hierarchyData.containsKey(chapterUrl)) {
        chapterData = await _loadAndCacheData(chapterUrl);
      } else {
        chapterData = hierarchyData[chapterUrl]!;
      }

      setState(() {
        selectedChapterData = chapterData;
      });

      // Level 2: Load immediate children
      if (chapterData['child'] != null && chapterData['child'] is List) {
        final level1ChildUrls = List<String>.from(chapterData['child']);
        hierarchyChain[chapterUrl] = level1ChildUrls;

        // Load all level 1 children
        await Future.wait(level1ChildUrls.map((childUrl) async {
          if (!hierarchyData.containsKey(childUrl)) {
            final childData = await _loadAndCacheData(childUrl);

            // Level 3: Load grandchildren for each child
            if (childData['child'] != null && childData['child'] is List) {
              final level2ChildUrls = List<String>.from(childData['child']);
              hierarchyChain[childUrl] = level2ChildUrls;

              // Load all level 2 children in parallel
              await Future.wait(level2ChildUrls.map((grandChildUrl) async {
                if (!hierarchyData.containsKey(grandChildUrl)) {
                  await _loadAndCacheData(grandChildUrl);
                }
              }));
            }
          }
        }));
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print("Error in fetchChapterData: $e");
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  // Helper method to load and cache data
  Future<Map<String, dynamic>> _loadAndCacheData(String url) async {
    try {
      // Check SharedPreferences first
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(url);

      if (cachedData != null) {
        final decodedData = json.decode(cachedData);
        setState(() {
          hierarchyData[url] = decodedData;
        });
        return decodedData;
      }

      // Fetch from network if not in cache
      final data = await _httpService.getIcdData(url);
      await saveChapterData(url, data);
      setState(() {
        hierarchyData[url] = data;
      });
      return data;
    } catch (e) {
      print("Error loading data for $url: $e");
      throw e;
    }
  }

  Future<void> preloadData(String url) async {
    if (hierarchyData.containsKey(url)) return;

    try {
      final data = await _httpService.getIcdData(url);
      hierarchyData[url] = data;
      await saveChapterData(url, data);

      if (data['child'] != null) {
        await Future.wait(List<String>.from(data['child'])
            .map((childUrl) => preloadData(childUrl)));
      }
    } catch (e) {
      print("Preload error: $e");
    }
  }

  Future<void> loadChapterData(String url) async {
    selectedChapterUrl = url;
    if (hierarchyData.containsKey(url)) {
      setState(() {
        selectedChapterData = hierarchyData[url];
      });
    }
    // Always fetch to ensure children are loaded
    await fetchChapterData(url);
  }

  Future<void> saveChapterData(
      String chapterUrl, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(chapterUrl, json.encode(data));
    notifyListeners();
  }

  void setState(Function() fn) {
    fn();
    notifyListeners();
  }

  // Add this method to build and get the chain for a specific URL
  Future<List<String>> getHierarchyChain(String url) async {
    List<String> chain = [];
    String currentUrl = url;

    while (currentUrl.isNotEmpty) {
      final data = await loadStoredData(currentUrl);
      if (data == null) break;

      chain.insert(0, currentUrl);

      // Get parent URL if it exists
      final parents = data['parent'] as List<String>?;
      if (parents == null || parents.isEmpty) break;
      currentUrl = parents.first;
    }

    return chain;
  }

  // Helper method to load stored data
  Future<Map<String, dynamic>?> loadStoredData(String url) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(url);

    return data != null ? json.decode(data) : null;
  }

  // Helper method to check if children are loaded
  Future<bool> areChildrenLoaded(String url) async {
    final data = hierarchyData[url];
    if (data == null) return false;

    final children = data['child'] as List<String>?;
    if (children == null) return true;

    for (final childUrl in children) {
      if (!hierarchyData.containsKey(childUrl)) {
        return false;
      }
    }

    return true;
  }

  // Get children for a specific URL
  List<String> getChildrenUrls(String url) {
    return hierarchyChain[url] ?? [];
  }

  // Get data for a specific URL
  Map<String, dynamic>? getDataForUrl(String url) {
    return hierarchyData[url];
  }

  // Helper method to get title for a URL
  String getTitleForUrl(String url) {
    final data = hierarchyData[url];
    if (data == null) return '';
    return data['title']?['@value'] ?? '';
  }

  // Helper method to get classKind for a URL
  String getClassKindForUrl(String url) {
    final data = hierarchyData[url];
    if (data == null) return '';
    return data['classKind'] ?? '';
  }

  // Replace both loadScreenData methods with this unified implementation
  Future<void> loadScreenData(String url) async {
    try {
      setState(() {
        isLoading = true;
        error = null;
        selectedChapterUrl = url;
      });

      print("🔍 Loading screen data for URL: $url");

      // Check if this is a search result URL (contains '&')
      final isSearchResultUrl = url.contains('&');

      if (isSearchResultUrl) {
        print("🔄 Processing search result URL with postcoordination");

        // Parse compound URLs (postcoordination URLs like "url1 & url2")
        final urlParts = url.split(' & ');

        // First load the base entity
        final baseUrl = urlParts[0];
        await _loadEntityData(baseUrl);

        // Then load all referenced entity URLs
        for (int i = 1; i < urlParts.length; i++) {
          await _loadEntityData(urlParts[i]);
        }

        // Combine data if needed (basic implementation)
        if (!hierarchyData.containsKey(url) &&
            hierarchyData.containsKey(baseUrl)) {
          // Copy base data to compound URL
          hierarchyData[url] = Map.from(hierarchyData[baseUrl]!);
          hierarchyData[url]!['isComposed'] = true;
        }

        // Set as current data
        final currentData = hierarchyData[url]!;
        setState(() {
          selectedChapterData = currentData;
        });
      } else {
        // Regular URL handling
        if (!hierarchyData.containsKey(url)) {
          await _loadAndCacheData(url);
        }

        final currentData = hierarchyData[url]!;
        setState(() {
          selectedChapterData = currentData;
        });

        // Then load all its immediate children
        if (currentData['child'] != null && currentData['child'] is List) {
          final childUrls = List<String>.from(currentData['child']);
          hierarchyChain[url] = childUrls;

          print("👨‍👧‍👦 Prefetching ${childUrls.length} child URLs");

          // Load children in parallel (limit to 10 to avoid overloading)
          final childrenToLoad = childUrls.take(10).toList();
          await Future.wait(childrenToLoad.map((childUrl) async {
            if (!hierarchyData.containsKey(childUrl)) {
              final childData = await _loadAndCacheData(childUrl);

              // Also load the first few grandchildren
              if (childData['child'] != null && childData['child'] is List) {
                final grandChildUrls = List<String>.from(childData['child']);
                hierarchyChain[childUrl] = grandChildUrls;

                // Load a limited number of grandchildren
                final grandChildrenToLoad = grandChildUrls.take(5).toList();
                await Future.wait(
                    grandChildrenToLoad.map((grandChildUrl) async {
                  if (!hierarchyData.containsKey(grandChildUrl)) {
                    await _loadAndCacheData(grandChildUrl);
                  }
                }));
              }
            }
          }));
        }
      }
    } catch (e, stackTrace) {
      print("❌ Error loading screen data: $e");
      print("🔍 Stack trace: $stackTrace");
      setState(() {
        error = 'Failed to load data: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Add this method to your Chapters class
  Future<Map<String, dynamic>?> loadItemData(String url) async {
    try {
      if (hierarchyData.containsKey(url)) {
        return hierarchyData[url];
      }

      final data = await _loadAndCacheData(url);
      return data;
    } catch (e) {
      print("Error loading item data: $e");
      return null;
    }
  }

  // Add the following properties to your Chapters class
  SearchResult searchResults = SearchResult.empty();
  bool isSearching = false;
  String searchQuery = '';

  // Add these methods to your Chapters class
  Future<void> searchIcd(String query) async {
    if (query.isEmpty) {
      searchResults = SearchResult.empty();
      notifyListeners();
      return;
    }

    try {
      setState(() {
        isSearching = true;
        searchQuery = query;
        error = null;
      });

      print("🔍 Searching for: $query");
      final result = await _httpService.searchIcd(query: query);

      // Handle error responses from our modified HTTP service
      if (result['error'] == true) {
        print("⚠️ Search returned with error: ${result['errorMessage']}");
        setState(() {
          // Create an empty search result but with error info
          searchResults = SearchResult(
            entities: [],
            hasError: true,
            errorMessage: result['errorMessage'] as String?,
            resultChopped: false,
            suggestedWords: [],
            uniqueSearchId: '',
          );
          error = result['errorMessage'] as String?;
        });
        return;
      }

      // Normal processing continues...
      searchResults = SearchResult.fromJson(result);
      print("🔢 Found ${searchResults.entities.length} search results");

      // Cache results
      for (final entity in searchResults.entities) {
        if (!hierarchyData.containsKey(entity.id)) {
          hierarchyData[entity.id] = {
            'title': {'@value': entity.plainTitle},
            'code': entity.code,
            'classKind':
                entity.isPostcoordination ? 'postcoordination' : 'category',
          };
        }
      }
    } catch (e, stackTrace) {
      print("🚨 Search error: $e");
      print("🔍 Stack trace: $stackTrace");
      setState(() {
        error = 'Failed to search: $e';
        searchResults = SearchResult.empty();
      });
    } finally {
      setState(() {
        isSearching = false;
      });
    }
  }

  void clearSearch() {
    try {
      setState(() {
        searchResults = SearchResult.empty();
        searchQuery = '';
        isSearching = false;
      });
    } catch (e) {
      print("Error in clearSearch: $e");
    }
  }

  // Helper method to load a single entity
  Future<Map<String, dynamic>?> _loadEntityData(String url) async {
    try {
      // Check cache first
      if (hierarchyData.containsKey(url)) {
        return hierarchyData[url];
      }

      // Not in cache, need to fetch
      print("🌐 Fetching entity data: $url");
      final data = await _httpService.getIcdData(url);

      // Store in cache
      hierarchyData[url] = data;

      // Return the data
      return data;
    } catch (e) {
      print("⚠️ Error loading entity data for $url: $e");
      return null;
    }
  }
}
