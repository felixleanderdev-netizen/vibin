# Development Setup Guide

**Status**: Phase 0/1 Complete — Ready for Phase 1 Development  
**Last Updated**: 2026-03-30

---

## Quick Start

### 1. Backend (C# ASP.NET Core)

#### Prerequisites
- **.NET 9.0 SDK** or later ([Install](https://dotnet.microsoft.com/))
- A text editor or IDE (VS Code, Visual Studio, Rider)

#### Get Running
```bash
cd backend
dotnet restore  # Download dependencies
dotnet build    # Compile
dotnet run      # Start server
```

**Server will be available at**:
- HTTP: `http://localhost:5000`
- HTTPS: `https://localhost:5001`

**Trust HTTPS certificate** (first time only):
```bash
dotnet dev-certs https --trust
```

**Test the API**:
```bash
curl -i https://localhost:5001/health
# Expected: HTTP/1.1 200 OK + {"status":"ok","timestamp":"..."}
```

---

### 2. Mobile (Flutter)

#### Prerequisites
- **Flutter 3.0+** ([Install](https://flutter.dev/docs/get-started/install))
- **Android Studio** (for Android) or **Xcode** (for iOS)
- A device simulator/emulator

#### Get Running
```bash
cd mobile
flutter pub get              # Download dependencies

flutter run                  # Run on default emulator
# OR
flutter run -d <device-id>  # Run on specific device
```

**List available devices**:
```bash
flutter devices
```

**iOS (Mac only)**:
```bash
cd mobile/ios
pod install  # Install iOS dependencies
cd ..
flutter run -d iphone
```

---

## Project Structure

```
formFittingPrints/
├── _ai_workspace/          # 👈 AI Agent Planning & Documentation
│   ├── index.md            # Project state, decisions, risk log
│   └── phase-1.md          # Phase 1 detailed task board
│
├── mobile/                 # 👈 Flutter App (iOS + Android)
│   ├── lib/main.dart       # Entry point
│   ├── pubspec.yaml        # Dependencies
│   └── README.md           # Mobile setup
│
├── backend/                # 👈 C# API Server (ASP.NET Core)
│   ├── Program.cs          # Startup configuration
│   ├── Controllers/
│   │   └── ScansController.cs    # POST /api/scans/upload
│   ├── Models/
│   │   └── ScanModels.cs         # Data classes
│   ├── Services/
│   │   └── ScanStorageService.cs # Business logic
│   ├── scans/              # (Runtime) Upload destination
│   └── README.md           # Backend setup
│
├── 3d-templates/           # 👈 Pre-made Wearable Objects
│   ├── collar.stl
│   ├── armband.stl
│   ├── armor.stl
│   └── README.md           # Template documentation
│
├── docs/                   # 👈 System Documentation
│   ├── API.md              # API endpoint specification
│   ├── DATA_FLOW.md        # Architecture & data flow
│   ├── SCANNING_FLOW.md    # User journey & UX wireframes
│   ├── MEASUREMENTS.md     # Body measurement specs (Phase 3)
│   └── SETUP.md            # This file
│
├── scripts/                # 👈 Utility Scripts (Coming Soon)
│   └── README.md
│
├── .gitignore
└── README.md               # Project overview
```

---

## What's Ready Now (Phase 1 - Setup)

### ✅ Backend
- [x] ASP.NET Core project scaffold
- [x] `POST /api/scans/upload` endpoint (ready to implement)
- [x] Models & services (basic structure)
- [x] Compiles without errors

### ✅ Mobile
- [x] Flutter project structure
- [x] `pubspec.yaml` with required dependencies
- [x] Basic UI scaffold (`lib/main.dart`)
- [x] Ready for camera implementation

### ✅ Documentation
- [x] API specification (`docs/API.md`)
- [x] System architecture (`docs/DATA_FLOW.md`)
- [x] User scanning flow (`docs/SCANNING_FLOW.md`)
- [x] Body measurement specs (`docs/MEASUREMENTS.md`)
- [x] 3D template guidelines (`3d-templates/README.md`)

### ✅ Planning
- [x] Detailed Phase 1 task board (`_ai_workspace/phase-1.md`)
- [x] Risk assessment & mitigation
- [x] Dependency graph & critical path

---

## Next Steps (Phase 1 - Implementation)

### Task 1.2: Flutter Camera UI
- Implement live camera feed with preview
- Add guidance text overlays
- Implement frame capture + local storage

### Task 1.3: API Endpoint Implementation
- Implement multipart file upload handler
- Add image validation (format, size)
- Implement session storage (`./scans/{sessionId}/`)

### Task 1.4: Mobile → Backend Integration
- Build HTTP client for upload
- Implement progress tracking
- Handle network errors & retry logic

### Task 1.5: Testing & Validation
- Create mock image generation script
- Test upload on iOS simulator + Android emulator
- Verify images stored correctly on backend

---

## Important Notes

### Tech Stack (Locked In)
- **Mobile**: Flutter (Dart) — cross-platform
- **Backend**: C# + ASP.NET Core — type-safe, fast
- **3D**: Python + Open3D (Phase 2+)
- **No JavaScript** — entire project

### Development Model
- **Solo dev** (you) + **AI agent** (me) iterating
- **Agile**: Short feedback cycles, test early
- **MVP-first**: Get Phase 1 working, then expand

### Phase Progression
1. **Phase 1** (Current): Scanning pipeline → image upload
2. **Phase 2** (Next): 3D reconstruction (Colmap)
3. **Phase 3**: Measurement extraction (girths)
4. **Phase 4**: Object fitting (template scaling)
5. **Phase 5**: AR preview (try-on)

---

## Troubleshooting

### Backend Build Fails
```bash
cd backend
dotnet clean
dotnet restore
dotnet build
```

### Flutter Pub Get Fails
```bash
cd mobile
flutter clean
flutter pub get
```

### HTTPS Certificate Issues
```bash
dotnet dev-certs https --trust
# macOS: Adds cert to Keychain
# Windows: Installs in system store
# Linux: Copies to ~/.dotnet/corefx/cryptography/x509stores/
```

### Emulator Not Found
```bash
flutter doctor  # Check installation
flutter devices # List available

# Android emulator:
emulator -list-avds
emulator -avd <avd-name>

# iOS simulator:
xcrun simctl list devices
```

---

## Git Workflow

### Initialize Repository
```bash
git init
git add .
git commit -m "Initial project setup: Phase 0/1 complete"
git branch -M main
# Add remote: git remote add origin <url>
# Push: git push -u origin main
```

### Commit Convention
```
[_ai_workspace] phase-1: task board created
[backend] feat: upload endpoint scaffold
[mobile] feat: camera UI placeholder
[docs] feat: API specification
```

---

## Support & Debugging

### View Logs

**Backend**:
```bash
cd backend
dotnet run  # Logs to console
```

**Mobile**:
```bash
flutter logs       # Show device logs
flutter logs -f    # Follow (tail) logs
```

### Enable Debug Output

**C# Backend** (`appsettings.Development.json`):
```json
{
  "Logging": {
    "LogLevel": {
      "Default": "Debug",
      "FormFittingPrints": "Information"
    }
  }
}
```

**Flutter** (in code):
```dart
debugPrint('Debug message here');
```

---

## Next Agent Handoff

When the next AI agent starts working on Phase 1 implementation:

1. **Read** `_ai_workspace/phase-1.md` for detailed task breakdown
2. **Verify** backend compiles: `cd backend && dotnet build`
3. **Verify** mobile structure: `ls -la mobile/lib/`
4. **Check** docs are present: `ls -la docs/`
5. **Start with Task 1.2** (Flutter camera) or **Task 1.3** (API implementation)

---

**Ready to build?** 🚀

Pick a task from `_ai_workspace/phase-1.md` and let's make it happen!

---

**Last Updated**: 2026-03-30
