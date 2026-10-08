import 'package:flutter/material.dart';
import 'create_deck_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('B3-Learn - Mes Paquets'),
      ),
      body: Center(
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
              label: const Text('Créer un paquet'),
            )
          ],
        ),
      ),
    );
  }
}

