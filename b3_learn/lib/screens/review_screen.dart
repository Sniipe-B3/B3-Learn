import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flip_card/flip_card.dart';
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
  
  // Liste locale des cartes pour le swiper
  List<Flashcard> _cardsToReview = [];
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initSession();
    });
  }

  Future<void> _initSession() async {
    final notifier = ref.read(activeSessionProvider.notifier);
    await notifier.loadSession(widget.deck.id);
    
    final currentSession = ref.read(activeSessionProvider).value;
    final cardsAsync = ref.read(flashcardsStreamProvider(widget.deck.id));
    
    if (cardsAsync.value == null) return;

    if (currentSession == null) {
      // Nouvelle session
      final cardIds = cardsAsync.value!.map((c) => c.id).toList();
      cardIds.shuffle();
      await notifier.startNewSession(widget.deck.id, cardIds);
      
      setState(() {
        _cardsToReview = cardIds.map((id) => cardsAsync.value!.firstWhere((c) => c.id == id)).toList();
        _isInitialized = true;
      });
    } else {
      // Reprendre la session
      setState(() {
        _cardsToReview = currentSession.remainingCardIds
            .map((id) => cardsAsync.value!.firstWhere((c) => c.id == id, orElse: () => cardsAsync.value!.first))
            .toList();
        _isInitialized = true;
      });
    }
  }

  @override
  void dispose() {
    _swiperController.dispose();
    super.dispose();
  }

  Widget _buildCardFace({required Flashcard card, required bool isBack}) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: isBack 
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
              isBack ? 'VERSO (Réponse)' : 'RECTO (Question)',
              style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            
            if (!isBack && card.frontImageUrl != null && card.frontImageUrl!.isNotEmpty)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(card.frontImageUrl!, fit: BoxFit.cover, width: double.infinity),
                  ),
                ),
              ),
            if (isBack && card.backImageUrl != null && card.backImageUrl!.isNotEmpty)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(card.backImageUrl!, fit: BoxFit.cover, width: double.infinity),
                  ),
                ),
              ),
              
            Text(
              isBack ? card.backText : card.frontText,
              style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            
            if (!isBack) ...[
              const SizedBox(height: 48),
              const Text('Touchez pour retourner', style: TextStyle(color: Colors.white54, fontStyle: FontStyle.italic)),
            ]
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        appBar: AppBar(title: Text('Révision : ${widget.deck.title}')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Révision : ${widget.deck.title}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Recommencer du début',
            onPressed: () async {
              final cardsAsync = ref.read(flashcardsStreamProvider(widget.deck.id));
              if (cardsAsync.value != null) {
                final cardIds = cardsAsync.value!.map((c) => c.id).toList();
                cardIds.shuffle();
                await ref.read(activeSessionProvider.notifier).startNewSession(widget.deck.id, cardIds);
                setState(() {
                  _cardsToReview = cardIds.map((id) => cardsAsync.value!.firstWhere((c) => c.id == id)).toList();
                });
              }
            },
          )
        ],
      ),
      body: _cardsToReview.isEmpty
          ? Center(
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
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Cartes restantes : ${_cardsToReview.length}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: CardSwiper(
                    controller: _swiperController,
                    cardsCount: _cardsToReview.length,
                    isLoop: false,
                    onSwipe: (previousIndex, currentIndex, direction) {
                      final swipedCard = _cardsToReview[previousIndex];
                      final known = direction == CardSwiperDirection.right;
                      
                      ref.read(activeSessionProvider.notifier).swipeCard(swipedCard.id, known);
                      
                      // Si la carte n'est pas connue, on l'ajoute à la fin de NOTRE liste locale
                      if (!known) {
                        setState(() {
                          _cardsToReview.add(swipedCard);
                        });
                      }
                      return true;
                    },
                    numberOfCardsDisplayed: _cardsToReview.length > 2 ? 2 : _cardsToReview.length,
                    backCardOffset: const Offset(0, -40),
                    cardBuilder: (context, index, percentThresholdX, percentThresholdY) {
                      final card = _cardsToReview[index];
                      return FlipCard(
                        direction: FlipDirection.HORIZONTAL,
                        front: _buildCardFace(card: card, isBack: false),
                        back: _buildCardFace(card: card, isBack: true),
                      );
                    },
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
            ),
    );
  }
}
