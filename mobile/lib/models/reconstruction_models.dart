/// Reconstruction status model - matches backend API
class ReconstructionStatus {
  final String sessionId;
  final String status; // not_started, processing, succeeded, failed
  final DateTime updatedAt;
  final String message;
  final String? modelPath; // Point cloud PLY
  final String? meshObjPath; // Processed OBJ mesh
  final String? meshStlPath; // Processed STL mesh (for 3D printing)

  ReconstructionStatus({
    required this.sessionId,
    required this.status,
    required this.updatedAt,
    required this.message,
    this.modelPath,
    this.meshObjPath,
    this.meshStlPath,
  });

  factory ReconstructionStatus.fromJson(Map<String, dynamic> json) {
    return ReconstructionStatus(
      sessionId: json['sessionId'] as String,
      status: json['status'] as String,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      message: json['message'] as String,
      modelPath: json['modelPath'] as String?,
      meshObjPath: json['meshObjPath'] as String?,
      meshStlPath: json['meshStlPath'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'status': status,
      'updatedAt': updatedAt.toIso8601String(),
      'message': message,
      'modelPath': modelPath,
      'meshObjPath': meshObjPath,
      'meshStlPath': meshStlPath,
    };
  }

  bool get isComplete => status == 'succeeded';
  bool get isFailed => status == 'failed';
  bool get isProcessing => status == 'processing';
}

/// Body measurements model - matches backend API
class MeasurementResult {
  final String sessionId;
  final int neckGirthMm;
  final int leftArmGirthMm;
  final int rightArmGirthMm;
  final int leftLegGirthMm;
  final int rightLegGirthMm;
  final DateTime createdAt;
  final double confidence;

  MeasurementResult({
    required this.sessionId,
    required this.neckGirthMm,
    required this.leftArmGirthMm,
    required this.rightArmGirthMm,
    required this.leftLegGirthMm,
    required this.rightLegGirthMm,
    required this.createdAt,
    required this.confidence,
  });

  factory MeasurementResult.fromJson(Map<String, dynamic> json) {
    return MeasurementResult(
      sessionId: json['sessionId'] as String,
      neckGirthMm: json['neckGirthMm'] as int,
      leftArmGirthMm: json['leftArmGirthMm'] as int,
      rightArmGirthMm: json['rightArmGirthMm'] as int,
      leftLegGirthMm: json['leftLegGirthMm'] as int,
      rightLegGirthMm: json['rightLegGirthMm'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      confidence: (json['confidence'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'neckGirthMm': neckGirthMm,
      'leftArmGirthMm': leftArmGirthMm,
      'rightArmGirthMm': rightArmGirthMm,
      'leftLegGirthMm': leftLegGirthMm,
      'rightLegGirthMm': rightLegGirthMm,
      'createdAt': createdAt.toIso8601String(),
      'confidence': confidence,
    };
  }

  // Helper to get measurements as a map for display
  Map<String, int> get measurements => {
    'Neck': neckGirthMm,
    'Left Arm': leftArmGirthMm,
    'Right Arm': rightArmGirthMm,
    'Left Leg': leftLegGirthMm,
    'Right Leg': rightLegGirthMm,
  };
}