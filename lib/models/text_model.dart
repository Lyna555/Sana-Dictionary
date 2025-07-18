class SanaText {
  final int id;
  final String title;
  final String? author;
  final int? level;
  final String? field;
  final String? photoURL;
  final String? createdAt;
  final String? updatedAt;

  SanaText(
      {required this.id,
      required this.title,
      required this.author,
      required this.level,
      required this.field,
      required this.photoURL,
      required this.createdAt,
      required this.updatedAt});

  factory SanaText.fromJson(Map<String, dynamic> json) {
    return SanaText(
        id: json['id'],
        title: json['title'],
        author: json['author'],
        level: json['level'],
        field: json['field'],
        photoURL: json['photo_url'],
        createdAt: json['createdAt'],
        updatedAt: json['updatedAt']);
  }
}
