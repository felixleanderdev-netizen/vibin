import 'package:flutter/foundation.dart';

/// Provider for managing scanning guidance text and progression
class GuidanceProvider extends ChangeNotifier {
  static const List<String> guidanceSequence = [
    'Stand straight, arms at sides',
    'Rotate 45° (left side toward camera)',
    'Rotate 90° (profile view)',
    'Rotate 135° (far left side)',
    'Return to facing camera',
    'Raise arms above head',
    'Return arms to sides',
    'Turn to look from side, arms down',
    'Step back slightly',
    'Hold steady for final images',
  ];

  int _currentStep = 0;
  int _imageCount = 0;

  int get currentStep => _currentStep;
  String get currentGuidance => _getCurrentGuidance();
  int get imageCount => _imageCount;
  double get progressPercentage => (_imageCount / 50.0).clamp(0, 1);

  /// Get guidance text based on image count (rough progression)
  String _getCurrentGuidance() {
    final step = (_imageCount ~/ 5).clamp(0, guidanceSequence.length - 1);
    return guidanceSequence[step];
  }

  /// Update image count and refresh guidance
  void updateImageCount(int count) {
    _imageCount = count;
    notifyListeners();
  }

  /// Reset guidance for new scan
  void reset() {
    _currentStep = 0;
    _imageCount = 0;
    notifyListeners();
  }
}
