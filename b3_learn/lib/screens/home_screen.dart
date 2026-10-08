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
                Text('✨ V 1.1 (Actuelle)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurpleAccent)),
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
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
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
