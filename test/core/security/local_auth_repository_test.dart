import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unified_flutter_features/features/local_auth/data/secure_local_auth_repository.dart';
import 'package:unified_flutter_features/features/local_auth/presentation/constants/local_auth_constants.dart';

class MockLocalAuthentication extends Mock implements LocalAuthentication {}

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late MockLocalAuthentication mockAuth;
  late MockFlutterSecureStorage mockSecureStorage;
  late SharedPreferences prefs;
  late SecureLocalAuthRepository repository;

  setUp(() async {
    mockAuth = MockLocalAuthentication();
    mockSecureStorage = MockFlutterSecureStorage();

    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();

    repository = SecureLocalAuthRepository(
      prefs: prefs,
      secureStorage: mockSecureStorage,
      auth: mockAuth,
    );

    // Register fallback values if needed by mocktail
    registerFallbackValue(const AuthenticationOptions());
  });

  group('Biometrics', () {
    test(
      'isBiometricAvailable returns true when supported and can check',
      () async {
        when(() => mockAuth.canCheckBiometrics).thenAnswer((_) async => true);
        when(() => mockAuth.isDeviceSupported()).thenAnswer((_) async => true);

        final result = await repository.isBiometricAvailable();
        expect(result, isTrue);
      },
    );

    test(
      'isBiometricAvailable returns false when hardware is missing',
      () async {
        when(() => mockAuth.canCheckBiometrics).thenAnswer((_) async => false);
        when(() => mockAuth.isDeviceSupported()).thenAnswer((_) async => false);

        final result = await repository.isBiometricAvailable();
        expect(result, isFalse);
      },
    );

    test('authenticateWithBiometrics returns true on success', () async {
      when(() => mockAuth.canCheckBiometrics).thenAnswer((_) async => true);
      when(() => mockAuth.isDeviceSupported()).thenAnswer((_) async => true);
      when(
        () => mockAuth.authenticate(
          localizedReason: any(named: 'localizedReason'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async => true);

      final result = await repository.authenticateWithBiometrics();
      expect(result, isTrue);

      verify(
        () => mockAuth.authenticate(
          localizedReason: LocalAuthConstants.defaultBiometricReason,
          options: const AuthenticationOptions(
            biometricOnly: true,
            stickyAuth: true,
            useErrorDialogs: true,
          ),
        ),
      ).called(1);
    });

    test('authenticateWithBiometrics returns false if unavailable', () async {
      when(() => mockAuth.canCheckBiometrics).thenAnswer((_) async => false);
      when(() => mockAuth.isDeviceSupported()).thenAnswer((_) async => false);

      final result = await repository.authenticateWithBiometrics();
      expect(result, isFalse);
      verifyNever(
        () => mockAuth.authenticate(
          localizedReason: any(named: 'localizedReason'),
          options: any(named: 'options'),
        ),
      );
    });
  });

  group('PIN Management', () {
    test('isPinSet returns true if hash and salt exist', () async {
      when(
        () => mockSecureStorage.read(key: LocalAuthConstants.pinHashKey),
      ).thenAnswer((_) async => 'hash');
      when(
        () => mockSecureStorage.read(key: LocalAuthConstants.pinSaltKey),
      ).thenAnswer((_) async => 'salt');

      final result = await repository.isPinSet();
      expect(result, isTrue);
    });

    test('isPinSet returns false if either is missing', () async {
      when(
        () => mockSecureStorage.read(key: LocalAuthConstants.pinHashKey),
      ).thenAnswer((_) async => null);
      when(
        () => mockSecureStorage.read(key: LocalAuthConstants.pinSaltKey),
      ).thenAnswer((_) async => 'salt');

      final result = await repository.isPinSet();
      expect(result, isFalse);
    });

    test('deletePin clears secure storage keys', () async {
      when(
        () => mockSecureStorage.delete(key: LocalAuthConstants.pinHashKey),
      ).thenAnswer((_) async => {});
      when(
        () => mockSecureStorage.delete(key: LocalAuthConstants.pinSaltKey),
      ).thenAnswer((_) async => {});

      await repository.deletePin();

      verify(
        () => mockSecureStorage.delete(key: LocalAuthConstants.pinHashKey),
      ).called(1);
      verify(
        () => mockSecureStorage.delete(key: LocalAuthConstants.pinSaltKey),
      ).called(1);
    });
  });

  group('Preferences / Settings', () {
    test('biometricEnabled saves to SharedPreferences', () async {
      await repository.setBiometricEnabled(true);
      expect(prefs.getBool(LocalAuthConstants.biometricEnabledKey), isTrue);

      final result = await repository.isBiometricEnabled();
      expect(result, isTrue);
    });

    test('privacyGuard saves to SharedPreferences', () async {
      await repository.setPrivacyGuardEnabled(false);
      expect(prefs.getBool(LocalAuthConstants.privacyGuardEnabledKey), isFalse);

      final result = await repository.isPrivacyGuardEnabled();
      expect(result, isFalse);
    });
  });
}
