import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Service for managing camera-related operations
class CameraService {
  static final CameraService _instance = CameraService._internal();

  CameraService._internal();

  factory CameraService() {
    return _instance;
  }

  /// Get the temporary directory for storing scan images
  Future<Directory> getScanDirectory(String sessionId) async {
    final tempDir = await getTemporaryDirectory();
    final scanDir = Directory('${tempDir.path}/scans/$sessionId');
    
    if (!await scanDir.exists()) {
      await scanDir.create(recursive: true);
    }
    
    return scanDir;
  }

  /// Get list of image files in a scan session
  Future<List<File>> getScanImages(String sessionId) async {
    final scanDir = await getScanDirectory(sessionId);
    
    if (!await scanDir.exists()) {
      return [];
    }

    final images = scanDir
        .listSync()
        .whereType<File>()
        .where((file) {
          final ext = file.path.toLowerCase();
          return ext.endsWith('.jpg') || 
                 ext.endsWith('.jpeg') || 
                 ext.endsWith('.png');
        })
        .toList();

    // Sort by filename to maintain capture order
    images.sort((a, b) => a.path.compareTo(b.path));
    return images;
  }

  /// Save image file to scan directory
  Future<File> saveImage(String sessionId, File imageFile) async {
    final scanDir = await getScanDirectory(sessionId);
    final images = await getScanImages(sessionId);
    
    // Name sequentially: img_000.jpg, img_001.jpg, etc.
    final fileName = 'img_${images.length.toString().padLeft(3, '0')}.jpg';
    final savedFile = File('${scanDir.path}/$fileName');
    
    // Copy file to scan directory
    await imageFile.copy(savedFile.path);
    
    return savedFile;
  }

  /// Clear all images in a scan session
  Future<void> clearScanImages(String sessionId) async {
    try {
      final scanDir = await getScanDirectory(sessionId);
      if (await scanDir.exists()) {
        await scanDir.delete(recursive: true);
      }
    } catch (e) {
      print('Error clearing scan images: $e');
    }
  }

  /// Get total size of all images in scan session (bytes)
  Future<int> getScanSize(String sessionId) async {
    final images = await getScanImages(sessionId);
    int totalSize = 0;
    
    for (var file in images) {
      totalSize += await file.length();
    }
    
    return totalSize;
  }

  /// Format bytes to human-readable string (e.g., "125 MB")
  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
