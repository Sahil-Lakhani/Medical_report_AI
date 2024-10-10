import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:8000/api';

  static Future<String> analyzePDF(String filePath) async {
    final url = Uri.parse('$baseUrl/analyze-report/');

    var request = http.MultipartRequest('POST', url);
    request.files.add(await http.MultipartFile.fromPath(
      'patient_report',
      filePath,
      contentType: MediaType('application', 'pdf'),
    ));

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        // Log the response body to the console
        print('API Response: ${response.body}');

        return response.body;
      } else {
        throw Exception('Failed to analyze PDF: ${response.statusCode}');
      }
    } catch (e) {
      print('Error analyzing PDF: $e');
      throw Exception('Error analyzing PDF: $e');
    }
  }

  // Add more API functions here as needed
}
