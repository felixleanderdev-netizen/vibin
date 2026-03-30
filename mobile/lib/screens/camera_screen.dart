import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import '../providers/scan_session_provider.dart';
import '../providers/guidance_provider.dart';
import '../services/camera_service.dart';

/// Camera scanning screen - main scanning UI with live camera feed
class CameraScreen extends StatefulWidget {
  const CameraScreen({Key? key}) : super(key: key);

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _cameraController;
  late Future<void> _initializeControllerFuture;
  late ScanSessionProvider _scanProvider;
  late GuidanceProvider _guidanceProvider;
  late CameraService _cameraService;
  bool _isCapturing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _scanProvider = context.read<ScanSessionProvider>();
    _guidanceProvider = context.read<GuidanceProvider>();
    _cameraService = CameraService();
    
    // Initialize fresh scan session
    _scanProvider.startNewSession();
    _guidanceProvider.reset();
    
    // Initialize camera
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      // Get available cameras
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _errorMessage = 'No cameras available on this device';
        });
        return;
      }

      // Use the back camera
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      _initializeControllerFuture = _cameraController.initialize();
      setState(() {});
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to initialize camera: $e';
      });
    }
  }

  Future<void> _captureImage() async {
    if (_isCapturing || _scanProvider.isComplete) return;

    setState(() {
      _isCapturing = true;
    });

    try {
      // Take a picture
      final image = await _cameraController.takePicture();
      final imageFile = File(image.path);

      // Save to scan session
      await _scanProvider.addImage(imageFile);

      // Update guidance
      _guidanceProvider.updateImageCount(_scanProvider.imageCount);

      // Flash feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Image ${_scanProvider.imageCount} captured',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.green,
            duration: const Duration(milliseconds: 800),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to capture image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
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
      body: _errorMessage != null
          ? _buildErrorScreen()
          : Consumer2<ScanSessionProvider, GuidanceProvider>(
              builder: (context, scanProvider, guidanceProvider, _) {
                return FutureBuilder<void>(
                  future: _initializeControllerFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      return _buildCameraScreen(
                        context,
                        scanProvider,
                        guidanceProvider,
                      );
                    } else {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }
                  },
                );
              },
            ),
    );
  }

  Widget _buildErrorScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.red[300],
          ),
          const SizedBox(height: 24),
          Text(
            'Camera Error',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              _errorMessage ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraScreen(
    BuildContext context,
    ScanSessionProvider scanProvider,
    GuidanceProvider guidanceProvider,
  ) {
    return Stack(
      children: [
        // Camera Preview (Full Screen)
        CameraPreview(_cameraController),

        // Guidance Overlay (Top)
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black87, Colors.transparent],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Text(
                    guidanceProvider.currentGuidance,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  // Frame counter badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _getProgressColor(
                        scanProvider.imageCount,
                        scanProvider.targetImageCount,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${scanProvider.imageCount} / ${scanProvider.targetImageCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Bottom Controls
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black87, Colors.transparent],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: scanProvider.progress,
                      minHeight: 8,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getProgressColor(
                          scanProvider.imageCount,
                          scanProvider.targetImageCount,
                        ),
                      ),
                      backgroundColor: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Button Controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Cancel button
                      ElevatedButton.icon(
                        onPressed: () => _showExitDialog(context),
                        icon: const Icon(Icons.close),
                        label: const Text('Cancel'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                          ),
                        ),
                      ),

                      // Capture button (main action)
                      FloatingActionButton.large(
                        onPressed: _isCapturing ||
                                scanProvider.isComplete ||
                                _cameraController.value.isTakingPicture
                            ? null
                            : _captureImage,
                        backgroundColor: _getProgressColor(
                          scanProvider.imageCount,
                          scanProvider.targetImageCount,
                        ),
                        disabledElevation: 0,
                        child: _isCapturing
                            ? const SizedBox(
                                width: 32,
                                height: 32,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(Icons.camera_alt, size: 32),
                      ),

                      // Done button
                      ElevatedButton.icon(
                        onPressed: scanProvider.isComplete
                            ? () {
                                Navigator.of(context).pushNamed(
                                  '/upload_summary',
                                );
                              }
                            : null,
                        icon: const Icon(Icons.check),
                        label: const Text('Done'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                          ),
                          disabledBackgroundColor: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        // Center alignment guide (optional visual aid)
        Center(
          child: Container(
            width: 120,
            height: 200,
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.white30,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                'Stand\nHere',
                style: TextStyle(
                  color: Colors.white30,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _getProgressColor(int current, int target) {
    final percentage = current / target;
    if (percentage < 0.33) return Colors.orange;
    if (percentage < 0.66) return Colors.amber;
    if (percentage < 1.0) return Colors.blue;
    return Colors.green;
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
              await _scanProvider.clearSession();
              _guidanceProvider.reset();
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
