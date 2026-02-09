class LocalAuthConstants {
  LocalAuthConstants._();

  static const int pinLength = 6;
  static const int maxFailedAttempts = 3;
  static const int hapticDelayMs = 150;
  static const int shakeAnimationDuration = 500;
  static const int pinDotSize = 20;
  static const double pinDotSpacing = 12.0;
  static const double numpadButtonSize = 75.0;
  static const double numpadSpacing = 20.0;
  static const double pinDotShadowBlurRadius = 10.0;
  static const double pinDotShadowSpreadRadius = 2.0;
  static const double backgroundLockOpacity = 0.55;
  static const int backgroundLockMaxWidth = 320;
  static const Duration defaultAnimationDuration = Duration(milliseconds: 200);

  static const String pinHashKey = 'local_auth_pin_hash';
  static const String pinSaltKey = 'local_auth_pin_salt';
  static const String biometricEnabledKey = 'local_auth_biometric_enabled';
  static const String privacyGuardEnabledKey =
      'local_auth_privacy_guard_enabled';
  static const String backgroundLockTimeoutKey =
      'local_auth_background_lock_timeout';
  static const String lastBackgroundAtKey = 'local_auth_last_background_at';
  static const String lockoutEndKey = 'local_auth_lockout_end';
  static const String lockoutLevelKey = 'local_auth_lockout_level';

  static const String defaultBiometricReason = 'Authenticate to continue';
  static const String enableBiometricReason = 'Enable biometric login';
  static const String pinLabelText = 'PIN';
  static const String verifyButtonText = 'Doğrula';
  static const String cancelButtonText = 'Vazgeç';
  static const String pinDialogTitle = 'PIN Doğrulama';

  // Settings Widget Constants
  static const List<int> defaultTimeoutOptions = [0, 5, 10, 15, 30, 60];
  static const String settingsTitle = 'Güvenlik Ayarları';
  static const String settingsSubtitle = 'Uygulama güvenliğinizi yönetin';
  static const String pinSectionTitle = 'PIN Kilidi';
  static const String biometricSectionTitle = 'Biyometrik Giriş';
  static const String privacyGuardSectionTitle = 'Privacy Guard';
  static const String backgroundLockSectionTitle = 'Arka Plan Kilidi';
  static const String pinNotSetWarning = 'Önce PIN belirlemelisiniz';
  static const String biometricNotAvailable =
      'Cihazınız biyometrik doğrulamayı desteklemiyor';
  static const String createPinButtonText = 'PIN Oluştur';
  static const String changePinButtonText = 'PIN Değiştir';
  static const String deletePinButtonText = 'PIN Kaldır';
  static const String createPinDialogTitle = 'PIN Oluştur';
  static const String changePinDialogTitle = 'PIN Değiştir';
  static const String deletePinConfirmTitle = 'PIN Kaldır';
  static const String deletePinConfirmMessage =
      'PIN kaldırıldığında biyometrik giriş de devre dışı kalacak. Devam etmek istiyor musunuz?';
  static const String currentPinLabel = 'Mevcut PIN';
  static const String newPinLabel = 'Yeni PIN';
  static const String confirmPinLabel = 'PIN Tekrar';
  static const String pinHint = '******';
  static const String saveButtonText = 'Kaydet';
  static const String changeButtonText = 'Değiştir';
  static const String removeButtonText = 'Kaldır';
  static const String cancelButtonText2 = 'İptal';
  static const String pinValidationError = '6 haneli PIN girin';
  static const String pinMatchError = 'PINler eşleşmiyor';
  static const String privacyGuardEnabledSubtitle = 'Ekran koruma aktif';
  static const String privacyGuardDisabledSubtitle = 'Ekran koruma kapalı';
  static const String biometricEnabledSubtitle = 'Biyometrik giriş aktif';
  static const String biometricDisabledSubtitle = 'Biyometrik giriş kapalı';
  static const String biometricSwitchTitle = 'Biyometrik Doğrulama';
  static const String biometricEnabledDescription =
      'Açık - Parmak izi veya yüz tanıma ile giriş';
  static const String biometricDisabledDescription = 'Kapalı';
  static const String biometricPrerequisiteMessage =
      'Biyometrik girişi etkinleştirmek için önce PIN oluşturmalısınız.';
  static const String privacyGuardSwitchTitle = 'Ekran Koruma';
  static const String privacyGuardEnabledDescription =
      'Açık - Uygulama arka plandayken içerik gizlenir';
  static const String privacyGuardDisabledDescription = 'Kapalı';
  static const String backgroundLockSubtitle =
      'Uygulama arka planda belirli süre kaldığında otomatik olarak kilitlensin';
  static const String backgroundLockDisabled = 'Kapalı';
  static const String timeoutChipLabelSuffix = ' sn';

  static const Map<int, int> lockoutDurations = {
    0: 30,
    1: 120,
    2: 300,
    3: 1000,
  };
}
