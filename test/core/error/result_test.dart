import 'package:cinmovies_app/core/error/app_error.dart';
import 'package:cinmovies_app/core/error/error_mapper.dart';
import 'package:cinmovies_app/core/error/result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Result', () {
    test('Success exposes and transforms its value', () async {
      const result = Success(21);

      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);
      expect(result.getOrNull(), 21);
      expect(result.getOrElse(() => 0), 21);
      expect(result.errorOrNull, isNull);
      expect(
        result.when(onSuccess: (value) => value * 2, onFailure: (_) => 0),
        42,
      );
      expect(result.map((value) => value * 2), const Success(42));
      expect(result.flatMap((value) => Success('$value')), const Success('21'));
      expect(
        await result.flatMapAsync((value) async => Success(value + 1)),
        const Success(22),
      );
    });

    test('Failure preserves its typed error through transformations', () async {
      const error = NetworkAppError(message: 'Offline');
      const Result<int> result = Failure(error);

      expect(result.isSuccess, isFalse);
      expect(result.isFailure, isTrue);
      expect(result.getOrNull(), isNull);
      expect(result.getOrElse(() => 7), 7);
      expect(result.errorOrNull, error);
      expect(result.map((value) => value * 2), const Failure<int>(error));
      expect(
        await result.flatMapAsync((value) async => Success(value + 1)),
        const Failure<int>(error),
      );
    });
  });

  group('ErrorMapperRegistry', () {
    test('uses the first matching rule', () {
      const registry = ErrorMapperRegistry([
        _MatchingRule('first'),
        _MatchingRule('second'),
      ]);

      expect(
        registry.map(StateError('boom')),
        const ServerAppError(message: 'first'),
      );
    });

    test('falls back to a safe unknown error', () {
      const registry = ErrorMapperRegistry([_NoMatchRule()]);

      expect(
        registry.map(StateError('secret detail')),
        const UnknownAppError(
          message: 'Something went wrong. Please try again.',
        ),
      );
    });

    test('capture maps thrown exceptions into Failure', () async {
      const mapper = ErrorMapperRegistry([_MatchingRule('mapped')]);

      final result = await mapper.capture<int>(() => throw StateError('boom'));

      expect(result, const Failure<int>(ServerAppError(message: 'mapped')));
    });
  });
}

final class _MatchingRule implements ErrorMappingRule {
  const _MatchingRule(this.message);

  final String message;

  @override
  AppError? tryMap(Object exception) {
    return ServerAppError(message: message);
  }
}

final class _NoMatchRule implements ErrorMappingRule {
  const _NoMatchRule();

  @override
  AppError? tryMap(Object exception) => null;
}
