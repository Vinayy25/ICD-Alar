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

  Future<void> fetchChapterData(String chapterUrl) async {
    try {
      setState(() {
        isLoading = true;
        error = null;
        selectedChapterUrl = chapterUrl;
      });

      // Use the HttpService to fetch data for the specific chapter URL
      final chapterData = await _httpService.getIcdData(chapterUrl);

      setState(() {
        selectedChapterData = chapterData;
        isLoading = false;
      });

      // Save the fetched data locally
      await saveChapterData(chapterUrl, chapterData);
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> saveChapterData(
      String chapterUrl, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(chapterUrl, json.encode(data));
  }

  Future<void> loadChapterData(String chapterUrl) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(chapterUrl);
    if (data != null) {
      setState(() {
        selectedChapterData = json.decode(data);
        print('Loaded data from cache' +
            selectedChapterData.toString() +
            "title " +
            selectedChapterData!['title']?['@value']);

        selectedChapterUrl = chapterUrl;
      });
    } else {
      fetchChapterData(chapterUrl);
    }
  }

  void setState(Function() fn) {
    fn();
    notifyListeners();
  }
}
