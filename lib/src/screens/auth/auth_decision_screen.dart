import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/session/session_controller.dart';
import '../../models/user_role.dart';
import '../user/user_shell.dart';
import 'sign_in_screen.dart';
import 'sign_up_screen.dart';

class AuthDecisionScreen extends StatelessWidget {
  const AuthDecisionScreen({super.key, required this.role});

  final UserRole role;

  bool get _allowGuest => role == UserRole.user;

  void _continueAsGuest(BuildContext context) {
    context.read<SessionController>().setGuest(role);
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const UserShell()),
      (_) => false,
    );
  }

  void _openSignIn(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => SignInScreen(role: role)),
    );
  }

  void _openSignUp(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => SignUpScreen(role: role)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${role.displayName} access',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              role == UserRole.user
                  ? 'Sign in to book tables or continue as guest to browse restaurants.'
                  : 'Owners need an account to manage occupancy and bookings.',
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => _openSignUp(context),
              child: const Text('Create account'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => _openSignIn(context),
              child: const Text('Sign in'),
            ),
            if (_allowGuest) ...[
              const SizedBox(height: 16),
              Text('Or'),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => _continueAsGuest(context),
                icon: const Icon(Icons.visibility_outlined),
                label: const Text('Continue as guest'),
              ),
              const SizedBox(height: 8),
              Text(
                'Guests can explore restaurants but must sign in to book.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}