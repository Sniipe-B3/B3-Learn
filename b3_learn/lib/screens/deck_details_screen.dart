import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/deck.dart';
import '../providers/flashcard_provider.dart';
import 'create_flashcard_screen.dart';
import 'review_screen.dart';

class DeckDetailsScreen extends ConsumerWidget {
  final Deck deck;
  const DeckDetailsScreen({super.key, required this.deck});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flashcardsAsync = ref.watch(flashcardsStreamProvider(deck.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(deck.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.play_arrow),
            tooltip: 'Lancer la révision',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ReviewScreen(deck: deck),
                ),
              );
            },
          ),
        ],
      ),
      body: flashcardsAsync.when(
        data: (cards) {
          if (cards.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.style, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('Ce paquet est vide.', style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CreateFlashcardScreen(deckId: deck.id),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Ajouter une carte'),
                  )
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: cards.length,
            itemBuilder: (context, index) {
              final card = cards[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('RECTO', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                      if (card.frontImageUrl != null && card.frontImageUrl!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Image.network(
                            card.frontImageUrl!, 
                            height: 150, 
                            width: double.infinity, 
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Text('Erreur de chargement de l\'image (CORS)'),
                          ),
                        ),
                      Text(card.frontText, style: const TextStyle(fontSize: 16)),
                      const Divider(height: 24),
                      const Text('VERSO', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                      if (card.backImageUrl != null && card.backImageUrl!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Image.network(
                            card.backImageUrl!, 
                            height: 150, 
                            width: double.infinity, 
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Text('Erreur de chargement de l\'image (CORS)'),
                          ),
                        ),
                      Text(card.backText, style: const TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Erreur : $e')),
      ),
      floatingActionButton: flashcardsAsync.maybeWhen(
        data: (cards) => cards.isNotEmpty 
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreateFlashcardScreen(deckId: deck.id),
                  ),
                );
              },
              child: const Icon(Icons.add),
            )
          : null,
        orElse: () => null,
      ),
    );
  }
}

