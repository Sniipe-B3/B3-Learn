import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/review_service.dart';
import '../models/review_session.dart';

final reviewServiceProvider = Provider<ReviewService>((ref) {
  return ReviewService();
});

class ActiveSessionNotifier extends Notifier<AsyncValue<ReviewSession?>> {
  @override
  AsyncValue<ReviewSession?> build() {
    return const AsyncValue.loading();
  }

  Future<void> loadSession(String deckId) async {
    state = const AsyncValue.loading();
    try {
      final service = ref.read(reviewServiceProvider);
      final session = await service.getActiveSession(deckId);
      state = AsyncValue.data(session);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> startNewSession(String deckId, List<String> shuffledCardIds) async {
    state = const AsyncValue.loading();
    try {
      final service = ref.read(reviewServiceProvider);
      final session = await service.createSession(deckId, shuffledCardIds);
      state = AsyncValue.data(session);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> swipeCard(String cardId, bool known) async {
    final session = state.value;
    if (session == null) return;

    final updatedRemaining = List<String>.from(session.remainingCardIds)..remove(cardId);
    
    if (!known) {
      updatedRemaining.add(cardId);
    }

    final updatedKnown = List<String>.from(session.knownCardIds);
    final updatedUnknown = List<String>.from(session.unknownCardIds);

    if (known) {
      updatedKnown.add(cardId);
    } else {
      updatedUnknown.add(cardId);
    }

    final updatedSession = ReviewSession(
      id: session.id,
      deckId: session.deckId,
      remainingCardIds: updatedRemaining,
      knownCardIds: updatedKnown,
      unknownCardIds: updatedUnknown,
      startedAt: session.startedAt,
    );

    state = AsyncValue.data(updatedSession);
    
    final service = ref.read(reviewServiceProvider);
    await service.updateSession(updatedSession);
  }
}

final activeSessionProvider = NotifierProvider<ActiveSessionNotifier, AsyncValue<ReviewSession?>>(() {
  return ActiveSessionNotifier();
});
