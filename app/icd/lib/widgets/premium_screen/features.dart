import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class Features extends StatelessWidget {
  final ThemeData theme;

  Features({super.key, required this.theme});
  final List<Map<String, dynamic>> _features = [
    // For the gradient version
    {
      'icon': Icons.mic,
      'title': 'AI Voice Coding',
      'description':
          'Convert patient case histories to ICD codes using voice recognition',
      'gradient': [Colors.purple.shade300, Colors.deepPurple.shade600]
    },
    {
      'icon': Icons.manage_search,
      'title': 'Realtime Search',
      'description':
          'Advanced filtering options with instant results as you type',
      'gradient': [Colors.cyan.shade300, Colors.blue.shade600]
    },
    {
      'icon': Icons.support_agent,
      'title': 'Priority Support',
      'description':
          'Direct access to our customer support team for any assistance',
      'gradient': [Colors.red.shade300, Colors.pink.shade600]
    },
    {
      'icon': Icons.search,
      'title': 'Advanced Search',
      'description': 'Powerful search across all ICD-11 codes and categories'
    },
    {
      'icon': Icons.content_paste,
      'title': 'Clipboard History',
      'description': 'Save and organize your most used codes for quick access'
    },
    {
      'icon': Icons.nights_stay,
      'title': 'Dark Mode',
      'description': 'Comfortable viewing experience in low-light environments'
    },
    {
      'icon': Icons.block,
      'title': 'Ad-Free Experience',
      'description': 'No distractions, just pure clinical reference'
    },
    {
      'icon': Icons.share,
      'title': 'Export & Share',
      'description': 'Easily share multiple codes with colleagues'
    },
    {
      'icon': Icons.update,
      'title': 'Lifetime Updates',
      'description': 'Always stay current with the latest ICD-11 data'
    },
  ];
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.1,
      ),
      itemCount: _features.length,
      itemBuilder: (context, index) {
        final feature = _features[index];
        return Card(
          elevation: 0,
          color:
              theme.colorScheme.surfaceContainerHighest.withValues(alpha: .5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  feature['icon'] as IconData,
                  size: 32,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 8),
                Text(
                  feature['title'],
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  feature['description'],
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ).animate().fadeIn(
              delay: Duration(milliseconds: 500 + (index * 100)),
              duration: 600.ms,
            );
      },
    );
  }
}
