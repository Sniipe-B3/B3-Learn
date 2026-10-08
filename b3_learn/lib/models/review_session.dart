class ReviewSession {
  final String id;
  final String deckId;
  final List<String> remainingCardIds;
  final List<String> knownCardIds; // Swiped Right
  final List<String> unknownCardIds; // Swiped Left
  final DateTime startedAt;

  ReviewSession({
    required this.id,
    required this.deckId,
    required this.remainingCardIds,
    required this.knownCardIds,
    required this.unknownCardIds,
    required this.startedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'deckId': deckId,
      'remainingCardIds': remainingCardIds,
      'knownCardIds': knownCardIds,
      'unknownCardIds': unknownCardIds,
      'startedAt': startedAt.toIso8601String(),
    };
  }

  factory ReviewSession.fromMap(Map<String, dynamic> map, String documentId) {
    return ReviewSession(
      id: documentId,
      deckId: map['deckId'] ?? '',
      remainingCardIds: List<String>.from(map['remainingCardIds'] ?? []),
      knownCardIds: List<String>.from(map['knownCardIds'] ?? []),
      unknownCardIds: List<String>.from(map['unknownCardIds'] ?? []),
      startedAt: map['startedAt'] != null 
          ? DateTime.parse(map['startedAt']) 
          : DateTime.now(),
    );
  }
}
