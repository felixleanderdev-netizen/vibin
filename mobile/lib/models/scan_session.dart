class ScanSession {
  final String id;
  final DateTime createdAt;
  final List<String> imageFilePaths;
  final int targetImageCount;
  String status; // pending, capturing, uploading, completed, error
  String? errorMessage;

  ScanSession({
    required this.id,
    required this.createdAt,
    this.imageFilePaths = const [],
    this.targetImageCount = 50,
    this.status = 'pending',
    this.errorMessage,
  });

  int get imageCount => imageFilePaths.length;
  double get progress => targetImageCount > 0 
    ? (imageCount / targetImageCount).clamp(0, 1)
    : 0;
  bool get isComplete => imageCount >= targetImageCount;

  ScanSession copyWith({
    String? id,
    DateTime? createdAt,
    List<String>? imageFilePaths,
    int? targetImageCount,
    String? status,
    String? errorMessage,
  }) {
    return ScanSession(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      imageFilePaths: imageFilePaths ?? this.imageFilePaths,
      targetImageCount: targetImageCount ?? this.targetImageCount,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
