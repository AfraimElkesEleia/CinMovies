import 'package:cinmovies_app/features/ai/domain/entities/movie_chat_models.dart';
import 'package:cinmovies_app/features/ai/presentation/cubit/ai_chat_cubit.dart';
import 'package:cinmovies_app/features/ai/presentation/widgets/chat_tab.dart';
import 'package:cinmovies_app/features/ai/presentation/widgets/movie_recommendation_card.dart';
import 'package:cinmovies_app/features/ai/presentation/widgets/thinking_bubble.dart';
import 'package:cinmovies_app/features/movies/domain/entities/movie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders the empty chat state', (tester) async {
    await tester.pumpWidget(_app(messages: const []));

    expect(find.text('Ask for a movie match'), findsOneWidget);
    expect(find.textContaining('Recommend a short sci-fi'), findsOneWidget);
  });

  testWidgets('submits typed text with the send action', (tester) async {
    var sends = 0;
    await tester.pumpWidget(_app(messages: const [], onSend: () => sends++));

    await tester.enterText(find.byType(TextField), 'Recommend a family movie');
    await tester.pump();
    await tester.tap(find.byTooltip('Send message'));

    expect(sends, 1);
  });

  testWidgets('shows assistant loading and text', (tester) async {
    await tester.pumpWidget(
      _app(status: AiChatStatus.sending, messages: [_assistantMessage()]),
    );
    await tester.pump(const Duration(milliseconds: 301));

    expect(find.byType(ThinkingBubble), findsOneWidget);
    expect(find.text('A grounded answer'), findsOneWidget);
  });

  testWidgets('renders a recommendation and reports its tap', (tester) async {
    Movie? selected;
    String? selectedHeroTag;
    await tester.pumpWidget(
      _app(
        messages: [_assistantMessage(withRecommendation: true)],
        onMoviePressed: (movie, heroTag) {
          selected = movie;
          selectedHeroTag = heroTag;
        },
      ),
    );

    expect(find.byType(MovieRecommendationCard), findsOneWidget);
    expect(
      find.text('Matches your runtime and genre request.'),
      findsOneWidget,
    );
    await tester.tap(find.byType(MovieRecommendationCard));

    expect(selected, same(_movie));
    expect(
      selectedHeroTag,
      'ai-recommendation-08b02ec9-42c4-4742-b2f0-7770c6fdcebd-0-157336',
    );
  });

  testWidgets('retry action invokes callback after a send failure', (
    tester,
  ) async {
    var retries = 0;
    await tester.pumpWidget(
      _app(
        status: AiChatStatus.sendFailure,
        messages: [_assistantMessage()],
        failureMessage: 'No connection',
        onRetry: () => retries++,
      ),
    );

    await tester.tap(find.text('Retry'));

    expect(retries, 1);
  });
}

Widget _app({
  required List<MovieChatMessage> messages,
  AiChatStatus status = AiChatStatus.ready,
  String? failureMessage,
  VoidCallback? onSend,
  VoidCallback? onRetry,
  void Function(Movie movie, String heroTag)? onMoviePressed,
}) {
  return MaterialApp(
    home: Scaffold(
      body: ChatTab(
        controller: TextEditingController(),
        scrollController: ScrollController(),
        messages: messages,
        status: status,
        failureMessage: failureMessage,
        onPromptSelected: (_) {},
        onSuggestedReply: (_) {},
        onMoviePressed: onMoviePressed ?? (_, _) {},
        onSend: onSend ?? () {},
        onRetry: onRetry ?? () {},
      ),
    ),
  );
}

MovieChatMessage _assistantMessage({bool withRecommendation = false}) {
  return MovieChatMessage(
    id: '08b02ec9-42c4-4742-b2f0-7770c6fdcebd',
    role: MovieChatRole.assistant,
    content: 'A grounded answer',
    createdAt: DateTime.utc(2026),
    recommendations: withRecommendation
        ? const [
            MovieRecommendation(
              movie: _movie,
              reason: 'Matches your runtime and genre request.',
            ),
          ]
        : const [],
  );
}

const _movie = Movie(
  id: '157336',
  title: 'Interstellar',
  imageAsset: 'assets/images/movie_ex1.jpg',
  genres: ['Science Fiction'],
  rating: 8.7,
  year: '2014',
  duration: '2h 49m',
  ageRating: 'PG-13',
  synopsis: 'Explorers travel through a wormhole.',
  director: 'Christopher Nolan',
  votes: '35K',
  cast: [],
  reviews: [],
);
