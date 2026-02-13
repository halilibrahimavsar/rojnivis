import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:remote_auth_module/remote_auth_module.dart';

import '../../../../core/widgets/app_card.dart';

class RemoteAuthSettingsPage extends StatelessWidget {
  const RemoteAuthSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('account'.tr())),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is UnauthenticatedState) {
            context.go('/public');
          }
        },
        builder: (context, state) {
          if (state is AuthenticatedState) {
            final user = state.user;
            final displayName = user.displayName ?? 'User';
            final email = user.email;
            final photoUrl = user.photoURL;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                AppCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundImage:
                            photoUrl != null ? NetworkImage(photoUrl) : null,
                        child:
                            photoUrl == null
                                ? Text(
                                  displayName.isNotEmpty
                                      ? displayName[0].toUpperCase()
                                      : 'U',
                                  style: Theme.of(context).textTheme.headlineMedium,
                                )
                                : null,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        displayName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                             // Manage Account logic or navigation
                             ScaffoldMessenger.of(context).showSnackBar(
                               SnackBar(content: Text('Verification email sent to $email')),
                             );
                          },
                          icon: const Icon(Icons.manage_accounts),
                          label: Text('manage_account'.tr()),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () {
                             context.read<AuthBloc>().add(const SignOutEvent());
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.error,
                            foregroundColor: Theme.of(context).colorScheme.onError,
                          ),
                          icon: const Icon(Icons.logout),
                          label: Text('sign_out'.tr()),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          } else {
             return Center(
               child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'sign_in_desc'.tr(),
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () {
                      context.go('/public');
                    },
                    icon: const Icon(Icons.login),
                    label: Text('sign_in'.tr()),
                  ),
                ],
               ),
             );
          }
        },
      ),
    );
  }
}
