# Form-Fitting Prints - Mobile App

Flutter application for capturing detailed body scans using a smartphone camera and uploading to the backend for processing.

## Getting Started

### Prerequisites

- **Flutter 3.0.0+** ([Install Flutter](https://flutter.dev/docs/get-started/install))
- **Dart 3.0.0+** (comes with Flutter)
- Android Studio (for Android) or Xcode (for iOS)
- A physical device or emulator

### Installation

1. Get dependencies:
```bash
flutter pub get
```

2. (iOS only) Install pods:
```bash
cd ios && pod install && cd ..
```

### Running the App

**On an emulator/simulator**:
```bash
flutter run
```

**On a physical device**:
```bash
flutter devices  # List connected devices
flutter run -d <device-id>
```

## Project Structure

```
mobile/
├── lib/
│   ├── main.dart              # App entry point
│   ├── screens/               # UI screens (coming soon)
│   │   ├── scanning_screen.dart
│   │   └── upload_screen.dart
│   ├── services/              # Business logic
│   │   ├── camera_service.dart
│   │   └── upload_service.dart
│   ├── models/                # Data models
│   │   └── scan_session.dart
│   └── widgets/               # Reusable UI components
│       └── guidance_widget.dart
├── android/                   # Android native code
├── ios/                       # iOS native code
├── web/                       # Web platform support (N/A for this project)
├── pubspec.yaml               # Dependencies
└── README.md                  # This file
```

## Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| camera | ^0.10.5 | Smartphone camera access |
| http | ^1.1.0 | HTTP client for uploads |
| provider | ^6.0.0 | State management |
| path_provider | ^2.1.0 | File system access |

## Features

### Phase 1 (Current)
- [x] Basic app scaffold
- [ ] Camera preview + capture
- [ ] Image storage (local temp directory)
- [ ] Upload to backend with progress
- [ ] Guided scanning UI

## Platform-Specific Setup

### iOS

**Permissions** (`ios/Runner/Info.plist`):
```xml
<key>NSCameraUsageDescription</key>
<string>We need access to your camera to scan your body.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>We need access to save scan images.</string>
```

**Build & Run**:
```bash
flutter run -d iphone
```

### Android

**Permissions** (`android/app/src/main/AndroidManifest.xml`):
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
```

**Build & Run**:
```bash
flutter run -d emulator-5554
```

## Testing

```bash
flutter test
```

## Troubleshooting

**Camera not working?**
- Verify permissions are granted in app settings
- Ensure device has a camera
- Check logs: `flutter logs`

**Build errors?**
```bash
flutter clean
flutter pub get
flutter run
```

## Development Notes

- **No JavaScript**: Project uses only Dart
- **Target SDK**: iOS 12.0+, Android 9.0+ (API 28+)
- **State Management**: Provider for simplicity
- **AR Integration**: Coming in Phase 5 (ARCore/ARKit plugins)

## Future Phases

- [ ] **Phase 1**: Scanning UI + upload
- [ ] **Phase 2**: 3D preview (basic mesh display)
- [ ] **Phase 3**: AR try-on (ARCore/ARKit)
- [ ] **Phase 4**: Order + payment integration

---

**Last Updated**: 2026-03-30
