import 'package:flutter/material.dart';
import 'package:icd/services/firebase_service.dart';
import 'package:icd/state/auth_state.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatefulWidget {
  final AuthStateProvider authProvider;
  const LoginPage({super.key, required this.authProvider});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

final TextEditingController emailController = TextEditingController();
final TextEditingController passwordController = TextEditingController();

class _LoginPageState extends State<LoginPage> {
  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final authProvider = Provider.of<AuthStateProvider>(context, listen: false);
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        width: size.width,
        height: size.height,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.primary.withValues(alpha: 0.05),
              theme.colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(flex: 1),

              // Company logo/name
              Text(
                "ALAR",
                style: theme.textTheme.displayLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                  letterSpacing: 4,
                ),
              ),

              const SizedBox(height: 16),

              // Tagline
              Text(
                "International Classification of Diseases",
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),

              const Spacer(flex: 2),

              // Welcome message
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      "Welcome to ICD",
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Access the complete International Classification of Diseases database with advanced search and reference features.",
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 32),

                    // Google Sign-in button
                    ElevatedButton(
                      onPressed: () async {
                        String response =
                            await FirebaseService().signInWithGoogle();
                        if (response == "NEW_USER") {
                          authProvider.isNewUser = true;
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        backgroundColor: Colors.white,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/icons/google.png',
                            height: 24,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            "Sign in with Google",
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.black87,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),
                    Text(
                      "Google account is required to use this app",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 2),

              // Footer/version info
              Text(
                "Powered by Alar",
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
