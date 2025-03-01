import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:icd/services/send_email.dart';
import 'package:icd/widgets/alar.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:lottie/lottie.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form fields
  final _nameController = TextEditingController();
  final _feedbackController = TextEditingController();

  String _selectedFeedbackType = 'General';
  double _rating = 4.0;
  bool _isSubmitting = false;
  bool _allowContact = false;

  final List<String> _feedbackTypes = [
    'General',
    'Bug Report',
    'Feature Request',
    'Content Issue',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });

      // Simulate API call
      FeedbackService.sendFeedback(
        feedbackType: _selectedFeedbackType,
        message: _feedbackController.text,
        rating: _selectedFeedbackType == 'General' ? _rating : null,
        name: _nameController.text,
        allowContact: _allowContact,
      );

      // Reset form after submission
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });

        // Show success dialog
        _showSuccessDialog();

        // Clear form
        _nameController.clear();
        _feedbackController.clear();
        setState(() {
          _selectedFeedbackType = 'General';
          _rating = 4.0;
          _allowContact = false;
        });
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Lottie.asset(
                'assets/search_animation/success.json',
                height: 120,
                repeat: false,
              ),
              const SizedBox(height: 16),
              Text(
                'Thank You!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                'Your feedback has been submitted successfully. We appreciate your input!',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                ),
                child: Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            AlarLogo(size: 24, isAnimated: true),
            const SizedBox(width: 12),
            const Text('Feedback')
                .animate()
                .fadeIn(duration: 600.ms)
                .slideX(begin: -0.1, end: 0),
          ],
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header section
                      Center(
                        child: Column(
                          children: [
                            Text(
                              'Your Opinion Matters',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                            ).animate().fadeIn().slideY(begin: -0.2, end: 0),
                            const SizedBox(height: 8),
                            Text(
                              'Help us improve our ICD-11 app by sharing your experience',
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.7),
                                  ),
                            ).animate().fadeIn(delay: 200.ms),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Feedback type selector
                      Text(
                        'Feedback Type',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 8),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: _feedbackTypes.map((type) {
                                bool isSelected = _selectedFeedbackType == type;
                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 4),
                                  child: ChoiceChip(
                                    label: Text(type),
                                    selected: isSelected,
                                    onSelected: (selected) {
                                      setState(() {
                                        _selectedFeedbackType = type;
                                      });
                                    },
                                    labelStyle: TextStyle(
                                      color: isSelected
                                          ? Theme.of(context)
                                              .colorScheme
                                              .onPrimary
                                          : Theme.of(context)
                                              .colorScheme
                                              .onSurface,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                    backgroundColor:
                                        Theme.of(context).colorScheme.surface,
                                    selectedColor:
                                        Theme.of(context).colorScheme.primary,
                                    elevation: isSelected ? 0 : 1,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Rating section
                      if (_selectedFeedbackType == 'General') ...[
                        Text(
                          'How would you rate our app?',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: RatingBar.builder(
                            initialRating: _rating,
                            minRating: 1,
                            direction: Axis.horizontal,
                            allowHalfRating: true,
                            itemCount: 5,
                            itemSize: 40,
                            itemPadding:
                                const EdgeInsets.symmetric(horizontal: 4.0),
                            itemBuilder: (context, _) => Icon(
                              Icons.star,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            onRatingUpdate: (rating) {
                              setState(() {
                                _rating = rating;
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: Text(
                            _getRatingDescription(_rating),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Name field
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Name',
                          hintText: 'Enter your name',
                          prefixIcon: const Icon(Icons.person_outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      const SizedBox(height: 8),

                      // Contact permission
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'I agree to receive follow-ups about this feedback',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        value: _allowContact,
                        onChanged: (value) {
                          setState(() {
                            _allowContact = value ?? false;
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                        activeColor: Theme.of(context).colorScheme.primary,
                      ),

                      const SizedBox(height: 16),

                      // Feedback text field
                      TextFormField(
                        controller: _feedbackController,
                        maxLines: 5,
                        decoration: InputDecoration(
                          labelText: 'Your Feedback',
                          hintText: _getPlaceholderText(),
                          alignLabelWithHint: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your feedback';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 32),

                      // Submit button
                      Center(
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitFeedback,
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                          ),
                          child: _isSubmitting
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimary,
                                        strokeWidth: 2,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Text('Submitting...'),
                                  ],
                                )
                              : const Text('Submit Feedback'),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Contact section
                      Card(
                        elevation: 0,
                        color: Theme.of(context).colorScheme.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: Theme.of(context)
                                .colorScheme
                                .outline
                                .withValues(alpha: 0.2),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.contact_support_outlined,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Contact Us',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _buildContactItem(context,
                                  icon: Icons.email,
                                  title: 'Email',
                                  content: 'vinaychandra166@gmail.com',
                                  onTap: () => launchUrl(Uri.parse(
                                      'mailto:vinaychandra166@gmail.com?subject=Feedback%20on%20ICD-11%20App'))),
                              const SizedBox(height: 12),
                              _buildContactItem(
                                context,
                                icon: Icons.link,
                                title: 'Website',
                                content: 'www.alarinnovations.com',
                                onTap: () =>
                                    _launchUrl('https://alarinnovations.com/'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const AlarFooter(),
        ],
      ),
    );
  }

  Widget _buildContactItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String content,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.7),
                      ),
                ),
                Text(
                  content,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getRatingDescription(double rating) {
    if (rating >= 4.5) return 'Excellent';
    if (rating >= 3.5) return 'Good';
    if (rating >= 2.5) return 'Average';
    if (rating >= 1.5) return 'Poor';
    return 'Very Poor';
  }

  String _getPlaceholderText() {
    switch (_selectedFeedbackType) {
      case 'Bug Report':
        return 'Please describe the bug, steps to reproduce, and your device details...';
      case 'Feature Request':
        return 'Please describe the feature you\'d like to see...';
      case 'Content Issue':
        return 'Please describe the content issue and where you found it...';
      default:
        return 'Share your feedback, suggestions, or experience with our app...';
    }
  }

  Future<void> _launchUrl(String url) async {
    Uri URL = Uri.parse(url);
    try {
      if (await canLaunchUrl(URL)) {
        await launchUrl(URL);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch $url')),
        );
      }
    } catch (e) {
      print(e);
    }
  }
}
