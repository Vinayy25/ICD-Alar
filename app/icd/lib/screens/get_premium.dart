import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:icd/widgets/premium_screen/faq.dart';
import 'package:icd/widgets/premium_screen/features.dart';
import 'package:lottie/lottie.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:icd/widgets/alar.dart';

class GetPremiumScreen extends StatefulWidget {
  const GetPremiumScreen({super.key});

  @override
  State<GetPremiumScreen> createState() => _GetPremiumScreenState();
}

class _GetPremiumScreenState extends State<GetPremiumScreen> {
  bool _isLoading = false;

  // List of premium features
 

  Future<void> _handlePurchase() async {
    setState(() => _isLoading = true);

    try {
      // Payment URL for lifetime premium access
      final paymentUrl = Uri.parse('https://pages.razorpay.com/icd-premium');

      await launchUrl(
        paymentUrl,
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      print("Payment error: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Could not open payment page. Please try again.'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.red,
      ));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Premium Access'),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                const SizedBox(height: 12),

                // Header section with gradient and animation
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        theme.colorScheme.primaryContainer,
                        theme.colorScheme.primary.withOpacity(0.8),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Lottie.asset(
                          'assets/search_animation/card_animation.json',
                          height: 120,
                          repeat: true),
                      Text(
                        'Unlock Lifetime Access',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: isDark
                              ? Colors.white
                              : theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      )
                          .animate()
                          .fadeIn(duration: 600.ms)
                          .slideY(begin: -0.2, end: 0, duration: 600.ms),
                      const SizedBox(height: 8),
                      Text(
                        'One payment, forever benefits',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: isDark
                              ? Colors.white70
                              : theme.colorScheme.onPrimary.withOpacity(0.9),
                        ),
                        textAlign: TextAlign.center,
                      ).animate().fadeIn(delay: 200.ms, duration: 600.ms),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Premium card with price
                Card(
                  elevation: 8,
                  shadowColor: theme.colorScheme.primary.withOpacity(0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: theme.colorScheme.primary.withOpacity(0.2),
                      width: 2,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // Premium badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.tertiary,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    theme.colorScheme.tertiary.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            'LIFETIME PREMIUM',
                            style: TextStyle(
                              color: theme.colorScheme.onTertiary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ).animate().scale(
                            begin: const Offset(0.9, 0.9),
                            end: const Offset(1, 1),
                            duration: 400.ms,
                            curve: Curves.easeOutBack),

                        const SizedBox(height: 24),

                        // Price
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '₹',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            Text(
                              '449',
                              style: TextStyle(
                                fontSize: 56,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        )
                            .animate()
                            .fadeIn(delay: 300.ms)
                            .slideY(begin: 0.3, end: 0, duration: 500.ms),

                        const SizedBox(height: 8),

                        // One-time note
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'One-time payment only',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ).animate().fadeIn(delay: 400.ms),

                        const SizedBox(height: 24),

                        // Purchase button
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _isLoading ? null : _handlePurchase,
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            icon: _isLoading
                                ? SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      color: theme.colorScheme.onPrimary,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.lock_open),
                            label: Text(
                                _isLoading ? 'Processing...' : 'Upgrade Now'),
                          ),
                        )
                            .animate()
                            .fadeIn(delay: 500.ms)
                            .slideY(begin: 0.2, end: 0, duration: 500.ms),

                        const SizedBox(height: 16),

                        // Secure payment note
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.security,
                              size: 16,
                              color: theme.colorScheme.onSurfaceVariant
                                  .withOpacity(0.7),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Secure payment via Razorpay',
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurfaceVariant
                                    .withOpacity(0.7),
                              ),
                            ),
                          ],
                        ).animate().fadeIn(delay: 600.ms),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: 300.ms, duration: 800.ms),

                const SizedBox(height: 24),

                // Features section header
                Text(
                  'What You\'ll Get',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ).animate().fadeIn(delay: 400.ms),
                const SizedBox(height: 16),

                // Features grid
                Features(theme: theme),

                const SizedBox(height: 24),

                // Testimonial section
                Card(
                  elevation: 0,
                  color: theme.colorScheme.secondaryContainer.withOpacity(0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          '"The premium version has completely transformed how I use ICD codes in my practice. Worth every penny!"',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '— Dr. Sharma, Neurologist',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: 800.ms),

                const SizedBox(height: 16),

                // FAQ section
                Text(
                  'Frequently Asked Questions',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ).animate().fadeIn(delay: 900.ms),
                const SizedBox(height: 12),

                // FAQ items
                buildFaqItem(
                  theme,
                  question: 'Is this really a one-time payment?',
                  answer:
                      'Yes! Pay once and enjoy all premium features for the lifetime of the app.',
                  delay: 1000,
                ),
                buildFaqItem(
                  theme,
                  question: 'Will I get future updates?',
                  answer:
                      'Absolutely! All future updates to both the app and ICD data are included.',
                  delay: 1100,
                ),
                buildFaqItem(
                  theme,
                  question: 'Do you offer refunds?',
                  answer:
                      'We offer a 7-day refund policy if you\'re not satisfied with the premium features.',
                  delay: 1200,
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
          // Footer with company branding
          const AlarFooter(),
        ],
      ),
    );
  }

  
}
