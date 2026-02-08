import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';

import '../bloc/settings_bloc.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [const Color(0xFF6C5CE7), const Color(0xFF00CEC9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Text('settings'.tr()),
      ),
      body: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          if (state is SettingsLoaded) {
            return ListView(
              children: [
                ListTile(
                  leading: const Icon(Icons.brightness_6),
                  title: const Text('Theme'),
                  subtitle: Text(
                    state.themeMode.toString().split('.').last.capitalize(),
                  ),
                  trailing: DropdownButton<ThemeMode>(
                    value: state.themeMode,
                    underline: SizedBox(),
                    items:
                        ThemeMode.values.map((mode) {
                          return DropdownMenuItem(
                            value: mode,
                            child: Text(
                              mode.toString().split('.').last.capitalize(),
                            ),
                          );
                        }).toList(),
                    onChanged: (mode) {
                      if (mode != null) {
                        context.read<SettingsBloc>().add(ChangeTheme(mode));
                      }
                    },
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.language),
                  title: const Text('Language'),
                  subtitle: Text(
                    context.locale.languageCode == 'tr' ? 'Türkçe' : 'English',
                  ),
                  trailing: DropdownButton<String>(
                    value: context.locale.languageCode,
                    underline: SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 'tr', child: Text('Türkçe')),
                      DropdownMenuItem(value: 'en', child: Text('English')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        final locale =
                            value == 'tr'
                                ? const Locale('tr', 'TR')
                                : const Locale('en', 'US');
                        context.setLocale(locale);
                        context.read<SettingsBloc>().add(
                          ChangeLanguage(locale),
                        );
                      }
                    },
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.language),
                  title: const Text('Language'),
                  subtitle: Text(
                    context.locale.languageCode == 'tr' ? 'Türkçe' : 'English',
                  ),
                  trailing: DropdownButton<String>(
                    value: context.locale.languageCode,
                    underline: SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 'tr', child: Text('Türkçe')),
                      DropdownMenuItem(value: 'en', child: Text('English')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        final locale =
                            value == 'tr'
                                ? const Locale('tr', 'TR')
                                : const Locale('en', 'US');
                        context.setLocale(locale);
                        context.read<SettingsBloc>().add(
                          ChangeLanguage(locale),
                        );
                      }
                    },
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.font_download),
                  title: const Text('Font'),
                  subtitle: Text(state.fontFamily),
                  trailing: DropdownButton<String>(
                    value: state.fontFamily,
                    underline: SizedBox(),
                    items: const [
                      DropdownMenuItem(
                        value: 'Poppins',
                        child: Text('Poppins'),
                      ),
                      DropdownMenuItem(
                        value: 'Playfair Display',
                        child: Text('Playfair Display'),
                      ),
                      DropdownMenuItem(value: 'Lora', child: Text('Lora')),
                      DropdownMenuItem(value: 'Nunito', child: Text('Nunito')),
                      DropdownMenuItem(value: 'Roboto', child: Text('Roboto')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        context.read<SettingsBloc>().add(ChangeFont(value));
                      }
                    },
                  ),
                ),
              ],
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
