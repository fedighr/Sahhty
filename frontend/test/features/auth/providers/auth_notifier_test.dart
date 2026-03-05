// test/features/auth/providers/auth_notifier_test.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sahhty/core/utils/app_failure.dart';
import 'package:sahhty/data/models/auth_model.dart';
import 'package:sahhty/data/repositories/auth_repository.dart';
import 'package:sahhty/features/auth/providers/auth_notifier.dart';
import 'package:sahhty/features/auth/providers/auth_state.dart';

// ─── Mocks ────────────────────────────────────────────────────────────────────

class MockAuthRepository extends Mock implements IAuthRepository {}

// ─── Fakes (required by mocktail for any() on custom types) ──────────────────

class FakeSignInRequest extends Fake implements SignInRequest {}

class FakeSignUpRequest extends Fake implements SignUpRequest {}

class FakeAuthTokens extends Fake implements AuthTokens {}

// ─── Fixtures ────────────────────────────────────────────────────────────────

const fakeTokens = AuthTokens(
  accessToken: 'access_abc',
  refreshToken: 'refresh_xyz',
);

void main() {
  late MockAuthRepository mockRepo;

  setUpAll(() {
    registerFallbackValue(FakeSignInRequest());
    registerFallbackValue(FakeSignUpRequest());
    registerFallbackValue(FakeAuthTokens());
  });

  setUp(() {
    mockRepo = MockAuthRepository();
    // Default: no existing session
    when(() => mockRepo.isAuthenticated()).thenAnswer((_) async => false);
    when(() => mockRepo.getCachedTokens()).thenAnswer((_) async => null);
  });

  /// Builds container and pumps until the async _checkExistingSession settles.
  Future<ProviderContainer> buildAndWait() async {
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockRepo),
      ],
    );
    // Trigger build
    container.read(authNotifierProvider);
    // Pump enough for async session check to complete
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return container;
  }

  group('AuthNotifier initial state', () {
    test('resolves to AuthUnauthenticated when no stored tokens', () async {
      final container = await buildAndWait();
      addTearDown(container.dispose);

      expect(container.read(authNotifierProvider), isA<AuthUnauthenticated>());
    });

    test('restores session if tokens found in storage', () async {
      when(() => mockRepo.isAuthenticated()).thenAnswer((_) async => true);
      when(() => mockRepo.getCachedTokens()).thenAnswer((_) async => fakeTokens);

      final container = await buildAndWait();
      addTearDown(container.dispose);

      final state = container.read(authNotifierProvider);
      expect(state, isA<AuthAuthenticated>());
      expect((state as AuthAuthenticated).tokens, equals(fakeTokens));
    });
  });

  group('AuthNotifier.signIn', () {
    test('transitions loading → authenticated on success', () async {
      when(() => mockRepo.signIn(any())).thenAnswer((_) async => fakeTokens);

      final container = await buildAndWait();
      addTearDown(container.dispose);

      final states = <AuthState>[];
      container.listen(authNotifierProvider, (_, next) => states.add(next));

      await container
          .read(authNotifierProvider.notifier)
          .signIn(email: 'test@test.tn', password: 'Password123!');

      expect(states, containsAll([isA<AuthLoading>(), isA<AuthAuthenticated>()]));
      final authed = states.last as AuthAuthenticated;
      expect(authed.tokens, equals(fakeTokens));
    });

    test('transitions loading → error on AuthFailure', () async {
      when(() => mockRepo.signIn(any()))
          .thenThrow(const AuthFailure(message: 'Invalid credentials'));

      final container = await buildAndWait();
      addTearDown(container.dispose);

      final states = <AuthState>[];
      container.listen(authNotifierProvider, (_, next) => states.add(next));

      await container
          .read(authNotifierProvider.notifier)
          .signIn(email: 'bad@test.tn', password: 'wrongpass');

      expect(states.last, isA<AuthError>());
      final error = states.last as AuthError;
      expect(error.message, 'Invalid credentials');
    });

    test('transitions loading → error on NetworkFailure', () async {
      when(() => mockRepo.signIn(any())).thenThrow(const NetworkFailure());

      final container = await buildAndWait();
      addTearDown(container.dispose);

      await container
          .read(authNotifierProvider.notifier)
          .signIn(email: 'test@test.tn', password: 'pass');

      expect(container.read(authNotifierProvider), isA<AuthError>());
    });
  });

  group('AuthNotifier.signOut', () {
    test('clears state to AuthUnauthenticated', () async {
      when(() => mockRepo.isAuthenticated()).thenAnswer((_) async => true);
      when(() => mockRepo.getCachedTokens()).thenAnswer((_) async => fakeTokens);
      when(() => mockRepo.signOut()).thenAnswer((_) async {});

      final container = await buildAndWait();
      addTearDown(container.dispose);

      expect(container.read(authNotifierProvider), isA<AuthAuthenticated>());

      await container.read(authNotifierProvider.notifier).signOut();

      expect(container.read(authNotifierProvider), isA<AuthUnauthenticated>());
    });
  });

  group('AuthNotifier.resetError', () {
    test('resets error state to AuthUnauthenticated', () async {
      when(() => mockRepo.signIn(any()))
          .thenThrow(const AuthFailure(message: 'Error'));

      final container = await buildAndWait();
      addTearDown(container.dispose);

      await container
          .read(authNotifierProvider.notifier)
          .signIn(email: 'x@x.tn', password: 'x');

      expect(container.read(authNotifierProvider), isA<AuthError>());

      container.read(authNotifierProvider.notifier).resetError();

      expect(container.read(authNotifierProvider), isA<AuthUnauthenticated>());
    });
  });
}
