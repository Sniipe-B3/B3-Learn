import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/deck.dart';

class DeckService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Récupérer le flux (stream) de tous les paquets
  Stream<List<Deck>> getDecks() {
    return _firestore.collection('decks')
      .snapshots()
      .map((snapshot) {
        final decks = snapshot.docs
          .map((doc) => Deck.fromMap(doc.data(), doc.id))
          .toList();
        
        decks.sort((a, b) {
          if (a.order != b.order) {
            return a.order.compareTo(b.order);
          }
          return a.createdAt.compareTo(b.createdAt);
        });
        
        return decks;
      });
  }

  // Ajouter un nouveau paquet
  Future<void> addDeck(String title, String description) async {
    final newDeck = Deck(
      id: '',
      title: title,
      description: description,
      createdAt: DateTime.now(),
      order: DateTime.now().millisecondsSinceEpoch, // Toujours à la fin
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
  
  // Réordonner les paquets
  Future<void> updateDecksOrder(List<Deck> decks) async {
    final batch = _firestore.batch();
    for (int i = 0; i < decks.length; i++) {
      final ref = _firestore.collection('decks').doc(decks[i].id);
      batch.update(ref, {'order': i});
    }
    await batch.commit();
  }

  // Supprimer un paquet
  Future<void> deleteDeck(String deckId) async {
    final flashcards = await _firestore.collection('decks').doc(deckId).collection('flashcards').get();
    for (var doc in flashcards.docs) {
      await doc.reference.delete();
    }
    await _firestore.collection('decks').doc(deckId).delete();
  }
}
