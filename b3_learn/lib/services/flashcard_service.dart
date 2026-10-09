import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../models/flashcard.dart';

class FlashcardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Récupérer les cartes d'un paquet spécifique
  Stream<List<Flashcard>> getFlashcardsForDeck(String deckId) {
    return _firestore
        .collection('decks')
        .doc(deckId)
        .collection('flashcards')
        .snapshots()
        .map((snapshot) {
          final cards = snapshot.docs
              .map((doc) => Flashcard.fromMap(doc.data(), doc.id))
              .toList();
          
          cards.sort((a, b) {
            if (a.order != b.order) {
              return a.order.compareTo(b.order);
            }
            return a.createdAt.compareTo(b.createdAt);
          });
          
          return cards;
        });
  }
  
  // Uploader une image dans Firebase Storage
  Future<String> uploadImage(String deckId, Uint8List imageBytes, String fileName) async {
    final ref = _storage.ref().child('flashcards/$deckId/${DateTime.now().millisecondsSinceEpoch}_$fileName');
    final uploadTask = ref.putData(imageBytes);
    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  // Ajouter une nouvelle carte dans un paquet
  Future<void> addFlashcard({
    required String deckId,
    required String frontText,
    String? frontImageUrl,
    required String backText,
    String? backImageUrl,
  }) async {
    final newCard = Flashcard(
      id: '',
      deckId: deckId,
      frontText: frontText,
      frontImageUrl: frontImageUrl,
      backText: backText,
      backImageUrl: backImageUrl,
      createdAt: DateTime.now(),
      order: DateTime.now().millisecondsSinceEpoch,
    );

    await _firestore
        .collection('decks')
        .doc(deckId)
        .collection('flashcards')
        .add(newCard.toMap());
  }

  // Mettre à jour une carte
  Future<void> updateFlashcard({
    required String deckId,
    required String flashcardId,
    required String frontText,
    String? frontImageUrl,
    required String backText,
    String? backImageUrl,
  }) async {
    await _firestore
        .collection('decks')
        .doc(deckId)
        .collection('flashcards')
        .doc(flashcardId)
        .update({
      'frontText': frontText,
      'frontImageUrl': frontImageUrl,
      'backText': backText,
      'backImageUrl': backImageUrl,
    });
  }
  
  // Réordonner les cartes
  Future<void> updateFlashcardsOrder(String deckId, List<Flashcard> cards) async {
    final batch = _firestore.batch();
    for (int i = 0; i < cards.length; i++) {
      final ref = _firestore.collection('decks').doc(deckId).collection('flashcards').doc(cards[i].id);
      batch.update(ref, {'order': i});
    }
    await batch.commit();
  }

  // Supprimer une carte
  Future<void> deleteFlashcard(String deckId, String flashcardId) async {
    await _firestore
        .collection('decks')
        .doc(deckId)
        .collection('flashcards')
        .doc(flashcardId)
        .delete();
  }
}
