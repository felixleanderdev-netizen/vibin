import 'dart:async';
import 'package:flutter/material.dart';
import '../models/reconstruction_models.dart';
import '../services/reconstruction_service.dart';

/// Reconstruction status screen - shows processing progress and final results
class ReconstructionStatusScreen extends StatefulWidget {
  final String sessionId;

  const ReconstructionStatusScreen({
    Key? key,
    required this.sessionId,
  }) : super(key: key);

  @override
  State<ReconstructionStatusScreen> createState() => _ReconstructionStatusScreenState();
}

class _ReconstructionStatusScreenState extends State<ReconstructionStatusScreen> {
  final ReconstructionService _service = ReconstructionService();
  ReconstructionStatus? _status;
  MeasurementResult? _measurements;
  Timer? _pollTimer;
  String? _errorMessage;
  bool _isReconstructionTriggered = false;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    // Poll immediately, then every 3 seconds
    _pollStatus();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _pollStatus();
    });
  }

  Future<void> _pollStatus() async {
    try {
      final status = await _service.getReconstructionStatus(widget.sessionId);
      setState(() {
        _status = status;
        _errorMessage = null;
      });

      if (status.status == 'not_started' && !_isReconstructionTriggered) {
        _isReconstructionTriggered = true;
        try {
          await _service.startReconstruction(widget.sessionId);
          setState(() {
            _status = ReconstructionStatus(
              sessionId: widget.sessionId,
              status: 'processing',
              updatedAt: DateTime.now(),
              message: 'Reconstruction started',
            );
          });
        } catch (ex) {
          _pollTimer?.cancel();
          setState(() {
            _status = ReconstructionStatus(
              sessionId: widget.sessionId,
              status: 'failed',
              updatedAt: DateTime.now(),
              message: 'Failed to start reconstruction: $ex',
            );
            _errorMessage = null;
          });
          return;
        }
      }

      // If completed, get measurements and stop polling
      if (status.isComplete) {
        _pollTimer?.cancel();
        await _loadMeasurements();
      }

      // If failed, stop polling (user can retry by returning)
      if (status.isFailed) {
        _pollTimer?.cancel();
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _loadMeasurements() async {
    try {
      final measurements = await _service.getMeasurements(widget.sessionId);
      setState(() {
        _measurements = measurements;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load measurements: $e';
      });
    }
  }

  Future<void> _downloadModel() async {
    try {
      final url = await _service.downloadModel(widget.sessionId);
      // In a real app, you'd open this URL or save the file
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Point cloud available at: $url')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to download model: $e')),
      );
    }
  }

  Future<void> _downloadMeshStl() async {
    try {
      final url = await _service.downloadMeshStl(widget.sessionId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('STL mesh ready for download')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to download STL: $e')),
      );
    }
  }

  Future<void> _downloadMeshObj() async {
    try {
      final url = await _service.downloadMeshObj(widget.sessionId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('OBJ mesh ready for download')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to download OBJ: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Processing Scan'),
        backgroundColor: Colors.blue,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Padding(
              padding: EdgeInsets.only(bottom: 24),
              child: Text(
                '3D Reconstruction',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Session ID
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Session ID',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.sessionId,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Status Card
            if (_status != null) ...[
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _getStatusIcon(_status!.status),
                            color: _getStatusColor(_status!.status),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Status: ${_status!.status.toUpperCase()}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _getStatusColor(_status!.status),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _status!.message,
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Last updated: ${_formatDateTime(_status!.updatedAt)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else if (_errorMessage != null) ...[
              Card(
                elevation: 2,
                color: Colors.red.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.error, color: Colors.red),
                          SizedBox(width: 12),
                          Text(
                            'Connection Error',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              const Card(
                elevation: 2,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(width: 16),
                      Text('Connecting to server...'),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Measurements (when complete)
            if (_measurements != null) ...[
              const Text(
                'Body Measurements',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      ..._measurements!.measurements.entries.map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                entry.key,
                                style: const TextStyle(fontSize: 16),
                              ),
                              Text(
                                '${entry.value} mm',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Confidence',
                            style: TextStyle(fontSize: 16),
                          ),
                          Text(
                            '${(_measurements!.confidence * 100).round()}%',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Action buttons
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _downloadMeshStl,
                  icon: const Icon(Icons.download),
                  label: const Text('Download STL (3D Print)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _downloadMeshObj,
                  icon: const Icon(Icons.download),
                  label: const Text('Download OBJ (Modeling)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _downloadModel,
                  icon: const Icon(Icons.download),
                  label: const Text('Download Point Cloud (PLY)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.home),
                  label: const Text('Back to Home'),
                ),
              ),
            ] else if (_status?.isFailed == true) ...[
              // Error state
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  border: Border.all(color: Colors.red),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reconstruction Failed',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'The 3D reconstruction process encountered an error. '
                      'Please try uploading your scan again.',
                      style: TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                ),
              ),
            ] else ...[
              // Processing state
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Processing your scan...',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'This may take several minutes. Please keep the app open.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'processing':
        return Icons.hourglass_top;
      case 'succeeded':
        return Icons.check_circle;
      case 'failed':
        return Icons.error;
      default:
        return Icons.schedule;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'processing':
        return Colors.orange;
      case 'succeeded':
        return Colors.green;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
  }
}