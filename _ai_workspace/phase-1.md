# Phase 1: Scanning Pipeline

**Goal**: Mobile app captures images → server receives safely  
**Status**: Planning  
**Est. Duration**: 2-3 weeks (solo dev)

---

## 📌 Epic Summary

User scans body with smartphone by capturing multi-image sequence with **guided positioning**. App uploads images securely to C# backend. Server stores images and returns confirmation. This phase validates cross-device camera handling and image quality baseline.

---

## 🎯 Success Criteria

- [ ] iOS + Android Flutter app successfully captures 20-50 images in sequence
- [ ] App provides **rough UI guidance** (e.g., "Stand in center", "Rotate 45°", "Raise arms")
- [ ] Images transmit to backend via HTTPS with progress tracking
- [ ] Backend stores images in organized directory structure (per-scan session)
- [ ] Backend validates image metadata (resolution, timestamp, device info)
- [ ] Test harness verifies on 2+ device types (iOS simulator + Android emulator minimum)
- [ ] Zero data loss during transmission (checksums validated)

---

## 📋 Task Breakdown

### Task 1.1: Project Setup & Structure
**Assignee**: AI Agent  
**Effort**: Low (2 hours)  
**Dependencies**: None  

Create workspace directories:
```
formFittingPrints/
├── mobile/               # Flutter project root
├── backend/              # C# ASP.NET Core root
├── 3d-templates/         # Pre-made object files
├── docs/                 # Documentation
└── _ai_workspace/        # AI planning (existing)
```

