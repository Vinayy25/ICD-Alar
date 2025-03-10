import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class ClipboardItem {
  final String code;
  final String description;
  final DateTime timestamp;
  final String? category;

  ClipboardItem({
    required this.code,
    required this.description,
    required this.timestamp,
    this.category,
  });

  // Convert to JSON
  Map<String, dynamic> toJson() => {
        'code': code,
        'description': description,
        'timestamp': timestamp.toIso8601String(),
        'category': category,
      };

  // Create from JSON
  factory ClipboardItem.fromJson(Map<String, dynamic> json) {
    return ClipboardItem(
      code: json['code'],
      description: json['description'],
      timestamp: DateTime.parse(json['timestamp']),
      category: json['category'],
    );
  }
}



class ClipboardService {
  static const _storageKey = 'clipboard_items';

  // Add an item to clipboard
  static Future<void> addItem(ClipboardItem item) async {
    final prefs = await SharedPreferences.getInstance();
    final items = await getItems();

    // Check if item already exists to prevent duplicates
    if (!items.any((existing) => existing.code == item.code)) {
      items.add(item);
      final jsonList = items.map((item) => jsonEncode(item.toJson())).toList();
      await prefs.setStringList(_storageKey, jsonList);
    }
  }

  // Get all items
  static Future<List<ClipboardItem>> getItems() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_storageKey) ?? [];

    return jsonList
        .map((json) {
          try {
            return ClipboardItem.fromJson(jsonDecode(json));
          } catch (e) {
            print('Error parsing clipboard item: $e');
            return null;
          }
        })
        .whereType<ClipboardItem>()
        .toList();
  }

  // Remove an item
  static Future<void> removeItem(String code) async {
    final prefs = await SharedPreferences.getInstance();
    final items = await getItems();
    items.removeWhere((item) => item.code == code);

    final jsonList = items.map((item) => jsonEncode(item.toJson())).toList();
    await prefs.setStringList(_storageKey, jsonList);
  }

  // Clear all items
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
