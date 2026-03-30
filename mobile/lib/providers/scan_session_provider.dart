import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/scan_session.dart';
import '../models/upload_response.dart';
import '../services/camera_service.dart';
import '../services/upload_service.dart';
import 'dart:io';

/// Provider for managing scan session state and operations
class ScanSessionProvider extends ChangeNotifier {
  late ScanSession _currentSession;
  final CameraService _cameraService = CameraService();
  final UploadService _uploadService = UploadService();

  late String _currentSessionId;

  ScanSessionProvider() {
    _currentSessionId = const Uuid().v4();
    _currentSession = ScanSession(
      id: _currentSessionId,
      createdAt: DateTime.now(),
    );
  }

  // Getters
  ScanSession get currentSession => _currentSession;
  String get sessionId => _currentSessionId;
  int get imageCount => _currentSession.imageCount;
  int get targetImageCount => _currentSession.targetImageCount;
  double get progress => _currentSession.progress;
  bool get isComplete => _currentSession.isComplete;
  String get status => _currentSession.status;

  /// Start a new scanning session
  void startNewSession() {
    _currentSessionId = const Uuid().v4();
    _currentSession = ScanSession(
      id: _currentSessionId,
      createdAt: DateTime.now(),
      status: 'capturing',
    );
    notifyListeners();
  }

  /// Simulate adding an image to the session (placeholder for Task 1.3)
  Future<void> addImage(File imageFile) async {
    try {
      _currentSession.status = 'capturing';
      final savedFile = await _cameraService.saveImage(sessionId, imageFile);
      
      _currentSession = _currentSession.copyWith(
        imageFilePaths: [..._currentSession.imageFilePaths, savedFile.path],
      );
      
      notifyListeners();
    } catch (e) {
      _currentSession = _currentSession.copyWith(
        status: 'error',
        errorMessage: 'Failed to save image: $e',
      );
      notifyListeners();
      rethrow;
    }
  }

  /// Upload scan images to backend
  Future<UploadResponse> uploadScan() async {
    try {
      _currentSession.status = 'uploading';
      notifyListeners();

      // Get image files
      final imageFiles = await _cameraService.getScanImages(sessionId);
      
      if (imageFiles.isEmpty) {
        throw Exception('No images to upload');
      }

      // Get device info
      final deviceInfo = await _uploadService.getDeviceInfo();

      // Upload to backend
      final response = await _uploadService.uploadScanImages(
        sessionId: sessionId,
        imageFiles: imageFiles,
        deviceInfo: deviceInfo,
      );

      if (response.isSuccess) {
        _currentSession = _currentSession.copyWith(
          status: 'completed',
          errorMessage: null,
        );
      } else {
        _currentSession = _currentSession.copyWith(
          status: 'error',
          errorMessage: response.message ?? 'Upload failed',
        );
      }

      notifyListeners();
      return response;
    } catch (e) {
      _currentSession = _currentSession.copyWith(
        status: 'error',
        errorMessage: 'Upload error: $e',
      );
      notifyListeners();
      rethrow;
    }
  }

  /// Clear current session (reset for new scan)
  Future<void> clearSession() async {
    try {
      await _cameraService.clearScanImages(sessionId);
      startNewSession();
    } catch (e) {
      _currentSession = _currentSession.copyWith(
        status: 'error',
        errorMessage: 'Failed to clear session: $e',
      );
      notifyListeners();
    }
  }

  /// Get total size of scan images (formatted)
  Future<String> getScanSize() async {
    final bytes = await _cameraService.getScanSize(sessionId);
    return CameraService.formatBytes(bytes);
  }
}
