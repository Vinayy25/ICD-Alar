import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:icd/screens/get_premium.dart';
import 'package:icd/widgets/alar.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({Key? key}) : super(key: key);

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'About',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // App logo and name with animation
                      Center(
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              margin: const EdgeInsets.only(top: 12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withOpacity(0.2),
                                    Theme.of(context)
                                        .colorScheme
                                        .secondary
                                        .withOpacity(0.2),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: AlarLogo(
                                size: 60,
                                isAnimated: true,
                              )
                                  .animate(
                                      onPlay: (controller) =>
                                          controller.repeat(reverse: true))
                                  .shimmer(
                                    duration: 3000.ms,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withOpacity(0.4),
                                  ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Easy',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                ),
                                Text(
                                  ' ICD-11',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ],
                            ).animate().fadeIn(duration: 600.ms),
                            const SizedBox(height: 8),
                            Text(
                              'Your Pocket ICD-11 Reference',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withValues(alpha: 0.6),
                                  ),
                            ).animate().fadeIn(delay: 300.ms, duration: 600.ms),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Description card
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                          border: Border.all(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.1),
                          ),
                        ),
                        child: Text(
                          'Navigating the complexities of ICD-11 is now easier than ever! "Easy ICD-11" provides a clean, intuitive user interface for quick access to the International Classification of Diseases, 11th Revision.',
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    height: 1.6,
                                  ),
                        ),
                      ).animate().fadeIn(delay: 600.ms).slideY(
                            begin: 0.2,
                            end: 0,
                            curve: Curves.easeOutQuad,
                            duration: 800.ms,
                          ),

                      const SizedBox(height: 32),

                      // Key features section
                      _buildSectionTitle(
                              context, 'Key Features', Icons.stars_rounded)
                          .animate()
                          .fadeIn(delay: 900.ms),
                      const SizedBox(height: 16),

                      _buildFeatureItem(
                        context,
                        Icons.navigation_rounded,
                        'Effortless Navigation',
                        'Experience a user-friendly interface designed for seamless browsing.',
                        delay: 1000.ms,
                      ),

                      _buildFeatureItem(
                        context,
                        Icons.medication_rounded,
                        'Detailed Diagnoses with Post-Coordination',
                        'Enhance the specificity of your diagnoses by easily adding post-coordination codes, providing a more comprehensive clinical picture.',
                        delay: 1100.ms,
                      ),

                      _buildFeatureItem(
                        context,
                        Icons.content_paste_rounded,
                        'Clipboard Functionality',
                        'Quickly copy ICD-11 codes for easy sharing and documentation.',
                        delay: 1200.ms,
                      ),

                      const SizedBox(height: 32),

                      // Pro version section
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.15),
                              Theme.of(context)
                                  .colorScheme
                                  .tertiary
                                  .withOpacity(0.15),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.workspace_premium_rounded,
                                    color: Colors.amber[700],
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Unlock the Pro Version',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildProFeature(
                                context, '• Enjoy an ad-free experience.'),
                            _buildProFeature(context,
                                '• Access the entire ICD-11 database offline.'),
                            _buildProFeature(context,
                                '• Benefit from enhanced search capabilities.'),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const GetPremiumScreen(),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary,
                                foregroundColor:
                                    Theme.of(context).colorScheme.onPrimary,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('Upgrade Now'),
                                  const SizedBox(width: 8),
                                  Icon(Icons.arrow_forward_rounded, size: 16),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 1300.ms).slideY(
                            begin: 0.2,
                            end: 0,
                            curve: Curves.easeOutQuad,
                            duration: 800.ms,
                          ),

                      const SizedBox(height: 32),

                      // Closing message
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.1),
                          ),
                        ),
                        child: Text(
                          '"Easy ICD-11" is designed to be a valuable resource for students, researchers, and healthcare professionals. Download it today and simplify your ICD-11 experience!',
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontStyle: FontStyle.italic,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withValues(alpha: 0.6),
                                    height: 1.6,
                                  ),
                        ),
                      ).animate().fadeIn(delay: 1500.ms),

                      const SizedBox(height: 24),

                      // App version and copyright
                      Center(
                        child: Column(
                          children: [
                            Text(
                              'Version 1.0.0',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '© 2023-25 Alar Team',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 1600.ms),

                      const SizedBox(height: 40),

                      // Social links
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildSocialButton(
                            context,
                            Icons.language_rounded,
                            'Website',
                            delay: 1700.ms,
                            onTap: () {
                              //url is www.alarinnovations.com

                              launchUrl(
                                  Uri.parse('https://www.alarinnovations.com'));
                            },
                          ),
                          _buildSocialButton(
                            context,
                            Icons.email_rounded,
                            'Contact',
                            delay: 1800.ms,
                            onTap: () {
                              // Launch email

                              launchUrl(Uri.parse(
                                  'mailto:innovations.alar@gmail.com'));
                            },
                          ),
                          _buildSocialButton(
                            context,
                            Icons.privacy_tip_rounded,
                            'Privacy',
                            delay: 1900.ms,
                            onTap: () {
                              // show coming soon
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Coming Soon!'),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  Widget _buildFeatureItem(
      BuildContext context, IconData icon, String title, String description,
      {Duration? delay}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        height: 1.4,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.8),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: delay, duration: 600.ms).slideX(
          begin: 0.1,
          end: 0,
          delay: delay,
          duration: 500.ms,
        );
  }

  Widget _buildProFeature(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
      ),
    );
  }

  Widget _buildSocialButton(BuildContext context, IconData icon, String label,
      {Function()? onTap, Duration? delay}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Column(
            children: [
              Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
      ).animate().fadeIn(delay: delay, duration: 600.ms),
    );
  }
}
