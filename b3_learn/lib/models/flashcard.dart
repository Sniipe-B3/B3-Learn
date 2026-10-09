class Flashcard {
  final String id;
  final String deckId;
  final String frontText;
  final String? frontImageUrl;
  final String backText;
  final String? backImageUrl;
  final DateTime createdAt;
  final int order;

  Flashcard({
    required this.id,
    required this.deckId,
    required this.frontText,
    this.frontImageUrl,
    required this.backText,
    this.backImageUrl,
    required this.createdAt,
    this.order = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'deckId': deckId,
      'frontText': frontText,
      'frontImageUrl': frontImageUrl,
      'backText': backText,
      'backImageUrl': backImageUrl,
      'createdAt': createdAt.toIso8601String(),
      'order': order,
    };
  }

  factory Flashcard.fromMap(Map<String, dynamic> map, String documentId) {
    return Flashcard(
      id: documentId,
      deckId: map['deckId'] ?? '',
      frontText: map['frontText'] ?? '',
      frontImageUrl: map['frontImageUrl'],
      backText: map['backText'] ?? '',
      backImageUrl: map['backImageUrl'],
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt']) 
          : DateTime.now(),
      order: map['order'] ?? 0,
    );
  }
}
