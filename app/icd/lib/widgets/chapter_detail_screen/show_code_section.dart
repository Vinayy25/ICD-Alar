import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:icd/widgets/alar.dart';

class ShowCodeSection extends StatelessWidget {
  final bool isChapter;
  final bool isCategory;
  final Map<String, dynamic>? data;
  final AnimationController controller;

  const ShowCodeSection({super.key, required this.isChapter, required this.isCategory, this.data, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
                              animation: controller,
                              builder: (context, child) {
                                return Transform.translate(
                                  offset: Offset(
                                    0,
                                    (1 - controller.value) * -30,
                                  ),
                                  child: Opacity(
                                    opacity: controller.value,
                                    child: child,
                                  ),
                                );
                              },
                              child: Card(
                                elevation: 4,
                                shadowColor: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.3),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        isChapter
                                            ? Theme.of(context)
                                                .colorScheme
                                                .secondary
                                            : Theme.of(context)
                                                .colorScheme
                                                .primary,
                                        isChapter
                                            ? Theme.of(context)
                                                .colorScheme
                                                .secondary
                                                .withValues(alpha: 0.8)
                                            : Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .withValues(alpha: 0.8),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Row(
                                      children: [
                                        Icon(
                                          isChapter
                                              ? Icons.menu_book
                                              : Icons.qr_code,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onPrimary,
                                          size: 28,
                                        )
                                            .animate()
                                            .fadeIn(
                                                delay: 300.ms, duration: 500.ms)
                                            .scale(
                                                delay: 300.ms,
                                                duration: 500.ms),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            isChapter
                                                ? 'Chapter ${data?['code']}'
                                                : '${data?['code']}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleLarge
                                                ?.copyWith(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onPrimary,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                        ),

                                        AlarLogo(
                                          size: 24,
                                          isAnimated: true,
                                        ),
                                        // Add copy button for disease codes (categories)
                                        if (isCategory)
                                          IconButton(
                                            iconSize: 20,
                                            icon: Icon(
                                              Icons.copy,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onPrimary,
                                            ),
                                            onPressed: () {
                                              final code = data?['code'] ?? '';
                                              // Copy code to clipboard
                                              Clipboard.setData(
                                                      ClipboardData(text: code))
                                                  .then((_) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                        'Code $code copied to clipboard'),
                                                    behavior: SnackBarBehavior
                                                        .floating,
                                                    margin:
                                                        const EdgeInsets.all(8),
                                                    duration: const Duration(
                                                        seconds: 2),
                                                  ),
                                                );
                                              });
                                            },
                                          )
                                              .animate()
                                              .fadeIn(
                                                  delay: 600.ms,
                                                  duration: 500.ms)
                                              .scale(
                                                  delay: 600.ms,
                                                  duration: 300.ms),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
  }
}