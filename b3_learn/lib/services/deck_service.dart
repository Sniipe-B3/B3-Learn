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
}

