import 'package:flutter/material.dart';
import '../models/print_models.dart';
import '../services/print_service.dart';

/// Print order configuration and submission screen
class PrintOrderWidget extends StatefulWidget {
  final String sessionId;
  final VoidCallback onOrderComplete;

  const PrintOrderWidget({
    Key? key,
    required this.sessionId,
    required this.onOrderComplete,
  }) : super(key: key);

  @override
  State<PrintOrderWidget> createState() => _PrintOrderWidgetState();
}

class _PrintOrderWidgetState extends State<PrintOrderWidget> {
  final PrintService _service = PrintService();
  PrintStats? _stats;
  bool _isLoading = true;
  String? _errorMessage;

  // Print settings
  String _selectedMaterial = 'PLA';
  String _selectedQuality = 'standard';
  int _quantity = 1;
  String _selectedFinish = 'raw';
  bool _isSubmitting = false;

  final List<String> _materials = ['PLA', 'ABS', 'PETG', 'Resin'];
  final List<String> _qualities = ['draft', 'standard', 'premium'];
  final List<String> _finishes = ['raw', 'sanded', 'painted'];

  @override
  void initState() {
    super.initState();
    _loadPrintStats();
  }

  Future<void> _loadPrintStats() async {
    try {
      final stats = await _service.getPrintStats(widget.sessionId);
      setState(() {
        _stats = stats;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _submitOrder() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      final settings = PrintSettings(
        material: _selectedMaterial,
        quality: _selectedQuality,
        quantity: _quantity,
        finishType: _selectedFinish,
      );

      final result = await _service.submitPrintOrder(widget.sessionId, settings);

      if (!mounted) return;

      // Show success dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Order Confirmed! ✓'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Your 3D print order has been submitted.'),
              const SizedBox(height: 16),
              _buildOrderDetailRow('Order ID', result.orderId),
              const SizedBox(height: 8),
              _buildOrderDetailRow('Material', _selectedMaterial),
              const SizedBox(height: 8),
              _buildOrderDetailRow('Quality', _selectedQuality),
              const SizedBox(height: 8),
              _buildOrderDetailRow('Quantity', '$_quantity'),
              const SizedBox(height: 8),
              _buildOrderDetailRow('Finish', _selectedFinish),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Estimated Shipping',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      result.estimatedShipping.toString().split('.')[0],
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                widget.onOrderComplete();
              },
              child: const Text('Done'),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to submit order: $e';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Widget _buildOrderDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null || _stats == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Failed to load print information',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPrintStats,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (!_stats!.stlValid) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.warning, color: Colors.orange, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Model Not Ready for Printing',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _stats!.validationMessage ?? 'The 3D model cannot be printed',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Text(
            'Order 3D Print',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),

          // Model Info Card
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Model Details',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow('Dimensions', _stats!.dimensionsText),
                  const SizedBox(height: 10),
                  _buildInfoRow(
                    'Estimated Weight',
                    '${_stats!.estimatedWeightGrams.toStringAsFixed(0)}g',
                  ),
                  const SizedBox(height: 10),
                  _buildInfoRow(
                    'Print Time',
                    '${_stats!.estimatedPrintTimeHours.toStringAsFixed(1)}h',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Print Settings
          const Text(
            'Print Settings',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Material Selection
          const Text('Material'),
          const SizedBox(height: 8),
          _buildDropdown(
            value: _selectedMaterial,
            items: _materials,
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedMaterial = value);
              }
            },
          ),
          const SizedBox(height: 16),

          // Quality Selection
          const Text('Quality'),
          const SizedBox(height: 8),
          _buildDropdown(
            value: _selectedQuality,
            items: _qualities,
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedQuality = value);
              }
            },
          ),
          const SizedBox(height: 16),

          // Finish Selection
          const Text('Finish Type'),
          const SizedBox(height: 8),
          _buildDropdown(
            value: _selectedFinish,
            items: _finishes,
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedFinish = value);
              }
            },
          ),
          const SizedBox(height: 16),

          // Quantity
          const Text('Quantity'),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                icon: const Icon(Icons.remove),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _quantity.toString(),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              IconButton(
                onPressed: () => setState(() => _quantity++),
                icon: const Icon(Icons.add),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Cost Estimate
          Card(
            color: Colors.green[50],
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Estimated Cost',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    _stats!.costEstimate,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Submit Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _submitOrder,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.shopping_cart),
              label: Text(_isSubmitting ? 'Submitting...' : 'Place Order'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Disclaimer
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Your model will be reviewed and printed at our facility. '
              'You will receive tracking information once printing begins.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(4),
      ),
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        underline: const SizedBox(),
        items: items.map((item) {
          return DropdownMenuItem(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}