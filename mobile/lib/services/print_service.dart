import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/print_models.dart';

/// Service for print-related operations
class PrintService {
  static const String baseUrl = 'http://10.0.2.2:5000'; // Android emulator localhost

  /// Get print statistics for a session
  Future<PrintStats> getPrintStats(String sessionId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/scans/$sessionId/print/stats'),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return PrintStats.fromJson(json);
    } else if (response.statusCode == 404) {
      return PrintStats(stlValid: false, validationMessage: 'Not ready for printing yet');
    } else {
      throw Exception('Failed to get print stats: ${response.statusCode}');
    }
  }

  /// Submit a print order
  Future<PrintOrderResult> submitPrintOrder(
    String sessionId,
    PrintSettings settings,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/scans/$sessionId/print/order'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(settings.toJson()),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return PrintOrderResult.fromJson(json);
    } else {
      throw Exception('Failed to submit print order: ${response.statusCode}');
    }
  }
}