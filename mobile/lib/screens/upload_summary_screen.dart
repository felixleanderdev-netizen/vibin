import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/scan_session_provider.dart';

/// Upload summary screen - shows captured images and upload status
class UploadSummaryScreen extends StatefulWidget {
  const UploadSummaryScreen({Key? key}) : super(key: key);

  @override
  State<UploadSummaryScreen> createState() => _UploadSummaryScreenState();
}

class _UploadSummaryScreenState extends State<UploadSummaryScreen> {
  bool _isUploading = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Scan'),
        backgroundColor: Colors.blue,
        elevation: 0,
        automaticallyImplyLeading: !_isUploading,
      ),
      body: Consumer<ScanSessionProvider>(
        builder: (context, provider, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Text(
                    'Scan Summary',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // Summary Card
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildSummaryRow(
                          'Images Captured',
                          '${provider.imageCount}',
                        ),
                        const SizedBox(height: 12),
                        _buildSummaryRow(
                          'Status',
                          provider.status,
                          statusColor: _getStatusColor(provider.status),
                        ),
                        const SizedBox(height: 12),
                        FutureBuilder<String>(
                          future: provider.getScanSize(),
                          builder: (context, snapshot) {
                            return _buildSummaryRow(
                              'Total Size',
                              snapshot.data ?? 'Calculating...',
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Action Buttons
                if (!_isUploading) ...[
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        border: Border.all(color: Colors.red),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Error: $_errorMessage',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: provider.imageCount > 0
                        ? () => _uploadScan(context, provider)
                        : null,
                      icon: const Icon(Icons.cloud_upload),
                      label: const Text('Upload to Server'),
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
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.edit),
                      label: const Text('Retake Scan'),
                    ),
                  ),
                ] else ...[
                  // Upload in progress
                  const Center(
                    child: CircularProgressIndicator(),
                  ),
                  const SizedBox(height: 16),
                  const Center(
                    child: Text('Uploading images...'),
                  ),
                ],

                const SizedBox(height: 32),

                // Info section
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Your scan images will be processed to extract body measurements. '
                    'This typically takes a few minutes. You will be able to preview '
                    'the fitted object once processing is complete.',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? statusColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor?.withOpacity(0.2),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: statusColor ?? Colors.transparent,
            ),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'capturing':
        return Colors.orange;
      case 'uploading':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'error':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _uploadScan(
    BuildContext context,
    ScanSessionProvider provider,
  ) async {
    setState(() {
      _isUploading = true;
      _errorMessage = null;
    });

    try {
      final response = await provider.uploadScan();

      if (!mounted) return;

      if (response.isSuccess) {
        // Show success dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Upload Successful'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Session ID: ${response.sessionId}'),
                const SizedBox(height: 8),
                Text('Images received: ${response.imagesReceived}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Go back to first screen
                  Navigator.pop(context); // Go back to welcome
                },
                child: const Text('Done'),
              ),
            ],
          ),
        );
      } else {
        setState(() {
          _errorMessage = response.message ?? 'Upload failed';
          _isUploading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isUploading = false;
      });
    }
  }
}
