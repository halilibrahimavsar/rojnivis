import 'package:flutter/material.dart';
import '../bloc/settings/local_auth_settings_state.dart';
import '../utils/local_auth_utils.dart';
import 'local_auth_settings_components.dart';
import 'local_auth_settings_style.dart';

class LocalAuthSettingsHeader extends StatelessWidget {
  final LocalAuthSettingsState state;
  final LocalAuthSettingsStyle style;
  final Widget? header;

  const LocalAuthSettingsHeader({
    super.key,
    required this.state,
    required this.style,
    this.header,
  });

  @override
  Widget build(BuildContext context) {
    if (header != null) return header!;
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final headerTitleStyle = style.headerTitleStyle ??
        theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700);
    final headerSubtitleStyle = style.headerSubtitleStyle ??
        theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
        );

    return Container(
      padding: style.headerPadding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primary.withValues(alpha: 0.18),
            primary.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: primary.withValues(alpha: 0.25)),
                ),
                child: Icon(
                  Icons.security,
                  color: primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Güvenlik Ayarları', style: headerTitleStyle),
                    const SizedBox(height: 4),
                    Text('Uygulama güvenliğinizi yönetin',
                        style: headerSubtitleStyle),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              LocalAuthStatusChip(
                label: state.isPinSet ? 'PIN Aktif' : 'PIN Kapalı',
                enabled: state.isPinSet,
              ),
              LocalAuthStatusChip(
                label: state.isBiometricEnabled
                    ? 'Biyometrik Açık'
                    : 'Biyometrik Kapalı',
                enabled: state.isBiometricEnabled,
              ),
              LocalAuthStatusChip(
                label: state.isPrivacyGuardEnabled
                    ? 'Privacy Guard Açık'
                    : 'Privacy Guard Kapalı',
                enabled: state.isPrivacyGuardEnabled,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class LocalAuthPinSection extends StatelessWidget {
  final LocalAuthSettingsStyle style;
  final LocalAuthSettingsState state;
  final VoidCallback onCreatePin;
  final VoidCallback onChangePin;
  final VoidCallback onDeletePin;

  const LocalAuthPinSection({
    super.key,
    required this.style,
    required this.state,
    required this.onCreatePin,
    required this.onChangePin,
    required this.onDeletePin,
  });

  @override
  Widget build(BuildContext context) {
    return LocalAuthSectionCard(
      style: style,
      title: 'PIN Kilidi',
      subtitle: state.isPinSet ? 'PIN aktif' : 'PIN ayarlanmadı',
      icon: Icons.dialpad,
      trailing: LocalAuthStatusChip(
        label: state.isPinSet ? 'Aktif' : 'Kapalı',
        enabled: state.isPinSet,
      ),
      children: [
        if (!state.isPinSet)
          LocalAuthActionButton(
            style: style,
            text: 'PIN Oluştur',
            icon: Icons.add,
            onPressed: onCreatePin,
          ),
        if (state.isPinSet) ...[
          LocalAuthActionButton(
            style: style,
            text: 'PIN Değiştir',
            icon: Icons.edit,
            onPressed: onChangePin,
          ),
          SizedBox(height: style.buttonSpacing),
          LocalAuthActionButton(
            style: style,
            text: 'PIN Kaldır',
            icon: Icons.delete_outline,
            isDestructive: true,
            onPressed: onDeletePin,
          ),
        ],
      ],
    );
  }
}

class LocalAuthBiometricSection extends StatelessWidget {
  final LocalAuthSettingsStyle style;
  final LocalAuthSettingsState state;
  final ValueChanged<bool>? onToggle;

  const LocalAuthBiometricSection({
    super.key,
    required this.style,
    required this.state,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    if (!state.isBiometricAvailable) {
      return LocalAuthSectionCard(
        style: style,
        title: 'Biyometrik Giriş',
        subtitle: 'Cihazınız biyometrik doğrulamayı desteklemiyor',
        icon: Icons.fingerprint,
        trailing: const LocalAuthStatusChip(
          label: 'Desteklenmiyor',
          enabled: false,
        ),
        children: const [
          LocalAuthInfoBanner(
            message: 'Bu cihazda biyometrik doğrulama kullanılamaz.',
            icon: Icons.block,
          ),
        ],
      );
    }

    final canToggle = state.isPinSet || state.isBiometricEnabled;

    return LocalAuthSectionCard(
      style: style,
      title: 'Biyometrik Giriş',
      subtitle: state.isBiometricEnabled
          ? 'Biyometrik giriş aktif'
          : 'Biyometrik giriş kapalı',
      icon: Icons.fingerprint,
      trailing: LocalAuthStatusChip(
        label: state.isBiometricEnabled ? 'Açık' : 'Kapalı',
        enabled: state.isBiometricEnabled,
      ),
      children: [
        LocalAuthSwitchTile(
          style: style,
          title: 'Biyometrik Doğrulama',
          subtitle: state.isBiometricEnabled
              ? 'Açık - Parmak izi veya yüz tanıma ile giriş'
              : 'Kapalı',
          value: state.isBiometricEnabled,
          icon: Icons.fingerprint,
          onChanged: canToggle ? onToggle : null,
        ),
        if (!state.isPinSet) ...[
          SizedBox(height: style.tileSpacing),
          const LocalAuthInfoBanner(
            message:
                'Biyometrik girişi etkinleştirmek için önce PIN oluşturmalısınız.',
          ),
        ],
      ],
    );
  }
}

class LocalAuthPrivacyGuardSection extends StatelessWidget {
  final LocalAuthSettingsStyle style;
  final LocalAuthSettingsState state;
  final ValueChanged<bool> onToggle;

  const LocalAuthPrivacyGuardSection({
    super.key,
    required this.style,
    required this.state,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return LocalAuthSectionCard(
      style: style,
      title: 'Privacy Guard',
      subtitle: state.isPrivacyGuardEnabled
          ? 'Ekran koruma aktif'
          : 'Ekran koruma kapalı',
      icon: Icons.privacy_tip_outlined,
      trailing: LocalAuthStatusChip(
        label: state.isPrivacyGuardEnabled ? 'Açık' : 'Kapalı',
        enabled: state.isPrivacyGuardEnabled,
      ),
      children: [
        LocalAuthSwitchTile(
          style: style,
          title: 'Ekran Koruma',
          subtitle: state.isPrivacyGuardEnabled
              ? 'Açık - Uygulama arka plandayken içerik gizlenir'
              : 'Kapalı',
          value: state.isPrivacyGuardEnabled,
          icon: Icons.privacy_tip_outlined,
          onChanged: onToggle,
        ),
      ],
    );
  }
}

class LocalAuthBackgroundLockSection extends StatelessWidget {
  final LocalAuthSettingsStyle style;
  final LocalAuthSettingsState state;
  final ValueChanged<int> onTimeoutSelected;

  const LocalAuthBackgroundLockSection({
    super.key,
    required this.style,
    required this.state,
    required this.onTimeoutSelected,
  });

  @override
  Widget build(BuildContext context) {
    final currentTimeout = state.backgroundLockTimeoutSeconds;
    final canEdit = state.isPinSet || state.isBiometricEnabled;

    final subtitle = currentTimeout > 0
        ? '${_formatDuration(currentTimeout)} sonra kilitlenir (${_getAuthMethod(state)} ile)'
        : 'Kapalı';

    return LocalAuthSectionCard(
      style: style,
      title: 'Arka Plan Kilidi',
      subtitle: subtitle,
      icon: Icons.lock_outline,
      trailing: LocalAuthStatusChip(
        label: currentTimeout > 0 ? 'Açık' : 'Kapalı',
        enabled: currentTimeout > 0,
      ),
      children: [
        Text(
          'Uygulama arka planda belirli süre kaldığında ${_getAuthMethod(state)} istensin',
          style: style.tileSubtitleStyle ??
              Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
        ),
        if (!canEdit) ...[
          SizedBox(height: style.tileSpacing),
          const LocalAuthInfoBanner(
            message:
                'Arka plan kilidi için PIN belirlemeli veya biyometrik giriş açmalısınız.',
          ),
        ],
        SizedBox(height: style.tileSpacing),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            LocalAuthChoiceChip(
              label: 'Kapalı',
              selected: currentTimeout == 0,
              enabled: canEdit || currentTimeout == 0,
              onSelected: () => onTimeoutSelected(0),
            ),
            ...style.timeoutOptions.where((s) => s > 0).map(
                  (seconds) => LocalAuthChoiceChip(
                    label: _formatDuration(seconds),
                    selected: currentTimeout == seconds,
                    enabled: canEdit,
                    onSelected: () => onTimeoutSelected(seconds),
                  ),
                ),
          ],
        ),
        if (currentTimeout > 0) ...[
          const SizedBox(height: 10),
          Text(
            'Not: Uygulama geri döndüğünde doğrulama ekranı açılır.',
            style: style.tileSubtitleStyle ??
                Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
          ),
        ],
      ],
    );
  }

  String _formatDuration(int seconds) {
    return LocalAuthUtils.getRemainingTimeText(seconds);
  }

  String _getAuthMethod(LocalAuthSettingsState state) {
    if (state.isBiometricEnabled) {
      return 'biyometrik doğrulama';
    } else if (state.isPinSet) {
      return 'PIN';
    }
    return 'doğrulama';
  }
}
