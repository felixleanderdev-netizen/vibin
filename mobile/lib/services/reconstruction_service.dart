import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/reconstruction_models.dart';

/// Service for polling reconstruction status and retrieving results
class ReconstructionService {
  static const String baseUrl = 'http://10.0.2.2:5000'; // Android emulator localhost

  /// Get current reconstruction status for a session
  Future<ReconstructionStatus> getReconstructionStatus(String sessionId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/scans/$sessionId/reconstruct/status'),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return ReconstructionStatus.fromJson(json);
    } else if (response.statusCode == 404) {
      // Not started yet
      return ReconstructionStatus(
        sessionId: sessionId,
        status: 'not_started',
        updatedAt: DateTime.now(),
        message: 'Reconstruction not started',
      );
    } else {
      throw Exception('Failed to get reconstruction status: ${response.statusCode}');
    }
  }

  /// Get measurement results for a completed reconstruction
  Future<MeasurementResult?> getMeasurements(String sessionId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/scans/$sessionId/measurements'),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return MeasurementResult.fromJson(json);
    } else if (response.statusCode == 404) {
      return null; // No measurements yet
    } else {
      throw Exception('Failed to get measurements: ${response.statusCode}');
    }
  }

  Future<List<MeasurementResult>> getMeasurementHistory(String sessionId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/scans/$sessionId/measurements/history'),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as List<dynamic>;
      return json.map((item) => MeasurementResult.fromJson(item as Map<String, dynamic>)).toList();
    } else if (response.statusCode == 404) {
      return [];
    } else {
      throw Exception('Failed to get measurement history: ${response.statusCode}');
    }
  }

  /// Download the 3D model file
  Future<String> downloadModel(String sessionId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/scans/$sessionId/model'),
    );

    if (response.statusCode == 200) {
      // For now, just return the URL - in a real app you'd save the file
      return '$baseUrl/api/scans/$sessionId/model';
    } else {
      throw Exception('Failed to download model: ${response.statusCode}');
    }
  }

  /// Start reconstruction (if not automatic)
  Future<void> startReconstruction(String sessionId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/scans/$sessionId/reconstruct'),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to start reconstruction: ${response.statusCode}');
    }
  }
}