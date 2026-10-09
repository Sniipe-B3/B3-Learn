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

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Options de révision'),
                        content: const Text('Comment souhaitez-vous réviser ces cartes ?'),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context); // Fermer la modale
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ReviewScreen(deck: deck, shuffle: false),
                                ),
                              );
                            },
                            child: const Text('Dans l\'ordre'),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber,
                              foregroundColor: Colors.black,
                            ),
                            onPressed: () {
                              Navigator.pop(context); // Fermer la modale
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ReviewScreen(deck: deck, shuffle: true),
                                ),
                              );
                            },
                            child: const Text('Aléatoire'),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.play_circle_fill),
                  label: const Text('LANCER LA RÉVISION', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('RECTO', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, size: 20),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => CreateFlashcardScreen(deckId: deck.id, cardToEdit: card),
                                          ),
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                      onPressed: () async {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('Supprimer la carte ?'),
                                            content: const Text('Cette action est irréversible.'),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(context, false),
                                                child: const Text('Annuler'),
                                              ),
                                              TextButton(
                                                onPressed: () => Navigator.pop(context, true),
                                                child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
                                              ),
                                            ],
                                          ),
                                        );

                                        if (confirm == true) {
                                          try {
                                            await ref.read(flashcardServiceProvider).deleteFlashcard(deck.id, card.id);
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Carte supprimée')),
                                              );
                                            }
                                          } catch (e) {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('Erreur: $e')),
                                              );
                                            }
                                          }
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
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
                ),
              ),
            ],
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
