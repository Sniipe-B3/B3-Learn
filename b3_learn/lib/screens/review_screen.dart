import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import '../models/deck.dart';
import '../models/flashcard.dart';

import '../providers/flashcard_provider.dart';
import '../providers/review_provider.dart';

class ReviewScreen extends ConsumerStatefulWidget {
  final Deck deck;
  const ReviewScreen({super.key, required this.deck});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  final CardSwiperController _swiperController = CardSwiperController();
  bool _isFlipped = false;

  @override
  void initState() {
    super.initState();
    // Charger la session (nouvelle ou existante)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initSession();
    });
  }

  Future<void> _initSession() async {
    final notifier = ref.read(activeSessionProvider.notifier);
    await notifier.loadSession(widget.deck.id);
    
    final currentSession = ref.read(activeSessionProvider).value;
    if (currentSession == null) {
      // Aucune session en cours, on crée une nouvelle
      final cardsAsync = ref.read(flashcardsStreamProvider(widget.deck.id));
      if (cardsAsync.value != null && cardsAsync.value!.isNotEmpty) {
        final cardIds = cardsAsync.value!.map((c) => c.id).toList();
        cardIds.shuffle(); // Mélange aléatoire
        await notifier.startNewSession(widget.deck.id, cardIds);
      }
    }
  }

  @override
  void dispose() {
    _swiperController.dispose();
    super.dispose();
  }

  Widget _buildCard(Flashcard card, bool isFlipped) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: isFlipped 
                ? [Colors.teal.shade900, Colors.teal.shade700]
                : [Colors.deepPurple.shade900, Colors.deepPurple.shade700],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isFlipped ? 'VERSO (Réponse)' : 'RECTO (Question)',
              style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            
            // Image éventuelle
            if (!isFlipped && card.frontImageUrl != null && card.frontImageUrl!.isNotEmpty)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(card.frontImageUrl!, fit: BoxFit.cover, width: double.infinity),
                  ),
                ),
              ),
            if (isFlipped && card.backImageUrl != null && card.backImageUrl!.isNotEmpty)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(card.backImageUrl!, fit: BoxFit.cover, width: double.infinity),
                  ),
                ),
              ),
              
            // Texte
            Text(
              isFlipped ? card.backText : card.frontText,
              style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            
            if (!isFlipped) ...[
              const SizedBox(height: 48),
              const Text('Appuyez pour retourner', style: TextStyle(color: Colors.white54, fontStyle: FontStyle.italic)),
            ]
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sessionAsync = ref.watch(activeSessionProvider);
    final cardsAsync = ref.watch(flashcardsStreamProvider(widget.deck.id));

    return Scaffold(
      appBar: AppBar(
        title: Text('Révision : ${widget.deck.title}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Recommencer du début',
            onPressed: () async {
              if (cardsAsync.value != null) {
                final cardIds = cardsAsync.value!.map((c) => c.id).toList();
                cardIds.shuffle();
                await ref.read(activeSessionProvider.notifier).startNewSession(widget.deck.id, cardIds);
                setState(() => _isFlipped = false);
              }
            },
          )
        ],
      ),
      body: sessionAsync.when(
        data: (session) {
          if (session == null || cardsAsync.value == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (session.remainingCardIds.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.celebration, size: 80, color: Colors.amber),
                  const SizedBox(height: 24),
                  const Text('Félicitations !', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Vous avez terminé ce paquet.', style: TextStyle(fontSize: 18, color: Colors.grey.shade400)),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Retour aux paquets'),
                  )
                ],
              ),
            );
          }

          // Construire la liste des cartes restantes dans l'ordre de la session
          final remainingCards = session.remainingCardIds
              .map((id) => cardsAsync.value!.firstWhere((c) => c.id == id, orElse: () => cardsAsync.value!.first))
              .toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Cartes restantes : ${remainingCards.length}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _isFlipped = !_isFlipped;
                    });
                  },
                  child: CardSwiper(
                    controller: _swiperController,
                    cardsCount: remainingCards.length,
                    isLoop: false,
                    onSwipe: (previousIndex, currentIndex, direction) {
                      final swipedCardId = remainingCards[previousIndex].id;
                      final known = direction == CardSwiperDirection.right;
                      
                      ref.read(activeSessionProvider.notifier).swipeCard(swipedCardId, known);
                      
                      // Remettre le flag isFlipped à false pour la prochaine carte
                      setState(() {
                        _isFlipped = false;
                      });
                      return true;
                    },
                    numberOfCardsDisplayed: remainingCards.length > 2 ? 2 : remainingCards.length,
                    backCardOffset: const Offset(0, -40),
                    cardBuilder: (context, index, percentThresholdX, percentThresholdY) {
                      return _buildCard(remainingCards[index], index == 0 ? _isFlipped : false);
                    },
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 32.0, top: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [
                        Icon(Icons.keyboard_double_arrow_left, color: Colors.redAccent, size: 32),
                        Text('À revoir', style: TextStyle(color: Colors.redAccent)),
                      ],
                    ),
                    Column(
                      children: [
                        Icon(Icons.keyboard_double_arrow_right, color: Colors.greenAccent, size: 32),
                        Text('Connu', style: TextStyle(color: Colors.greenAccent)),
                      ],
                    ),
                  ],
                ),
              )
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Erreur: $e')),
      ),
    );
  }
}
