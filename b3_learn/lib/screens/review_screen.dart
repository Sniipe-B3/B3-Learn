import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flip_card/flip_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/deck.dart';
import '../models/flashcard.dart';
import '../providers/flashcard_provider.dart';
import '../providers/review_provider.dart';
import '../widgets/zoomable_image.dart';

class ReviewScreen extends ConsumerStatefulWidget {
  final Deck? deck; // null = révision globale
  final List<Deck>? globalDecks;
  final bool shuffle;
  
  const ReviewScreen({
    super.key, 
    this.deck, 
    this.globalDecks,
    this.shuffle = true,
  });

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  final CardSwiperController _swiperController = CardSwiperController();
  
  List<Flashcard> _cardsToReview = [];
  bool _isInitialized = false;
  bool _isFinished = false;
  int _currentIndex = 0;
  
  DateTime? _startTime;
  Duration? _elapsedTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initSession();
    });
  }

  Future<void> _initSession() async {
    _currentIndex = 0;
    _isFinished = false;
    _startTime = DateTime.now();

    if (widget.deck != null) {
      // --- REVISION CLASSIQUE D'UN PAQUET ---
      final notifier = ref.read(activeSessionProvider.notifier);
      await notifier.loadSession(widget.deck!.id);
      
      final currentSession = ref.read(activeSessionProvider).value;
      final cardsAsync = ref.read(flashcardsStreamProvider(widget.deck!.id));
      
      if (cardsAsync.value == null) return;

      if (currentSession == null) {
        final cardIds = cardsAsync.value!.map((c) => c.id).toList();
        if (widget.shuffle) cardIds.shuffle();
        await notifier.startNewSession(widget.deck!.id, cardIds);
        
        setState(() {
          _cardsToReview = cardIds.map((id) => cardsAsync.value!.firstWhere((c) => c.id == id)).toList();
          _isInitialized = true;
        });
      } else {
        setState(() {
          _cardsToReview = currentSession.remainingCardIds
              .map((id) => cardsAsync.value!.firstWhere((c) => c.id == id, orElse: () => cardsAsync.value!.first))
              .toList();
          _isInitialized = true;
        });
      }
    } else if (widget.globalDecks != null && widget.globalDecks!.isNotEmpty) {
      // --- REVISION GLOBALE ---
      List<Flashcard> allCards = [];
      for (var d in widget.globalDecks!) {
        final snapshot = await FirebaseFirestore.instance.collection('decks').doc(d.id).collection('flashcards').get();
        final cards = snapshot.docs.map((doc) => Flashcard.fromMap(doc.data(), doc.id)).toList();
        allCards.addAll(cards);
      }
      
      if (widget.shuffle) {
        allCards.shuffle();
      }
      
      setState(() {
        _cardsToReview = allCards;
        _isInitialized = true;
      });
    } else {
      // Securité
      setState(() {
        _isInitialized = true;
        _isFinished = true;
      });
    }
  }

  @override
  void dispose() {
    _swiperController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
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
                    child: ZoomableImage(imageUrl: card.frontImageUrl!, height: double.infinity),
                  ),
                ),
              ),
            if (isBack && card.backImageUrl != null && card.backImageUrl!.isNotEmpty)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: ZoomableImage(imageUrl: card.backImageUrl!, height: double.infinity),
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
        appBar: AppBar(title: Text(widget.deck != null ? 'Révision : ${widget.deck!.title}' : 'Révision Globale')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final int remainingCards = _cardsToReview.length - _currentIndex;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.deck != null ? 'Révision : ${widget.deck!.title}' : 'Révision Globale'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Recommencer du début',
            onPressed: () async {
              if (widget.deck != null) {
                final cardsAsync = ref.read(flashcardsStreamProvider(widget.deck!.id));
                if (cardsAsync.value != null) {
                  final cardIds = cardsAsync.value!.map((c) => c.id).toList();
                  if (widget.shuffle) {
                    cardIds.shuffle();
                  }
                  await ref.read(activeSessionProvider.notifier).startNewSession(widget.deck!.id, cardIds);
                  setState(() {
                    _cardsToReview = cardIds.map((id) => cardsAsync.value!.firstWhere((c) => c.id == id)).toList();
                    _currentIndex = 0;
                    _isFinished = false;
                    _startTime = DateTime.now();
                  });
                }
              } else {
                _initSession(); // Recharger pour la globale
              }
            },
          )
        ],
      ),
      body: (_isFinished || _cardsToReview.isEmpty)
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.celebration, size: 80, color: Colors.amber),
                  const SizedBox(height: 24),
                  const Text('Félicitations !', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Vous avez terminé cette révision.', style: TextStyle(fontSize: 18, color: Colors.grey)),
                  const SizedBox(height: 16),
                  if (_elapsedTime != null)
                    Text('Temps écoulé : ${_formatDuration(_elapsedTime!)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.amber)),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Retour'),
                  )
                ],
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Cartes restantes : $remainingCards',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: CardSwiper(
                    controller: _swiperController,
                    cardsCount: _cardsToReview.length,
                    isLoop: false,
                    onEnd: () {
                      setState(() {
                        _isFinished = true;
                        _elapsedTime = DateTime.now().difference(_startTime!);
                      });
                    },
                    onSwipe: (previousIndex, currentIndex, direction) {
                      final swipedCard = _cardsToReview[previousIndex];
                      final known = direction == CardSwiperDirection.right;
                      
                      if (widget.deck != null) {
                        ref.read(activeSessionProvider.notifier).swipeCard(swipedCard.id, known);
                      }
                      
                      setState(() {
                        if (!known) {
                          _cardsToReview.add(swipedCard);
                        }
                        // increment current index
                        _currentIndex++;
                      });
                      return true;
                    },
                    numberOfCardsDisplayed: remainingCards > 2 ? 2 : remainingCards,
                    backCardOffset: const Offset(0, -40),
                    cardBuilder: (context, index, percentThresholdX, percentThresholdY) {
                      final card = _cardsToReview[index];
                      return FlipCard(
                        key: ValueKey('${card.id}_$index'), // Ensures the card resets its flip state
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
