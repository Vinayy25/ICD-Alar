import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/http.dart';
import 'dart:convert';

class Chapters extends ChangeNotifier {
  final HttpService _httpService = HttpService();
  Map<String, dynamic>? selectedChapterData;
  String? selectedChapterUrl;
  bool isLoading = false;
  String? error;

  List<String> chapterUrls = [
    "http://id.who.int/icd/release/11/2019-04/mms/21500692",
    "http://id.who.int/icd/release/11/2019-04/mms/1630407678",
    "http://id.who.int/icd/release/11/2019-04/mms/1766440644",
    "http://id.who.int/icd/release/11/2019-04/mms/1954798891",
    "http://id.who.int/icd/release/11/2019-04/mms/1435254666",
    "http://id.who.int/icd/release/11/2019-04/mms/334423054",
    "http://id.who.int/icd/release/11/2019-04/mms/274880002",
    "http://id.who.int/icd/release/11/2019-04/mms/1296093776",
    "http://id.who.int/icd/release/11/2019-04/mms/868865918",
    "http://id.who.int/icd/release/11/2019-04/mms/1218729044",
    "http://id.who.int/icd/release/11/2019-04/mms/426429380",
    "http://id.who.int/icd/release/11/2019-04/mms/197934298",
    "http://id.who.int/icd/release/11/2019-04/mms/1256772020",
    "http://id.who.int/icd/release/11/2019-04/mms/1639304259",
    "http://id.who.int/icd/release/11/2019-04/mms/1473673350",
    "http://id.who.int/icd/release/11/2019-04/mms/30659757",
    "http://id.who.int/icd/release/11/2019-04/mms/577470983",
    "http://id.who.int/icd/release/11/2019-04/mms/714000734",
    "http://id.who.int/icd/release/11/2019-04/mms/1306203631",
    "http://id.who.int/icd/release/11/2019-04/mms/223744320",
    "http://id.who.int/icd/release/11/2019-04/mms/1843895818",
    "http://id.who.int/icd/release/11/2019-04/mms/435227771",
    "http://id.who.int/icd/release/11/2019-04/mms/850137482",
    "http://id.who.int/icd/release/11/2019-04/mms/1249056269",
    "http://id.who.int/icd/release/11/2019-04/mms/1596590595",
    "http://id.who.int/icd/release/11/2019-04/mms/718687701",
    "http://id.who.int/icd/release/11/2019-04/mms/231358748",
    "http://id.who.int/icd/release/11/2019-04/mms/979408586",
  ];

  List<String> chapterNames = [
    "Chapter 1",
    "Chapter 2",
    "Chapter 3",
    "Chapter 4",
    "Chapter 5",
    "Chapter 6",
    "Chapter 7",
    "Chapter 8",
    "Chapter 9",
    "Chapter 10",
    "Chapter 11",
    "Chapter 12",
    "Chapter 13",
    "Chapter 14",
    "Chapter 15",
    "Chapter 16",
    "Chapter 17",
    "Chapter 18",
    "Chapter 19",
    "Chapter 20",
    "Chapter 21",
    "Chapter 22",
    "Chapter 23",
    "Chapter 24",
    "Chapter 25",
    "Chapter 26",
    "Chapter 27",
    "Chapter 28",
  ];

  Map<String, List<String>> hierarchyChain =
      {}; // Stores parent-child relationships
  Map<String, Map<String, dynamic>> hierarchyData =
      {}; // Stores data for each URL

  Future<void> fetchChapterData(String chapterUrl) async {
    // Check if data is already in hierarchyData
    if (hierarchyData.containsKey(chapterUrl)) {
      setState(() {
        selectedChapterData = hierarchyData[chapterUrl];
        isLoading = false;
      });
      return;
    }

    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      // Check SharedPreferences first
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(chapterUrl);

      if (cachedData != null) {
        final decodedData = json.decode(cachedData);
        hierarchyData[chapterUrl] = decodedData;
        setState(() {
          selectedChapterData = decodedData;
          isLoading = false;
        });
      } else {
        // Fetch from network if not cached
        final chapterData = await _httpService.getIcdData(chapterUrl);
        await saveChapterData(chapterUrl, chapterData);
        hierarchyData[chapterUrl] = chapterData;
        setState(() {
          selectedChapterData = chapterData;
          isLoading = false;
        });
      }

      // Recursively fetch children if needed
      if (selectedChapterData!['child'] != null) {
        final children = List<String>.from(selectedChapterData!['child']);
        await Future.wait(children.map((url) => preloadData(url)));
      }
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
    notifyListeners();
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
    if (hierarchyData.containsKey(url)) {
      setState(() {
        selectedChapterData = hierarchyData[url];
      });
      notifyListeners();
      return;
    }
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
}
