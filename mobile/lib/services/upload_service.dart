import 'package:http/http.dart' as http;
import '../models/upload_response.dart';
import 'dart:io';

/// Service for uploading scan images to backend
class UploadService {
  static final UploadService _instance = UploadService._internal();

  UploadService._internal();

  factory UploadService() {
    return _instance;
  }

  // Backend URL configuration
  static const String _backendHost = 'localhost:5001';
  static const String _uploadEndpoint = '/api/scans/upload';

  /// Upload scan images to backend
  /// 
  /// Returns UploadResponse on success
  /// Throws exception on failure
  Future<UploadResponse> uploadScanImages({
    required String sessionId,
    required List<File> imageFiles,
    String? deviceInfo,
    void Function(int, int)? onProgress,
  }) async {
    try {
      // Create multipart request
      final uri = Uri.parse('https://$_backendHost$_uploadEndpoint');
      final request = http.MultipartRequest('POST', uri)
        ..fields['deviceInfo'] = deviceInfo ?? '';

      // Add image files
      for (var i = 0; i < imageFiles.length; i++) {
        final file = imageFiles[i];
        final stream = http.ByteStream(file.openRead());
        final length = await file.length();

        request.files.add(
          http.MultipartFile(
            'images',
            stream,
            length,
            filename: file.path.split('/').last,
          ),
        );
      }

      // Send request
      final streamedResponse = await request.send()
        .timeout(const Duration(minutes: 5));

      // Read response
      final response = await http.Response.fromStream(streamedResponse);

      // Parse response
      if (response.statusCode == 200) {
        final json = _parseJson(response.body);
        return UploadResponse.fromJson(json);
      } else {
        throw HttpException(
          'Upload failed with status ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Upload error: $e');
    }
  }

  /// Parse JSON response (handles both valid JSON and error responses)
  Map<String, dynamic> _parseJson(String body) {
    try {
      // Simple JSON parsing without dart:convert to avoid issues
      // In real app, use dart:convert with jsonDecode
      final Map<String, dynamic> result = {};
      
      // Extract common fields via regex/string parsing
      if (body.contains('"sessionId"')) {
        final match = RegExp(r'"sessionId"\s*:\s*"([^"]*)"').firstMatch(body);
        if (match != null) result['sessionId'] = match.group(1);
      }
      
      if (body.contains('"imagesReceived"')) {
        final match = RegExp(r'"imagesReceived"\s*:\s*(\d+)').firstMatch(body);
        if (match != null) result['imagesReceived'] = int.parse(match.group(1) ?? '0');
      }
      
      if (body.contains('"status"')) {
        final match = RegExp(r'"status"\s*:\s*"([^"]*)"').firstMatch(body);
        if (match != null) result['status'] = match.group(1);
      }
      
      if (body.contains('"message"')) {
        final match = RegExp(r'"message"\s*:\s*"([^"]*)"').firstMatch(body);
        if (match != null) result['message'] = match.group(1);
      }
      
      result['timestamp'] = DateTime.now().toIso8601String();
      
      return result;
    } catch (e) {
      return {'status': 'error', 'message': 'Parse error: $e'};
    }
  }

  /// Get device info as JSON string
  Future<String> getDeviceInfo() async {
    // In a real app, use device_info plugin
    // For now, return basic info
    return '''
    {
      "platform": "${Platform.operatingSystem}",
      "os_version": "${Platform.operatingSystemVersion}"
    }
    ''';
  }
}
