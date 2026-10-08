import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/review_session.dart';

class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Récupérer la session de révision en cours pour un paquet
  Future<ReviewSession?> getActiveSession(String deckId) async {
    final query = await _firestore
        .collection('reviews')
        .where('deckId', isEqualTo: deckId)
        .orderBy('startedAt', descending: true)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      final session = ReviewSession.fromMap(query.docs.first.data(), query.docs.first.id);
      // Si la session n'a plus de cartes restantes, elle est terminée, on ne la renvoie pas
      if (session.remainingCardIds.isNotEmpty) {
        return session;
      }
    }
    return null;
  }

  // Créer une nouvelle session
  Future<ReviewSession> createSession(String deckId, List<String> cardIds) async {
    final newSession = ReviewSession(
      id: '',
      deckId: deckId,
      remainingCardIds: cardIds,
      knownCardIds: [],
      unknownCardIds: [],
      startedAt: DateTime.now(),
    );

    final docRef = await _firestore.collection('reviews').add(newSession.toMap());
    return ReviewSession.fromMap(newSession.toMap(), docRef.id);
  }

  // Mettre à jour la session
  Future<void> updateSession(ReviewSession session) async {
    await _firestore.collection('reviews').doc(session.id).update(session.toMap());
  }
}
