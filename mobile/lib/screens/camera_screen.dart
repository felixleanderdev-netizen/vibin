import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/scan_session_provider.dart';

/// Camera scanning screen - main scanning UI
/// Task 1.3 will implement actual camera functionality
class CameraScreen extends StatefulWidget {
  const CameraScreen({Key? key}) : super(key: key);

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late ScanSessionProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = context.read<ScanSessionProvider>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Body Scan'),
        backgroundColor: Colors.blue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _showExitDialog(context),
        ),
      ),
      body: Consumer<ScanSessionProvider>(
        builder: (context, provider, _) {
          return Stack(
            children: [
              // Camera Preview Area (Placeholder for Task 1.3)
              Container(
                color: Colors.black,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.camera_alt,
                        size: 80,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Camera implementation coming...',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Placeholder message
                      Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Task 1.3:\nImplement camera feed, capture UI,\nimage storage, and guidance text',
                          style: TextStyle(
                            color: Colors.white,
                            height: 1.6,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Guidance Overlay (will be enhanced in Task 1.3)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.black54,
                  child: Column(
                    children: [
                      const Text(
                        'Stand straight, arms at sides',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Image ${provider.imageCount} of ${provider.targetImageCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Controls
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    border: Border(
                      top: BorderSide(
                        color: Colors.grey[700]!,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Progress bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: provider.progress,
                          minHeight: 8,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            provider.isComplete ? Colors.green : Colors.blue,
                          ),
                          backgroundColor: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Capture button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => _showExitDialog(context),
                            icon: const Icon(Icons.close),
                            label: const Text('Cancel'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade700,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          FloatingActionButton.large(
                            onPressed: _isCaptureable(provider)
                              ? () => _showCapturedDialog(context, provider)
                              : null,
                            backgroundColor: _isCaptureable(provider)
                              ? Colors.blue
                              : Colors.grey,
                            child: const Icon(Icons.camera_alt, size: 32),
                          ),
                          ElevatedButton.icon(
                            onPressed: provider.isComplete
                              ? () => Navigator.of(context).pushNamed(
                                  '/upload_summary',
                                )
                              : null,
                            icon: const Icon(Icons.check),
                            label: const Text('Done'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  bool _isCaptureable(ScanSessionProvider provider) {
    return provider.imageCount < provider.targetImageCount &&
        provider.status == 'capturing';
  }

  void _showCapturedDialog(
    BuildContext context,
    ScanSessionProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Image Captured'),
        content: Text('${provider.imageCount} / ${provider.targetImageCount}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showExitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Scan?'),
        content: const Text(
          'This will discard all captured images.\nAre you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue Scanning'),
          ),
          TextButton(
            onPressed: () async {
              await _provider.clearSession();
              if (mounted) {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back to welcome
              }
            },
            child: const Text(
              'Discard',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