**Deliverables**:
- [ ] Directory tree created
- [ ] `.gitignore` configured (Flutter, C#, Python, 3D files)
- [ ] Root `README.md` with project overview

---

### Task 1.2: Flutter Mobile App Scaffold ✅ COMPLETE
**Assignee**: AI Agent  
**Effort**: Medium (4-6 hours) — **Actual: 2 hours**  
**Dependencies**: Task 1.1 ✅  
**Status**: DONE

Initialize Flutter project with dependencies:
- ✅ `camera` (image capture)
- ✅ `http` (image upload)
- ✅ `provider` (state management)
- ✅ `flutter_lints` (code quality)
- ✅ `uuid` (session ID generation)
- ✅ `path_provider` (file storage)

**Deliverables**:
- ✅ Flutter project created via manual scaffold (flutter CLI unavailable)
- ✅ `pubspec.yaml` configured with all dependencies
- ✅ Basic app structure with Material theme
- ✅ **Camera permission handling**:
  - ✅ Android: `AndroidManifest.xml` with camera, storage, internet permissions
  - ✅ iOS: `Info.plist` with NSCameraUsageDescription, NSPhotoLibraryUsageDescription
- ✅ **App folder structure**:
  - ✅ `lib/screens/` — UI screens (welcome, camera, upload summary)
  - ✅ `lib/services/` — Camera + Upload services
  - ✅ `lib/models/` — ScanSession, UploadResponse data classes
  - ✅ `lib/providers/` — ScanSessionProvider for state management
  - ✅ `lib/widgets/` — Reusable UI components (ready for Task 1.3)
- ✅ **Core Services Implemented**:
  - ✅ `CameraService` — Image storage + file management
  - ✅ `UploadService` — Multipart form upload to backend
  - ✅ `ScanSessionProvider` — ChangeNotifier for scan state + operations
- ✅ **Three Screen Implementations**:
  - ✅ `WelcomeScreen` — Guidance + start button
  - ✅ `CameraScreen` — Placeholder with UI skeleton for Task 1.3
  - ✅ `UploadSummaryScreen` — Review scans + initiate upload
- ✅ **Navigation Setup**:
  - ✅ Named routes: `/camera`, `/upload_summary`
  - ✅ MultiProvider integration for state management
  - ✅ Proper routing between screens

---

### Task 1.3: Camera Capture UI with Guidance
**Assignee**: AI Agent  
**Effort**: Medium-High (6-8 hours)  
**Dependencies**: Task 1.2  

Implement guided scanning flow:
1. **Start screen**: "Scan your body. Stand in a well-lit area."
2. **Guidance text**: Numbered steps (1-N rotations/poses)
3. **Live camera preview**: Full-screen, frame counter showing image count
4. **Capture button**: Large, centered; disabled during processing
5. **Progress indicator**: "Image 15 of 50" + upload status
6. **Completion screen**: "Scan complete! Uploading..."

Store images locally (temp directory) before upload.

**Deliverables**:
- [ ] Camera view widget with live preview
- [ ] Guidance text/UI choreography
- [ ] Image capture + local storage logic
- [ ] Frame counter + progress UI
- [ ] Test on simulator (visual validation)

---

### Task 1.4: C# ASP.NET Core Backend Scaffold
**Assignee**: AI Agent  
**Effort**: Medium (4-6 hours)  
**Dependencies**: Task 1.1  

Initialize ASP.NET Core API project:
- Create `dotnet new webapi` project
- Structure: Controllers, Models, Services, Middleware
- Configure HTTPS + CORS
- Add logging (Serilog or built-in)
- Add input validation + error handling

**Deliverables**:
- [ ] `.csproj` file configured
- [ ] Project structure (Controllers, Services, Models)
- [ ] HTTPS certificate (self-signed for dev)
- [ ] Startup middleware (logging, error handling)
- [ ] `appsettings.json` with development profile

---

### Task 1.5: `/upload` Endpoint Implementation
**Assignee**: AI Agent  
**Effort**: Medium (5-7 hours)  
**Dependencies**: Task 1.4  

Implement POST `/api/scans/upload` endpoint:
- Accept multipart form data (multiple image files + session metadata)
- Validate incoming images (file type, max size, resolution)
- Create session directory: `./scans/{sessionId}/images/`
- Store images with sequential naming: `img_001.jpg`, `img_002.jpg`, etc.
- Extract metadata (EXIF, device info) and validate
- Return 200 OK with session ID and frame count confirmation
- Handle partial upload retry logic (resume capability)

**Deliverables**:
- [ ] Multipart file upload handler
- [ ] Session storage (disk-based for MVP)
- [ ] Image validation (format, size, resolution)
- [ ] Metadata extraction and logging
- [ ] Error responses (400, 413 for oversized files, etc.)
- [ ] Integration tests (POST with mock images)

---

### Task 1.6: Mobile → Backend Integration
**Assignee**: AI Agent  
**Effort**: Medium (4-6 hours)  
**Dependencies**: Task 1.3 + Task 1.5  

Connect Flutter app to backend:
- Implement HTTP client in Flutter (upload function)
- Build multipart request with captured images
- Add progress callback (bytes sent / total)
- Handle network errors (retry, timeout)
- Display upload progress to user
- Confirm with backend response (session ID)
- Clear local images on successful upload

**Deliverables**:
- [ ] HTTP client + multipart upload logic
- [ ] Progress tracking UI (upload %)
- [ ] Error handling + retry UI
- [ ] Session ID confirmation display
- [ ] Integration test (app → backend, verify images in directory)

---

### Task 1.7: Test Harness & Validation
**Assignee**: AI Agent  
**Effort**: Medium-High (6-8 hours)  
**Dependencies**: Task 1.6  

Set up test infrastructure:
- Script to generate mock images (various resolutions)
- Automated test on iOS simulator (capture + upload)
- Automated test on Android emulator (capture + upload)
- Backend test: verify session directory, image count, metadata
- Cross-device compatibility test plan (devices & results table)

**Deliverables**:
- [ ] Mock image generation script (Python or bash)
- [ ] Flutter integration test (simulator)
- [ ] Android emulator test (Kotlin/ActivityScenario or equivalent)
- [ ] Backend unit tests (POST endpoint)
- [ ] Test results document (devices, pass/fail, notes)

---

### Task 1.8: Documentation & API Spec
**Assignee**: AI Agent  
**Effort**: Low (2-3 hours)  
**Dependencies**: Task 1.5  

Create documentation:
- `docs/API.md`: Endpoint spec, request/response schemas
- `docs/SCANNING_FLOW.md`: User journey + UI wireframe description
- `backend/README.md`: Setup, build, run instructions
- `mobile/README.md`: Setup, build, run instructions
- System diagram: mobile → backend data flow

**Deliverables**:
- [ ] API documentation (OpenAPI / Swagger optional)
- [ ] Scanning flow walkthrough
- [ ] Backend setup guide
- [ ] Mobile app setup guide
- [ ] Data flow diagram (ASCII or Mermaid)

---

## 📊 Task Dependency Graph

```
Task 1.1 (Setup)
  ├─→ Task 1.2 (Flutter Scaffold)
  │     └─→ Task 1.3 (Camera UI)
  │           └─→ Task 1.6 (Integration)
  │                 └─→ Task 1.7 (Testing)
  │
  └─→ Task 1.4 (Backend Scaffold)
        └─→ Task 1.5 (Upload Endpoint)
              └─→ Task 1.6 (Integration)
                    └─→ Task 1.7 (Testing)

Task 1.5 (Upload) → Task 1.8 (Docs)
Task 1.3 (Camera) → Task 1.8 (Docs)
```

**Critical Path**: 1.1 → 1.2 → 1.3 → 1.6 → 1.7 (Mobile side)  
**Parallel Track**: 1.1 → 1.4 → 1.5 → 1.6 → 1.7 (Backend side)

---

## 🔍 Risk Mitigation

| Risk | Severity | Mitigation |
|------|----------|-----------|
| Cross-device camera differences | HIGH | Prototype on simulator early; test resolution handling |
| Network reliability (file loss) | MEDIUM | Add checksum validation + resume capability in Task 1.5 |
| Large image file uploads (bandwidth) | MEDIUM | Implement chunking in Task 1.6 (future optimization) |
| HTTPS certificate issues | LOW | Use self-signed cert for dev; document setup |
| Image quality variance | MEDIUM | Store metadata (EXIF, device info); log for Phase 2 analysis |

---

## ✅ Acceptance Criteria (Phase 1 Complete)

All tasks 1.1-1.8 are DONE when:
1. ✅ Flutter app successfully captures 30+ images on simulator
2. ✅ Images upload to backend without errors
3. ✅ Backend stores images in organized session directory
4. ✅ Backend validates image metadata and logs issues
5. ✅ Test harness passes on both iOS simulator and Android emulator
6. ✅ Documentation is complete and accurate
7. ✅ Zero data corruption during upload/storage cycle

---

## 📝 Notes

- **Solo dev strategy**: Work Tasks 1.1, 1.4, 1.5 first (backend serial), then 1.2, 1.3, 1.6 (mobile in parallel).
- **Image storage**: MVP uses local disk (`./scans/{sessionId}/`); can migrate to S3 later.
- **Network**: Localhost/127.0.0.1 for dev; will need IP whitelisting for physical device testing.
- **Guidance roughness**: Doesn't need AR or pose estimation yet; simple text + visual counter suffices for MVP.

---

## 🔄 Handoff to Phase 2

Once Phase 1 is complete:
- Archive raw images from Phase 1 test runs
- Use Phase 1 image sets as input for Colmap in Phase 2
- Measure image quality metrics (blur, lighting, coverage)
- Identify tuning needs for cross-device consistency
