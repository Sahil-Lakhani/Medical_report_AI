import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.0.178:8000/api';

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
        
        // Display the analysis results in a formatted way
        displayAnalysisResults(response.body);
        
        return response.body;
      } else {
        throw Exception('Failed to analyze PDF: ${response.statusCode}');
      }
    } catch (e) {
      print('Error analyzing PDF: $e');
      throw Exception('Error analyzing PDF: $e');
    }
  }

  static void displayAnalysisResults(String jsonResponse) {
    final Map<String, dynamic> data = json.decode(jsonResponse);
    final List<dynamic> parameters = data['parameters'];
    final List<dynamic> additionalInfo = data['additionalInfo'];

    // Display table header
    print('| Parameter | Optimal Range | Patient Value |');
    print('|-----------|---------------|---------------|');

    // Display table rows
    for (var param in parameters) {
      print('| ${param['name'].padRight(9)} | ${param['optimalRange'].padRight(13)} | ${param['patientValue'].padRight(13)} |');
    }

    // Display additional information
    print('\nAdditional Information:');
    for (var info in additionalInfo) {
      print('- $info');
    }
  }

  // Add more API functions here as needed
}
