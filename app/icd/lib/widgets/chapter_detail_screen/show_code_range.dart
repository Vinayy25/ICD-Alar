import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ShowCodeRange extends StatelessWidget {
  
  final Map<String, dynamic>? data;
  final AnimationController controller;

  const ShowCodeRange({super.key, this.data, required this.controller});

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
        shadowColor:
            Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.tertiary,
                Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.view_module,
                      color: Theme.of(context).colorScheme.onTertiary,
                      size: 28,
                    )
                        .animate()
                        .fadeIn(delay: 300.ms, duration: 500.ms)
                        .scale(delay: 300.ms, duration: 500.ms),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Block: ${data?['blockId'] ?? ''}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Theme.of(context).colorScheme.onTertiary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    // Add the copy button
                    IconButton(
                      icon: Icon(
                        Icons.copy,
                        color: Theme.of(context).colorScheme.onTertiary,
                      ),
                      onPressed: () {
                        final codeRange = data?['codeRange'] ?? '';
                        // Copy code range to clipboard
                        Clipboard.setData(ClipboardData(text: codeRange))
                            .then((_) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Code range $codeRange copied to clipboard'),
                              behavior: SnackBarBehavior.floating,
                              margin: const EdgeInsets.all(8),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        });
                      },
                    )
                        .animate()
                        .fadeIn(delay: 600.ms, duration: 500.ms)
                        .scale(delay: 600.ms, duration: 300.ms),
                  ],
                ),
                if (data?['codeRange'] != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Code Range: ${data?['codeRange']}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onTertiary,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}