import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';

void main() async {
  // S'assurer que les bindings Flutter sont initialisés avant d'appeler Firebase
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialisation de Firebase avec les options générées
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // ProviderScope est nécessaire pour utiliser Riverpod
  runApp(const ProviderScope(child: B3LearnApp()));
}

class B3LearnApp extends StatelessWidget {
  const B3LearnApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'B3-Learn',
      debugShowCheckedModeBanner: false,
      // Configuration du Thème Sombre
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1F1F1F),
          elevation: 0,
          centerTitle: true,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

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
                // TODO: Naviguer vers la création d'un paquet
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
