import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/deck.dart';
import '../services/deck_service.dart';
import 'auth_provider.dart';

// Provider pour le service Firebase
final deckServiceProvider = Provider<DeckService>((ref) {
  final user = ref.watch(authStateProvider).value;
  return DeckService(userId: user?.uid);
});

// StreamProvider pour écouter en temps réel la liste des paquets
final decksStreamProvider = StreamProvider<List<Deck>>((ref) {
  final deckService = ref.watch(deckServiceProvider);
  return deckService.getDecks();
});

