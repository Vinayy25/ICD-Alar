import 'dart:convert';
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

    try {
      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to search: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error searching: $e');
    }
  }
}
