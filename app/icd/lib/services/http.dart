import 'dart:convert';
import 'package:http/http.dart' as http;

class HttpService {
  // Base URL for your FastAPI server
  static const String baseUrl = 'https://53df-2401-4900-6301-4d18-69e2-d70b-615b-d913.ngrok-free.app';

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
}
