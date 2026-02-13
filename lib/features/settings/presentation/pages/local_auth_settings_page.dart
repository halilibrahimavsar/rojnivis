import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:unified_flutter_features/features/local_auth/data/local_auth_repository.dart';
import 'package:unified_flutter_features/features/local_auth/presentation/widgets/local_auth_settings_widget.dart';

import '../../../../di/injection.dart';

class LocalAuthSettingsPage extends StatelessWidget {
  const LocalAuthSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('security'.tr())),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: LocalAuthSettingsWidget(
          repository: getIt<LocalAuthRepository>(),
          showHeader: false, 
        ),
      ),
    );
  }
}
