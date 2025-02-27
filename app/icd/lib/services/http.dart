import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

class HttpService {
  // Base URL for your FastAPI server
  static const String baseUrl = 'http://cognito.fun';

  // Singleton pattern
  static final HttpService _instance = HttpService._internal();

  factory HttpService() {
    return _instance;
  }

  HttpService._internal();

  // Generic GET method that accepts a URL
  Future<Map<String, dynamic>> getData(String url) async {
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching data: $e');
    }
  }

  // Specific method to fetch ICD chapters
  Future<Map<String, dynamic>> getChapters(
      {String releaseId = '2019-04'}) async {
    final url = '$baseUrl/chapters/$releaseId';
    return getData(url);
  }

  // Method to fetch data from any ICD API endpoint
  Future<Map<String, dynamic>> getIcdData(String icdUrl) async {
    final encodedUrl = Uri.encodeComponent(icdUrl);
    final url = '$baseUrl/icd/data?url=$encodedUrl';
    return getData(url);
  }

  // New method to search ICD codes
  Future<Map<String, dynamic>> searchIcd({
    required String query,
    String releaseId = '2025-01',
    bool subtreeFilterUsesFoundationDescendants = false,
    bool includeKeywordResult = true,
    bool useFlexisearch = false,
    bool flatResults = true,
    bool highlightingEnabled = true,
    bool medicalCodingMode = true,
  }) async {
    final queryParams = {
      'q': query,
      'subtreeFilterUsesFoundationDescendants':
          subtreeFilterUsesFoundationDescendants.toString(),
      'includeKeywordResult': includeKeywordResult.toString(),
      'useFlexisearch': useFlexisearch.toString(),
      'flatResults': flatResults.toString(),
      'highlightingEnabled': highlightingEnabled.toString(),
      'medicalCodingMode': medicalCodingMode.toString(),
      'release_id': releaseId,
    };

    final uri =
        Uri.parse('$baseUrl/search').replace(queryParameters: queryParams);
    print("🌐 Search request URL: $uri");

    // Add retry logic for better resilience
    int retries = 0;
    const maxRetries = 2;

    while (retries <= maxRetries) {
      try {
        final response = await http.get(
          uri,
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ).timeout(const Duration(seconds: 15)); // Add timeout

        print("📡 Search response status: ${response.statusCode}");

        if (response.statusCode == 200) {
          final responseBody = response.body;

          if (responseBody.isEmpty) {
            throw Exception('Empty response from server');
          }

          try {
            final jsonData = json.decode(responseBody);
            return jsonData;
          } catch (e) {
            print("❌ JSON parsing error: $e");
            throw Exception('Failed to parse response: $e');
          }
        } else if (response.statusCode == 500) {
          // Handle 500 errors specially
          print("⚠️ Server error (500) for query: $query");

          // Return empty search result structure instead of throwing an exception
          return {
            'destinationEntities': [],
            'error': true,
            'errorMessage':
                'The server encountered an error processing this search term.',
            'resultChopped': false,
            'words': [],
            'uniqueSearchId': '',
          };
        } else {
          throw Exception('Failed to search: ${response.statusCode}');
        }
      } catch (e) {
        retries++;
        if (retries > maxRetries) {
          print("⚠️ Maximum retries reached for query: $query");

          // Return empty search result structure instead of throwing
          return {
            'destinationEntities': [],
            'error': true,
            'errorMessage': 'Failed to complete search: $e',
            'resultChopped': false,
            'words': [],
            'uniqueSearchId': '',
          };
        }

        print("🔄 Retry $retries of $maxRetries for query: $query");
        await Future.delayed(Duration(milliseconds: 500 * retries)); // Backoff
      }
    }

    // This shouldn't be reached but just in case
    throw Exception('Unexpected error in search');
  }
}
