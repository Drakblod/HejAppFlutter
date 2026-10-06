Map<String, dynamic> ratingMap(dynamic value) => value is Map
    ? value.map((key, value) => MapEntry(key.toString(), value))
    : {};
List<Map<String, dynamic>> ratingDefinitions(dynamic value) =>
    value is List ? value.map(ratingMap).toList() : [];

class RatingConfig {
  final Map<String, dynamic> json;
  RatingConfig(Map<String, dynamic> value)
    : json = {
        ...value,
        'criteria': ratingDefinitions(value['criteria']),
        'metadataFields': ratingDefinitions(value['metadataFields']),
      };
  String get title => json['title'] as String;
  String get itemTypeName => json['itemTypeName'] as String;
  String get primaryLabel => json['primaryLabel'] as String;
  num get min => json['min'] as num;
  num get max => json['max'] as num;
  int get revision => (json['revision'] as num?)?.toInt() ?? 0;
  bool get showSummary => json['showSummary'] == true;
  List<Map<String, dynamic>> get criteria =>
      ratingDefinitions(json['criteria']);
  List<Map<String, dynamic>> get fields =>
      ratingDefinitions(json['metadataFields']);
}

class RatingReview {
  final Map<String, dynamic> json;
  RatingReview(this.json);
  String? get userId => json['userId'] as String?;
  num? get primaryRating => json['primaryRating'] as num?;
  Map<String, dynamic> get criteria => ratingMap(json['criterionRatings']);
  String get comment => json['comment'] as String? ?? '';
  int get updatedAt => (json['updatedAt'] as num?)?.toInt() ?? 0;
}

class RatingItem {
  final Map<String, dynamic> json;
  RatingItem(this.json);
  String get id => json['id'] as String;
  String get title => json['title'] as String;
  String get creatorId => json['creatorId'] as String;
  String? get imageUrl => json['imageUrl'] as String?;
  int get version => (json['version'] as num?)?.toInt() ?? 0;
  int get updatedAt => (json['updatedAt'] as num?)?.toInt() ?? 0;
  int get createdAt => (json['createdAt'] as num?)?.toInt() ?? 0;
  Map<String, dynamic> get metadata => ratingMap(json['metadataValues']);
  Map<String, RatingReview> get reviews => ratingMap(
    json['reviews'],
  ).map((id, value) => MapEntry(id, RatingReview(ratingMap(value))));
  num? get score => _mean(reviews.values.map((r) => r.primaryRating));
  num? criterionScore(String id) =>
      _mean(reviews.values.map((r) => r.criteria[id] as num?));
  int get ratingCount =>
      reviews.values.where((r) => r.primaryRating != null).length;
  static num? _mean(Iterable<num?> values) {
    final present = values.whereType<num>().toList();
    return present.isEmpty
        ? null
        : present.reduce((a, b) => a + b) / present.length;
  }
}

class RatingArchive {
  final RatingConfig? config;
  final List<RatingItem> items;
  final bool canConfigure;
  final String userId;
  RatingArchive({
    required this.config,
    required this.items,
    required this.canConfigure,
    required this.userId,
  });
  factory RatingArchive.fromJson(Map<String, dynamic> value) {
    final module = ratingMap(value['module']);
    return RatingArchive(
      config: module['config'] == null
          ? null
          : RatingConfig(ratingMap(module['config'])),
      items: ratingMap(module['items']).entries
          .map((e) => RatingItem({...ratingMap(e.value), 'id': e.key}))
          .toList(),
      canConfigure: value['canConfigure'] == true,
      userId: value['userId'] as String,
    );
  }
  List<RatingItem> get ranked => [...items]
    ..sort((a, b) {
      if (a.score == null && b.score != null) return 1;
      if (b.score == null && a.score != null) return -1;
      final scoreOrder = (b.score ?? 0).compareTo(a.score ?? 0);
      return scoreOrder == 0 ? a.title.compareTo(b.title) : scoreOrder;
    });
  List<RatingItem> get topThree =>
      ranked.where((i) => i.score != null).take(3).toList();
  RatingItem? get latest => items.isEmpty
      ? null
      : ([...items]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt))).first;
  RatingItem? highlight(String criterionId) {
    final rated =
        items.where((i) => i.criterionScore(criterionId) != null).toList()
          ..sort(
            (a, b) => b
                .criterionScore(criterionId)!
                .compareTo(a.criterionScore(criterionId)!),
          );
    return rated.firstOrNull;
  }
}

String ratingScore(num? value) => value == null
    ? 'Ej betygsatt'
    : value.toStringAsFixed(1).replaceAll('.', ',');
String metadataDisplay(Map<String, dynamic> field, dynamic value) {
  if (value == null) return 'Ej angivet';
  if (value is bool) return value ? 'Ja' : 'Nej';
  return field['type'] == 'currency' ? '$value ${field['currency']}' : '$value';
}
