class IcdDataModel {
  final String context;
  final String id;
  final List<String>? parent;
  final List<String>? child;
  final String browserUrl;
  final String code;
  final String source;
  final String classKind;
  final IcdLocalizedText title;
  final IcdLocalizedText? definition;
  final List<FoundationItem>? foundationChildElsewhere;
  final List<ExclusionItem>? exclusion;

  IcdDataModel({
    required this.context,
    required this.id,
    this.parent,
    this.child,
    required this.browserUrl,
    required this.code,
    required this.source,
    required this.classKind,
    required this.title,
    this.definition,
    this.foundationChildElsewhere,
    this.exclusion,
  });

  factory IcdDataModel.fromJson(Map<String, dynamic> json) {
    return IcdDataModel(
      context: json['@context'] ?? '',
      id: json['@id'] ?? '',
      parent: json['parent'] != null ? List<String>.from(json['parent']) : null,
      child: json['child'] != null ? List<String>.from(json['child']) : null,
      browserUrl: json['browserUrl'] ?? '',
      code: json['code'] ?? '',
      source: json['source'] ?? '',
      classKind: json['classKind'] ?? '',
      title: IcdLocalizedText.fromJson(json['title']),
      definition: json['definition'] != null
          ? IcdLocalizedText.fromJson(json['definition'])
          : null,
      foundationChildElsewhere: json['foundationChildElsewhere'] != null
          ? (json['foundationChildElsewhere'] as List)
              .map((e) => FoundationItem.fromJson(e))
              .toList()
          : null,
      exclusion: json['exclusion'] != null
          ? (json['exclusion'] as List)
              .map((e) => ExclusionItem.fromJson(e))
              .toList()
          : null,
    );
  }
}

class IcdLocalizedText {
  final String language;
  final String value;

  IcdLocalizedText({
    required this.language,
    required this.value,
  });

  factory IcdLocalizedText.fromJson(Map<String, dynamic> json) {
    return IcdLocalizedText(
      language: json['@language'] ?? '',
      value: json['@value'] ?? '',
    );
  }
}

class FoundationItem {
  final IcdLocalizedText? label;
  final String foundationReference;
  final String linearizationReference;

  FoundationItem({
    this.label,
    required this.foundationReference,
    required this.linearizationReference,
  });

  factory FoundationItem.fromJson(Map<String, dynamic> json) {
    return FoundationItem(
      label: json['label'] != null
          ? IcdLocalizedText.fromJson(json['label'])
          : null,
      foundationReference: json['foundationReference'] ?? '',
      linearizationReference: json['linearizationReference'] ?? '',
    );
  }
}

class ExclusionItem {
  final IcdLocalizedText? label;
  final String? foundationReference;
  final String? linearizationReference;

  ExclusionItem({
    this.label,
    this.foundationReference,
    this.linearizationReference,
  });

  factory ExclusionItem.fromJson(Map<String, dynamic> json) {
    return ExclusionItem(
      label: json['label'] != null
          ? IcdLocalizedText.fromJson(json['label'])
          : null,
      foundationReference: json['foundationReference'],
      linearizationReference: json['linearizationReference'],
    );
  }
}
