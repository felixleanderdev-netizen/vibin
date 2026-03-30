class UploadResponse {
  final String sessionId;
  final int imagesReceived;
  final String status;
  final DateTime timestamp;
  final String? message;

  UploadResponse({
    required this.sessionId,
    required this.imagesReceived,
    required this.status,
    required this.timestamp,
    this.message,
  });

  factory UploadResponse.fromJson(Map<String, dynamic> json) {
    return UploadResponse(
      sessionId: json['sessionId'] ?? '',
      imagesReceived: json['imagesReceived'] ?? 0,
      status: json['status'] ?? 'error',
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
      message: json['message'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'imagesReceived': imagesReceived,
      'status': status,
      'timestamp': timestamp.toIso8601String(),
      'message': message,
    };
  }

  bool get isSuccess => status == 'success' || status == 'completed';
}
