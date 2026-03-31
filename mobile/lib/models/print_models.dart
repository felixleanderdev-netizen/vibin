/// Print order configuration model
class PrintSettings {
  final String material; // PLA, ABS, PETG, Resin
  final String quality; // draft, standard, premium
  final int quantity;
  final String finishType; // raw, sanded, painted

  PrintSettings({
    this.material = 'PLA',
    this.quality = 'standard',
    this.quantity = 1,
    this.finishType = 'raw',
  });

  Map<String, dynamic> toJson() {
    return {
      'material': material,
      'quality': quality,
      'quantity': quantity,
      'finishType': finishType,
    };
  }
}

/// Print statistics model
class PrintStats {
  final bool stlValid;
  final String? validationMessage;
  final List<double>? dimensionsMm;
  final double estimatedWeightGrams;
  final double estimatedPrintTimeHours;

  PrintStats({
    required this.stlValid,
    this.validationMessage,
    this.dimensionsMm,
    this.estimatedWeightGrams = 0,
    this.estimatedPrintTimeHours = 0,
  });

  factory PrintStats.fromJson(Map<String, dynamic> json) {
    List<double>? parseDims(dynamic dims) {
      if (dims == null) return null;
      if (dims is List) {
        return List<double>.from(dims.cast<double>());
      }
      return null;
    }

    return PrintStats(
      stlValid: json['stlValid'] as bool? ?? false,
      validationMessage: json['validationMessage'] as String?,
      dimensionsMm: parseDims(json['dimensionsMm']),
      estimatedWeightGrams: (json['estimatedWeightGrams'] as num?)?.toDouble() ?? 0,
      estimatedPrintTimeHours: (json['estimatedPrintTimeHours'] as num?)?.toDouble() ?? 0,
    );
  }

  String get dimensionsText {
    if (dimensionsMm == null || dimensionsMm!.isEmpty) return 'N/A';
    return '${dimensionsMm![0].toStringAsFixed(1)} × ${dimensionsMm![1].toStringAsFixed(1)} × ${dimensionsMm![2].toStringAsFixed(1)} mm';
  }

  String get costEstimate {
    // Rough cost estimate: $0.10 per gram + material multiplier
    final baseCost = estimatedWeightGrams * 0.10;
    final materialMultiplier = {
      'PLA': 1.0,
      'ABS': 1.2,
      'PETG': 1.3,
      'Resin': 2.0,
    };
    return '\$${(baseCost * 1.5).toStringAsFixed(2)}'; // Rough estimate
  }
}

/// Print order result from server
class PrintOrderResult {
  final String orderId;
  final String sessionId;
  final String status;
  final DateTime estimatedShipping;
  final String message;

  PrintOrderResult({
    required this.orderId,
    required this.sessionId,
    required this.status,
    required this.estimatedShipping,
    required this.message,
  });

  factory PrintOrderResult.fromJson(Map<String, dynamic> json) {
    return PrintOrderResult(
      orderId: json['orderId'] as String,
      sessionId: json['sessionId'] as String,
      status: json['status'] as String,
      estimatedShipping: DateTime.parse(json['estimatedShipping'] as String),
      message: json['message'] as String,
    );
  }
}