import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/deck_provider.dart';
import 'create_deck_screen.dart';
import 'deck_details_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  void _showReleaseNotes(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notes de version'),
          content: const SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('✨ V 1.3 (Actuelle)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber)),
                SizedBox(height: 4),
                Text('- Ajout de l\'édition de paquets et de cartes (CRUD).'),
                Text('- Ajout de la suppression de paquets et de cartes.'),
                Text('- Ajout d\'une animation de chargement PWA personnalisée.'),
                Divider(height: 24),
                Text('📦 V 1.2.1', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                SizedBox(height: 4),
                Text('- Correction: Bouton Play bien visible dans les paquets.'),
                Text('- Correction: Animation de retournement de la carte (Flip).'),
                Text('- Correction: Les cartes "à revoir" (swipe gauche) reviennent en boucle tant qu\'elles ne sont pas connues.'),
                Divider(height: 24),
                Text('📦 V 1.2', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                SizedBox(height: 4),
                Text('- Ajout du mode Révision complet !'),
                Text('- Système de Swipe (Type Tinder) sur les cartes.'),
                Text('- Glisser à Droite (Connu) / Gauche (À revoir).'),
                Text('- Sauvegarde intelligente de la progression (reprise plus tard).'),
                Divider(height: 24),
                Text('📦 V 1.1', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                SizedBox(height: 4),
                Text('- Ajout du système de cartes (Flashcards).'),
                Text('- Possibilité d\'ajouter des photos (Recto/Verso).'),
                Text('- Interface de visualisation des paquets.'),
                Divider(height: 24),
                Text('📦 V 1.0', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                SizedBox(height: 4),
                Text('- Thème sombre intégral.'),
                Text('- Création de paquets de cartes (titre & description).'),
                Text('- Sauvegarde en temps réel sur Firebase (Firestore).'),
                Text('- Application PWA installable.'),
              ],
            ),
          ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final decksAsyncValue = ref.watch(decksStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('B3-Learn - Mes Paquets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.new_releases),
            tooltip: 'Notes de version',
            onPressed: () => _showReleaseNotes(context),
          ),
        ],
      ),
      body: decksAsyncValue.when(
        data: (decks) {
          if (decks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.style, size: 64, color: Colors.deepPurpleAccent),
                  const SizedBox(height: 16),
                  const Text(
                    'Bienvenue sur B3-Learn',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('Vos paquets de cartes apparaîtront ici.'),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CreateDeckScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Créer mon premier paquet'),
                  )
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: decks.length,
            itemBuilder: (context, index) {
              final deck = decks[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.deepPurple,
                    child: Icon(Icons.style, color: Colors.white),
                  ),
                  title: Text(
                    deck.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: deck.description.isNotEmpty 
                      ? Text(deck.description, maxLines: 1, overflow: TextOverflow.ellipsis) 
                      : null,
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'edit') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CreateDeckScreen(deckToEdit: deck),
                          ),
                        );
                      } else if (value == 'delete') {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Supprimer le paquet ?'),
                            content: const Text('Toutes les cartes de ce paquet seront supprimées. Cette action est irréversible.'),
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
                            await ref.read(deckServiceProvider).deleteDeck(deck.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Paquet supprimé')),
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
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('Modifier'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red, size: 20),
                            SizedBox(width: 8),
                            Text('Supprimer', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DeckDetailsScreen(deck: deck),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Erreur: $error')),
      ),
      floatingActionButton: decksAsyncValue.maybeWhen(
        data: (decks) => decks.isNotEmpty
            ? FloatingActionButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreateDeckScreen(),
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
