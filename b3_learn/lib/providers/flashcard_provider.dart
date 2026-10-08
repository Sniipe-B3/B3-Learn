import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/flashcard.dart';
import '../services/flashcard_service.dart';

final flashcardServiceProvider = Provider<FlashcardService>((ref) {
  return FlashcardService();
});

// Utilisation de family pour passer l'ID du paquet en paramètre
final flashcardsStreamProvider = StreamProvider.family<List<Flashcard>, String>((ref, deckId) {
  final flashcardService = ref.watch(flashcardServiceProvider);
  return flashcardService.getFlashcardsForDeck(deckId);
});

