import 'package:http/http.dart' as http;
import '../models/upload_response.dart';
import 'dart:io';
import 'dart:convert';

/// Service for uploading scan images to backend
class UploadService {
  static final UploadService _instance = UploadService._internal();

  UploadService._internal();

  factory UploadService() {
    return _instance;
  }

  // Backend URL configuration
  // TODO: Make configurable per environment (dev/prod)
  static const String _backendHost = 'localhost:5001';
  static const String _uploadEndpoint = '/api/scans/upload';
  static const Duration _uploadTimeout = Duration(minutes: 5);

  /// Upload scan images to backend
  /// 
  /// Parameters:
  /// - sessionId: Unique session identifier
  /// - imageFiles: List of image File objects to upload
  /// - deviceInfo: Optional device metadata JSON string
  /// - onProgress: Optional callback for upload progress (bytes sent / total bytes)
  /// 
  /// Returns UploadResponse on success
  /// Throws exception on failure
  Future<UploadResponse> uploadScanImages({
    required String sessionId,
    required List<File> imageFiles,
    String? deviceInfo,
    void Function(int bytesUploaded, int totalBytes)? onProgress,
  }) async {
    if (imageFiles.isEmpty) {
      throw Exception('No images to upload');
    }

    try {
      // Create multipart request
      final uri = _buildUri(_uploadEndpoint);
      final request = http.MultipartRequest('POST', uri);

      // Add device info if provided
      if (deviceInfo != null && deviceInfo.isNotEmpty) {
        request.fields['deviceInfo'] = deviceInfo;
      }

      // Calculate total size for progress tracking
      int totalSize = 0;
      final List<(File, int)> filesWithSize = [];
      
      for (var file in imageFiles) {
        final size = await file.length();
        totalSize += size;
        filesWithSize.add((file, size));
      }

      // Add image files to request
      for (var (file, size) in filesWithSize) {
        final stream = http.ByteStream(file.openRead());
        request.files.add(
          http.MultipartFile(
            'images',
            stream,
            size,
            filename: file.path.split('/').last,
          ),
        );
      }

      // Send request with timeout
      final streamedResponse = await request.send()
        .timeout(_uploadTimeout);

      // Read response
      final response = await http.Response.fromStream(streamedResponse);

      // Call progress callback for completion
      onProgress?.call(totalSize, totalSize);

      // Handle response based on status code
      return _handleResponse(response);
    } on SocketException catch (e) {
      throw Exception('Network error: Unable to connect to server ($e)');
    } on TimeoutException catch (_) {
      throw Exception('Upload timeout: Request took longer than ${_uploadTimeout.inMinutes} minutes');
    } catch (e) {
      throw Exception('Upload error: $e');
    }
  }

  /// Handle HTTP response and parse accordingly
  UploadResponse _handleResponse(http.Response response) {
    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>;

      switch (response.statusCode) {
        case 200:
          // Success
          return UploadResponse.fromJson(json);
        
        case 400:
          // Bad request - images invalid or no images
          final message = json['message'] ?? 'Invalid request';
          throw Exception('Bad request: $message');
        
        case 413:
          // Payload too large
          final message = json['message'] ?? 'File too large';
          throw Exception('File size error: $message');
        
        case 500:
          // Server error
          final message = json['message'] ?? 'Internal server error';
          throw Exception('Server error: $message');
        
        default:
          throw Exception(
            'Upload failed with status ${response.statusCode}: '
            '${json['message'] ?? response.body}'
          );
      }
    } catch (e) {
      // If JSON parsing fails, return raw error
      if (response.statusCode == 200) {
        throw Exception('Invalid response format from server');
      } else {
        throw Exception(
          'Error ${response.statusCode}: ${response.body}'
        );
      }
    }
  }

  /// Build backend URI with proper protocol and host
  Uri _buildUri(String endpoint) {
    // Use https in production, http for local dev
    final scheme = _backendHost.contains('localhost') ? 'http' : 'https';
    return Uri.parse('$scheme://$_backendHost$endpoint');
  }

  /// Get device info as JSON string
  Future<String> getDeviceInfo() async {
    try {
      final deviceInfo = {
        'platform': Platform.operatingSystem,
        'os_version': Platform.operatingSystemVersion,
        'timestamp': DateTime.now().toIso8601String(),
      };
      return jsonEncode(deviceInfo);
    } catch (e) {
      return jsonEncode({'platform': 'unknown', 'error': e.toString()});
    }
  }
}
