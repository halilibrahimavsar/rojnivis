import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../shared_features/dialog/ibo_dialog.dart';
import '../../../../shared_features/snackbar/ibo_snackbar.dart';
import '../../data/local_auth_repository.dart';
import '../bloc/local_auth_status.dart';
import '../bloc/settings/local_auth_settings_bloc.dart';
import '../bloc/settings/local_auth_settings_event.dart';
import '../bloc/settings/local_auth_settings_state.dart';
import 'local_auth_settings_sections.dart';
import 'local_auth_settings_style.dart';
import 'pin_input_dialog.dart';

/// A customizable settings widget for local authentication.
///
/// This widget provides a complete interface for managing:
/// - PIN creation, change, and deletion
/// - Biometric authentication toggle
/// - Privacy Guard settings
/// - Background lock timeout configuration
///
/// Example usage:
/// ```dart
/// LocalAuthSettingsWidget(
///   repository: myRepository,
///   style: LocalAuthSettingsStyle(
///     sectionTitleStyle: TextStyle(fontSize: 18),
///   ),
///   onPinChanged: () => print('PIN changed'),
/// )
/// ```
class LocalAuthSettingsWidget extends StatefulWidget {
  final LocalAuthRepository repository;
  final LocalAuthSettingsStyle style;
  final VoidCallback? onPinChanged;
  final VoidCallback? onBiometricToggled;
  final VoidCallback? onPrivacyGuardToggled;
  final VoidCallback? onBackgroundLockChanged;
  final Widget? header;
  final bool showHeader;
  final bool showPinSection;
  final bool showBiometricSection;
  final bool showPrivacyGuardSection;
  final bool showBackgroundLockSection;

  const LocalAuthSettingsWidget({
    super.key,
    required this.repository,
    this.style = const LocalAuthSettingsStyle(),
    this.onPinChanged,
    this.onBiometricToggled,
    this.onPrivacyGuardToggled,
    this.onBackgroundLockChanged,
    this.header,
    this.showHeader = true,
    this.showPinSection = true,
    this.showBiometricSection = true,
    this.showPrivacyGuardSection = true,
    this.showBackgroundLockSection = true,
  });

  @override
  State<LocalAuthSettingsWidget> createState() =>
      _LocalAuthSettingsWidgetState();
}

class _LocalAuthSettingsWidgetState extends State<LocalAuthSettingsWidget> {
  late final LocalAuthSettingsBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = LocalAuthSettingsBloc(repository: widget.repository);
    _bloc.add(LoadSettingsEvent());
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: BlocConsumer<LocalAuthSettingsBloc, LocalAuthSettingsState>(
        listener: _handleStateChanges,
        builder: (context, state) {
          final sections = <Widget>[];
          void addSection(Widget section) {
            if (sections.isNotEmpty) {
              sections.add(SizedBox(height: widget.style.sectionSpacing));
            }
            sections.add(section);
          }

          if (widget.showHeader) {
            addSection(LocalAuthSettingsHeader(
              state: state,
              style: widget.style,
              header: widget.header,
            ));
          }
          if (widget.showPinSection) {
            addSection(LocalAuthPinSection(
              style: widget.style,
              state: state,
              onCreatePin: () => _showCreatePinDialog(context),
              onChangePin: () => _showChangePinDialog(context),
              onDeletePin: () => _showDeletePinDialog(context),
            ));
          }
          if (widget.showBiometricSection) {
            addSection(LocalAuthBiometricSection(
              style: widget.style,
              state: state,
              onToggle: (value) =>
                  _bloc.add(ToggleBiometricEvent(enable: value)),
            ));
          }
          if (widget.showPrivacyGuardSection) {
            addSection(LocalAuthPrivacyGuardSection(
              style: widget.style,
              state: state,
              onToggle: (value) =>
                  _bloc.add(TogglePrivacyGuardEvent(enable: value)),
            ));
          }
          if (widget.showBackgroundLockSection) {
            addSection(LocalAuthBackgroundLockSection(
              style: widget.style,
              state: state,
              onTimeoutSelected: (seconds) =>
                  _bloc.add(UpdateBackgroundLockTimeoutEvent(seconds: seconds)),
            ));
          }

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: widget.style.sectionPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: sections,
            ),
          );
        },
      ),
    );
  }

  void _handleStateChanges(BuildContext context, LocalAuthSettingsState state) {
    if (state.message != null) {
      if (state.status == SettingsStatus.error) {
        IboSnackbar.showError(context, state.message!);
      } else if (state.status == SettingsStatus.success) {
        IboSnackbar.showSuccess(context, state.message!);
      }
    }

    if (state.status == SettingsStatus.success) {
      final normalized = state.message?.toLowerCase();
      if (normalized?.contains('pin') == true) {
        widget.onPinChanged?.call();
      } else if (normalized?.contains('biyometrik') == true) {
        widget.onBiometricToggled?.call();
      } else if (normalized?.contains('privacy guard') == true) {
        widget.onPrivacyGuardToggled?.call();
      } else if (normalized?.contains('arka plan') == true) {
        widget.onBackgroundLockChanged?.call();
      }
    }
  }

  Future<void> _showCreatePinDialog(BuildContext context) async {
    final pins = await PinInputDialog.show(
      context: context,
      title: 'PIN Oluştur',
      fieldLabels: const ['PIN (6 hane)', 'PIN Tekrar'],
    );

    if (pins != null && pins.length == 2) {
      _bloc.add(SavePinEvent(
        pin: pins[0],
        confirmPin: pins[1],
      ));
    }
  }

  Future<void> _showChangePinDialog(BuildContext context) async {
    final pins = await PinInputDialog.show(
      context: context,
      title: 'PIN Değiştir',
      fieldLabels: const ['Mevcut PIN', 'Yeni PIN', 'Yeni PIN Tekrar'],
      confirmLabel: 'Değiştir',
    );

    if (pins != null && pins.length == 3) {
      _bloc.add(ChangePinEvent(
        currentPin: pins[0],
        newPin: pins[1],
        confirmPin: pins[2],
      ));
    }
  }

  Future<void> _showDeletePinDialog(BuildContext context) async {
    final confirmed = await IboDialog.showConfirmation(
      context,
      'PIN Kaldır',
      'PIN kaldırıldığında biyometrik giriş de devre dışı kalacak. Devam etmek istiyor musunuz?',
      confirmText: 'Kaldır',
      cancelText: 'İptal',
    );

    if (confirmed == true) {
      if (!context.mounted) return;
      final pins = await PinInputDialog.show(
        context: context,
        title: 'PIN Doğrulama',
        fieldLabels: const ['Mevcut PIN'],
        confirmLabel: 'Doğrula',
      );

      if (!mounted) return;
      if (pins != null && pins.isNotEmpty) {
        _bloc.add(DeletePinEvent(currentPin: pins[0]));
      }
    }
  }
}
