class Deck {
  final String id;
  final String title;
  final String description;
  final DateTime createdAt;
  final int order;
  final String userId;
  
  Deck({
    required this.id,
    required this.title,
    this.description = '',
    required this.createdAt,
    this.order = 0,
    required this.userId,
  });

  // Convertir l'objet en Map pour Firebase
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'order': order,
      'userId': userId,
    };
  }

  // Créer un objet Deck à partir d'un Map de Firebase
  factory Deck.fromMap(Map<String, dynamic> map, String documentId) {
    return Deck(
      id: documentId,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt']) 
          : DateTime.now(),
      order: map['order'] ?? 0,
      userId: map['userId'] ?? '',
    );
  }
}
