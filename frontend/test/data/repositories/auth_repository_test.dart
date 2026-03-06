// test/data/repositories/auth_repository_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sahhty/core/utils/app_failure.dart';
import 'package:sahhty/data/models/auth_model.dart';
import 'package:sahhty/data/repositories/auth_repository.dart';
import 'package:sahhty/data/services/auth_service.dart';
import 'package:sahhty/data/services/token_storage_service.dart';

// ─── Mocks ────────────────────────────────────────────────────────────────────

class MockAuthService extends Mock implements IAuthService {}

class MockTokenStorage extends Mock implements ITokenStorageService {}

// ─── Fakes (required by mocktail for any() on custom types) ──────────────────

class FakeSignInRequest extends Fake implements SignInRequest {}

class FakeSignUpRequest extends Fake implements SignUpRequest {}

class FakeAuthTokens extends Fake implements AuthTokens {}

// ─── Fixtures ────────────────────────────────────────────────────────────────

const fakeTokens = AuthTokens(
  accessToken: 'fake_access_token_abc123',
  refreshToken: 'fake_refresh_token_xyz456',
);

final fakeSignInRequest = SignInRequest(
  email: 'test@test.tn',
  password: 'Password123!',
);

final fakeSignUpRequest = SignUpRequest(
  firstName: 'Ahmed',
  lastName: 'Ben Ali',
  email: 'ahmed@test.tn',
  phone: '22345678',
  password: 'Password123!',
  birthDate: '1990-01-15',
  gender: 'M',
  role: 'P',
);

void main() {
  late MockAuthService mockAuthService;
  late MockTokenStorage mockTokenStorage;
  late AuthRepository repository;

  setUpAll(() {
    registerFallbackValue(FakeSignInRequest());
    registerFallbackValue(FakeSignUpRequest());
    registerFallbackValue(FakeAuthTokens());
  });

  setUp(() {
    mockAuthService = MockAuthService();
    mockTokenStorage = MockTokenStorage();
    repository = AuthRepository(
      authService: mockAuthService,
      tokenStorage: mockTokenStorage,
    );
  });

  group('AuthRepository.signIn', () {
    test('returns tokens and saves them on success', () async {
      when(() => mockAuthService.signIn(any()))
          .thenAnswer((_) async => fakeTokens);
      when(() => mockTokenStorage.saveTokens(any()))
          .thenAnswer((_) async {});

      final result = await repository.signIn(fakeSignInRequest);

      expect(result, equals(fakeTokens));
      verify(() => mockAuthService.signIn(fakeSignInRequest)).called(1);
      verify(() => mockTokenStorage.saveTokens(fakeTokens)).called(1);
    });

    test('propagates AuthFailure without wrapping', () async {
      when(() => mockAuthService.signIn(any()))
          .thenThrow(const AuthFailure(message: 'Invalid credentials'));

      expect(
        () => repository.signIn(fakeSignInRequest),
        throwsA(isA<AuthFailure>()),
      );
    });

    test('propagates NetworkFailure', () async {
      when(() => mockAuthService.signIn(any()))
          .thenThrow(const NetworkFailure());

      expect(
        () => repository.signIn(fakeSignInRequest),
        throwsA(isA<NetworkFailure>()),
      );
    });

    test('wraps unknown exceptions in UnexpectedFailure', () async {
      when(() => mockAuthService.signIn(any()))
          .thenThrow(Exception('Some weird error'));

      expect(
        () => repository.signIn(fakeSignInRequest),
        throwsA(isA<UnexpectedFailure>()),
      );
    });
  });

  group('AuthRepository.signUp', () {
    test('succeeds without error', () async {
      when(() => mockAuthService.signUp(any()))
          .thenAnswer((_) async {});

      await expectLater(
        () => repository.signUp(fakeSignUpRequest),
        returnsNormally,
      );
      verify(() => mockAuthService.signUp(fakeSignUpRequest)).called(1);
    });
  });

  group('AuthRepository.signOut', () {
    test('clears tokens', () async {
      when(() => mockTokenStorage.clearTokens()).thenAnswer((_) async {});

      await repository.signOut();

      verify(() => mockTokenStorage.clearTokens()).called(1);
    });

    test('throws StorageFailure if clear fails', () async {
      when(() => mockTokenStorage.clearTokens())
          .thenThrow(Exception('Storage error'));

      expect(() => repository.signOut(), throwsA(isA<StorageFailure>()));
    });
  });

  group('AuthRepository.isAuthenticated', () {
    test('returns true when tokens exist', () async {
      when(() => mockTokenStorage.hasValidTokens())
          .thenAnswer((_) async => true);

      final result = await repository.isAuthenticated();

      expect(result, isTrue);
    });

    test('returns false when no tokens', () async {
      when(() => mockTokenStorage.hasValidTokens())
          .thenAnswer((_) async => false);

      final result = await repository.isAuthenticated();

      expect(result, isFalse);
    });
  });
}
