import 'dart:convert';
import 'package:http/http.dart' as http;

class FeedbackService {
  // Track how many emails have been sent to prevent abuse
  static int _emailSentCount = 0;

  // Maximum emails allowed per session
  static const int _maxEmails = 5;

  // Sends feedback via EmailJS
  static Future<bool> sendFeedback({
    required String feedbackType,
    required String message,
    double? rating,
    String? name,
    bool allowContact = false,
  }) async {
    // Prevent excessive emails
    if (_emailSentCount >= _maxEmails) {
      return false;
    }

    try {
      final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
      final timestamp = DateTime.now().toString();

      // Calculate rating width for the progress bar (40px per star)
      final ratingWidth = rating != null ? (rating * 40).toString() : "0";

      // Create template params - ensure all variables are properly formatted
      final templateParams = {
        'subject': "ICD App Feedback: $feedbackType",
        'feedbackType': feedbackType,
        'from_name': name ?? 'Anonymous User',
        'message': message,
        'contact_permission': allowContact
            ? 'User has agreed to be contacted'
            : 'User did not agree to be contacted',
        'timestamp': timestamp,
        'to_name': 'ALAR Support Team',
        'to_email': "vinaychandra166@gmail.com",
        'reply_to': "noreply@alarinnovations.com",
      };

      // Only add rating parameters if rating is provided
      if (rating != null) {
        templateParams['rating'] = rating.toStringAsFixed(1);
        templateParams['ratingWidth'] = ratingWidth;
      }

      // Print debug information
      print('Sending email with params: ${json.encode(templateParams)}');

      final response = await http.post(
        url,
        headers: {
          'origin': 'http://localhost',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'service_id': "service_wjdh5hp",
          'template_id': "template_st0w37m",
          'user_id': "bupyCZf6_lUBwwOUi",
          'template_params': templateParams,
        }),
      );

      // Debug the response
      print('Email response status: ${response.statusCode}');
      print('Email response body: ${response.body}');

      if (response.statusCode == 200) {
        _emailSentCount++;
        return true;
      }

      return false;
    } catch (e) {
      print('Feedback email error: $e');
      return false;
    }
  }
}
