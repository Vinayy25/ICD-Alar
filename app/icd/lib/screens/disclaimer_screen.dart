import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:icd/widgets/alar.dart';

class DisclaimerScreen extends StatelessWidget {
  final VoidCallback onAccept;

  const DisclaimerScreen({
    Key? key,
    required this.onAccept,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with animated logo
                      Center(
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: AlarLogo(size: 48)
                                  .animate()
                                  .scale(
                                    duration: 600.ms,
                                    curve: Curves.easeOut,
                                    begin: const Offset(0.8, 0.8),
                                    end: const Offset(1.0, 1.0),
                                  )
                                  .then()
                                  .shimmer(
                                    duration: 1200.ms,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withOpacity(0.6),
                                  ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Easy ICD-11',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ).animate().fadeIn(duration: 600.ms),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Theme.of(context).colorScheme.primary,
                                    Theme.of(context).colorScheme.secondary,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Disclaimer',
                                style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.onPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ).animate().fadeIn(delay: 200.ms, duration: 600.ms),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Main content with staggered animation
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildParagraph(
                              context,
                              'The "Easy ICD-11" app is designed to provide educational insights and general information based on the ICD-11 classification system. It serves as a valuable reference but is not intended to replace professional medical advice, diagnosis, or treatment. For any health-related concerns, we recommend consulting a qualified healthcare professional who can offer personalized guidance.',
                              delay: 400.ms,
                            ),
                            const SizedBox(height: 16),
                            _buildParagraph(
                              context,
                              'We strive to ensure that the information provided is accurate and up to date. However, medical classifications and guidelines may evolve over time. For the latest and most reliable details, please refer to official sources.',
                              delay: 600.ms,
                            ),
                            const SizedBox(height: 16),
                            _buildParagraph(
                              context,
                              'The developers and publishers of this app are committed to supporting healthcare learning but cannot take responsibility for medical decisions made solely based on the app\'s content. If you are facing a medical emergency, please seek immediate assistance from a healthcare provider or emergency services.',
                              delay: 800.ms,
                            ),
                          ],
                        ),
                      )
                          .animate()
                          .fadeIn(delay: 400.ms, duration: 800.ms)
                          .slideY(
                            begin: 0.2,
                            end: 0,
                            delay: 400.ms,
                            duration: 600.ms,
                            curve: Curves.easeOutQuad,
                          ),

                      const SizedBox(height: 40),

                      // Security and privacy indicators
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildInfoItem(
                              context,
                              Icons.local_hospital_rounded,
                              'Educational Use',
                              delay: 1000.ms,
                            ),
                            _buildInfoItem(
                              context,
                              Icons.verified_user_rounded,
                              'Reference Only',
                              delay: 1100.ms,
                            ),
                            _buildInfoItem(
                              context,
                              Icons.privacy_tip_rounded,
                              'Consult Professionals',
                              delay: 1200.ms,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom action area
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: onAccept,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('I Understand and Accept'),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 16,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 1400.ms, duration: 600.ms),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParagraph(BuildContext context, String text, {Duration? delay}) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            height: 1.5,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.9),
          ),
    ).animate().fadeIn(delay: delay, duration: 800.ms);
  }

  Widget _buildInfoItem(BuildContext context, IconData icon, String text,
      {Duration? delay}) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            text,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ).animate().fadeIn(delay: delay, duration: 600.ms),
    );
  }
}
