import 'package:flutter/material.dart';
import 'package:html/parser.dart' as htmlParser;

class SearchResultEntity {
  final String id;
  final String title;
  final String code;
  final String stemId;
  final bool isLeaf;
  final String chapterCode;
  final double score;
  final bool isImportant;
  final int entityType; // 0 for normal entry, 1 for postcoordination result
  final List<MatchingProperty> matchingProperties;
  final bool titleIsSearchResult;
  final bool isResidualOther;
  final bool isResidualUnspecified;
  final int postcoordinationAvailability;

  SearchResultEntity({
    required this.id,
    required this.title,
    required this.code,
    required this.stemId,
    required this.isLeaf,
    required this.chapterCode,
    required this.score,
    required this.isImportant,
    required this.entityType,
    required this.matchingProperties,
    required this.titleIsSearchResult,
    required this.isResidualOther,
    required this.isResidualUnspecified,
    required this.postcoordinationAvailability,
  });

  factory SearchResultEntity.fromJson(Map<String, dynamic> json) {
    List<MatchingProperty> matchingProps = [];
    if (json['matchingPVs'] != null) {
      matchingProps = List<MatchingProperty>.from((json['matchingPVs'] as List)
          .map((x) => MatchingProperty.fromJson(x)));
    }

    // Check if ID contains '&' to identify postcoordination results
    final id = json['id'] as String? ?? '';
    final isPostcoordination = id.contains('&');

    return SearchResultEntity(
      id: id,
      title: json['title'] ?? '',
      code: json['theCode'] ?? '',
      stemId: json['stemId'] ?? '',
      isLeaf: json['isLeaf'] ?? false,
      chapterCode: json['chapter'] ?? '',
      score: json['score'] ?? 0.0,
      isImportant: json['important'] ?? false,
      entityType: isPostcoordination ? 1 : (json['entityType'] ?? 0),
      matchingProperties: matchingProps,
      titleIsSearchResult: json['titleIsASearchResult'] ?? false,
      isResidualOther: json['isResidualOther'] ?? false,
      isResidualUnspecified: json['isResidualUnspecified'] ?? false,
      postcoordinationAvailability: json['postcoordinationAvailability'] ?? 0,
    );
  }

  // Helper to get plain text title without HTML markup
  String get plainTitle {
    final document = htmlParser.parse(title);
    return document.body?.text ?? title;
  }

  // Helper to check if this is a postcoordination result
  bool get isPostcoordination => entityType == 1;
}

class MatchingProperty {
  final String propertyId;
  final String label;
  final double score;
  final bool isImportant;
  final String? foundationUri;
  final int propertyValueType;

  MatchingProperty({
    required this.propertyId,
    required this.label,
    required this.score,
    required this.isImportant,
    this.foundationUri,
    required this.propertyValueType,
  });

  factory MatchingProperty.fromJson(Map<String, dynamic> json) {
    return MatchingProperty(
      propertyId: json['propertyId'] ?? '',
      label: json['label'] ?? '',
      score: json['score'] ?? 0.0,
      isImportant: json['important'] ?? false,
      foundationUri: json['foundationUri'],
      propertyValueType: json['propertyValueType'] ?? 0,
    );
  }
}

class SearchResult {
  final List<SearchResultEntity> entities;
  final bool hasError;
  final String? errorMessage;
  final bool resultChopped;
  final List<String> suggestedWords;
  final String uniqueSearchId;

  SearchResult({
    required this.entities,
    required this.hasError,
    this.errorMessage,
    required this.resultChopped,
    required this.suggestedWords,
    required this.uniqueSearchId,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    print("🔄 Processing search result JSON");

    List<SearchResultEntity> entities = [];
    if (json.containsKey('destinationEntities') &&
        json['destinationEntities'] != null) {
      try {
        final destinationEntities = json['destinationEntities'] as List;
        print("📋 Found ${destinationEntities.length} destination entities");

        entities = destinationEntities
            .map((x) {
              try {
                return SearchResultEntity.fromJson(x);
              } catch (e) {
                print("⚠️ Error parsing entity: $e");
                print("📑 Entity data: $x");
                return null;
              }
            })
            .whereType<SearchResultEntity>()
            .toList();

        print("✅ Successfully parsed ${entities.length} entities");
      } catch (e) {
        print("❌ Error parsing entities list: $e");
      }
    } else {
      print("❌ Missing 'destinationEntities' in JSON");
    }

    List<String> words = [];
    if (json.containsKey('words') && json['words'] != null) {
      try {
        words =
            (json['words'] as List).map((x) => x['label'] as String).toList();
        print("📝 Found ${words.length} suggested words");
      } catch (e) {
        print("⚠️ Error parsing words: $e");
      }
    }

    return SearchResult(
      entities: entities,
      hasError: json['error'] ?? false,
      errorMessage: json['errorMessage'],
      resultChopped: json['resultChopped'] ?? false,
      suggestedWords: words,
      uniqueSearchId: json['uniqueSearchId'] ?? '',
    );
  }

  factory SearchResult.empty() {
    return SearchResult(
      entities: [],
      hasError: false,
      resultChopped: false,
      suggestedWords: [],
      uniqueSearchId: '',
    );
  }
}
