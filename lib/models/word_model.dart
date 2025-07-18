class SanaWord {
  final int id;
  final String word;
  final String explanation;
  final String example;
  final int textId;
  final String? createdAt;
  final String? updatedAt;

  SanaWord(
      {required this.id,
        required this.word,
        required this.explanation,
        required this.example,
        required this.textId,
        required this.createdAt,
        required this.updatedAt});

  factory SanaWord.fromJson(Map<String, dynamic> json) {
    return SanaWord(
        id: json['id'],
        word: json['word'],
        explanation: json['explanation'],
        example: json['example'],
        textId: json['text_id'],
        createdAt: json['createdAt'],
        updatedAt: json['updatedAt']);
  }
}
