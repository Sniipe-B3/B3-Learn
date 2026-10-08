class Deck {
  final String id;
  final String title;
  final String description;
  final DateTime createdAt;
  // userId sera ajouté plus tard avec l'authentification
  
  Deck({
    required this.id,
    required this.title,
    this.description = '',
    required this.createdAt,
  });

  // Convertir l'objet en Map pour Firebase
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
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
    );
  }
}

