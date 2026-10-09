import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/deck.dart';

class DeckService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Récupérer le flux (stream) de tous les paquets
  Stream<List<Deck>> getDecks() {
    return _firestore.collection('decks')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
        .map((doc) => Deck.fromMap(doc.data(), doc.id))
        .toList());
  }

  // Ajouter un nouveau paquet
  Future<void> addDeck(String title, String description) async {
    final newDeck = Deck(
      id: '', // Firebase s'en chargera
      title: title,
      description: description,
      createdAt: DateTime.now(),
    );
    await _firestore.collection('decks').add(newDeck.toMap());
  }

  // Mettre à jour un paquet
  Future<void> updateDeck(String deckId, String title, String description) async {
    await _firestore.collection('decks').doc(deckId).update({
      'title': title,
      'description': description,
    });
  }

  // Supprimer un paquet
  Future<void> deleteDeck(String deckId) async {
    // 1. Récupérer et supprimer toutes les cartes du paquet
    final flashcards = await _firestore.collection('decks').doc(deckId).collection('flashcards').get();
    for (var doc in flashcards.docs) {
      await doc.reference.delete();
    }
    // 2. Supprimer le paquet lui-même
    await _firestore.collection('decks').doc(deckId).delete();
  }
}
