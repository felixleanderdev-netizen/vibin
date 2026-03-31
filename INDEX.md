# Form-Fitting Prints – Complete Documentation Index

**Current Status**: 🟢 **PHASE 2 COMPLETE** – Full 3D scanning, reconstruction, measurement extraction, and print ordering system

**Last Updated**: March 31, 2026

---

## Quick Overview

**Form-Fitting Prints** is a mobile-first system for creating customized 3D-printed wearables (armor, clothing, accessories) tailored to individual body dimensions. Users scan their body with their smartphone, the system reconstructs a 3D model, extracts body measurements, and offers integration with 3D printing services.

### The Complete Flow

1. **📱 Smartphone Scanning** (Phase 1) – User captures 50 guided images of their body
2. **☁️ Cloud Upload** (Phase 1) – Images validated and stored server-side
3. **🎯 3D Reconstruction** (Phase 2) – Colmap + Poisson surface reconstruction
4. **📏 Measurement Extraction** (Phase 2) – Girth calculations from 3D model
5. **🖨️ Print Ordering** (Phase 2) – Order print-ready STL with custom settings
6. **📦 Down-the-Line** – Template fitting, AR preview, mass customization

---

## Project Structure

```
formFittingPrints/
├── INDEX.md                        ← You are here
├── README.md                       # Project overview & setup quick-start
│
├── mobile/                         # Flutter mobile app
│   ├── lib/
│   │   ├── main.dart             # App entry point
│   │   ├── screens/              # UI screens
│   │   │   ├── welcome_screen.dart
│   │   │   ├── camera_screen.dart           # Live camera + guided capture
│   │   │   ├── upload_summary_screen.dart   # Image review + upload
│   │   │   ├── reconstruction_status_screen.dart  # Status polling
│   │   │   └── print_order_widget.dart      # Print ordering UI
│   │   ├── services/             # HTTP clients
│   │   │   ├── camera_service.dart
│   │   │   ├── upload_service.dart
│   │   │   ├── reconstruction_service.dart
│   │   │   └── print_service.dart
│   │   ├── providers/            # State management (Provider)
│   │   │   ├── scan_session_provider.dart
│   │   │   └── guidance_provider.dart
│   │   └── models/               # Data models
│   │       ├── upload_response.dart
│   │       ├── reconstruction_models.dart
│   │       └── print_models.dart
│   ├── pubspec.yaml              # Dependencies
│   └── README.md                 # Mobile-specific setup
│
├── backend/                        # C# ASP.NET Core 9.0 API
│   ├── Controllers/
│   │   └── ScansController.cs     # All REST endpoints
│   ├── Services/
│   │   ├── ScanStorageService.cs  # Image validation & storage
│   │   └── ReconstructionService.cs  # Colmap + mesh + measurements
│   ├── Models/
│   │   └── ScanModels.cs          # DTO + domain models
│   ├── Program.cs                 # Startup & DI configuration
│   ├── FormFittingPrints.API.csproj
│   └── README.md                 # Backend-specific setup
│
├── scripts/                        # Python/utility scripts
│   ├── measure.py                # Body measurement extraction
│   ├── mesh_processing.py        # Poisson reconstruction + decimation
│   └── validate_stl.py           # STL validation + print stats
│
├── 3d-templates/                  # Pre-made object templates
│   ├── collar.stl
│   ├── armband.stl
│   └── armor.stl
│
├── docs/                          # Detailed documentation
│   ├── SETUP.md                  # Development environment setup
│   ├── API.md                    # REST API reference
│   ├── DATA_FLOW.md              # System architecture
│   ├── SCANNING_FLOW.md          # User journey diagrams
│   └── MEASUREMENTS.md           # Measurement algorithm details
│
└── _ai_workspace/                # AI planning & task boards
    ├── index.md                  # Project state snapshot
    ├── phase-1.md               # Phase 1 task board (COMPLETE)
    └── phase-2.md               # Phase 2 task board (COMPLETE)
```

---

## Technology Stack

### Frontend
- **Flutter (Dart)** – Cross-platform mobile (iOS/Android)
- **Provider** – State management
- **Camera**/**http** – Camera access and API calls

### Backend
- **C# ASP.NET Core 9.0** – REST API
- **OpenAPI/Swagger** – API documentation
- **Logging (ILogger)** – Structured logging

### 3D Processing
- **Colmap** – Structure-from-Motion (SfM) - 3D reconstruction from images
- **Open3D (Python)** – Point cloud processing, Poisson surface reconstruction, measurement extraction
- **Mesh Processing** – Decimation, smoothing, format conversion (PLY, OBJ, STL)

### Storage
- **File-based** (development) – JSON status files, image directories, reconstruction models
- **Future**: S3/Azure Blob for cloud scale

---

## Key Features

### Phase 1: ✅ Complete
- ✅ Guided 50-image body scanning with live camera feed
- ✅ Progress tracking and image validation
- ✅ Multipart HTTP upload with error handling
- ✅ Server-side JPEG/PNG header parsing (no external libs)
- ✅ Session-based organization and status tracking

### Phase 2: ✅ Complete
- ✅ **Colmap 3D Reconstruction**: Feature extraction → matching → sparse reconstruction → model conversion
- ✅ **Mesh Processing**: Outlier removal, Poisson surface reconstruction, Laplacian smoothing, decimation
- ✅ **Body Measurements**: Girth calculation for neck, arms, and legs with confidence scoring
- ✅ **Multi-format Export**: Point cloud (PLY), mesh (OBJ), print-ready (STL)
- ✅ **STL Validation**: File integrity checks, coordinate validation, print statistics estimation
- ✅ **Print Ordering**: Material selection, quality tiers, finish options, cost estimation
- ✅ **Mobile Reconstruction UI**: Real-time status polling, measurement display, download options
- ✅ **Print Order Widget**: Interactive UI with live cost updates and order submission

### Future: Phase 3+
- Template fitting (collar, armband, armor, etc.)
- AR preview of fitted objects
- Payment integration & print service API
- User accounts and history
- Batch processing and queuing

---

## Quick Start

### For Users (Mobile App)
1. Download app from iOS App Store or Google Play (TBD)
2. Tap "Start Scan" → capture 50 guided images
3. Review images → tap "Upload"
4. Monitor reconstruction progress
5. View measurements and order 3D print

### For Developers

#### Backend Setup
```bash
cd backend
dotnet restore
dotnet build
dotnet run
# Runs on http://localhost:5000
```

Requires:
- .NET 9.0 SDK
- `colmap` binary in PATH
- Python 3.9+ with Open3D

#### Mobile Setup
```bash
cd mobile
flutter pub get
flutter run  # Choose device
```

Requires:
- Flutter SDK (latest stable)
- iOS Xcode / Android SDK

See [docs/SETUP.md](docs/SETUP.md) for detailed environment configuration.

---

## API Routes Overview

### Scan Upload (Phase 1)
- `POST /api/scans/{sessionId}/upload` – Upload image batch
- `GET /api/scans/{sessionId}/status` – Check upload status

### Reconstruction (Phase 2)
- `POST /api/scans/{sessionId}/reconstruct` – Start 3D reconstruction
- `GET /api/scans/{sessionId}/reconstruct/status` – Poll reconstruction progress
- `GET /api/scans/{sessionId}/reconstruct/model` – Download point cloud (PLY)
- `GET /api/scans/{sessionId}/mesh/stl` – Download print-ready mesh (STL)
- `GET /api/scans/{sessionId}/mesh/obj` – Download mesh (OBJ)

### Measurements (Phase 2)
- `GET /api/scans/{sessionId}/measurements` – Get body measurements
- `GET /api/scans/{sessionId}/measurements/history` – Get measurement history

### Print Service (Phase 2)
- `GET /api/scans/{sessionId}/print/stats` – Get print statistics & validation  
- `POST /api/scans/{sessionId}/print/order` – Submit print order

See [docs/API.md](docs/API.md) for complete endpoint reference.

---

## Documentation Map

| Document | Purpose |
|----------|---------|
| [README.md](README.md) | Project overview, feature list, quick setup |
| [SETUP.md](docs/SETUP.md) | Development environment, dependencies, troubleshooting |
| [API.md](docs/API.md) | API endpoint reference, request/response schemas, error codes |
| [DATA_FLOW.md](docs/DATA_FLOW.md) | System architecture, data pipeline, component interaction |
| [SCANNING_FLOW.md](docs/SCANNING_FLOW.md) | User journey maps, UI flows, state transitions |
| [MEASUREMENTS.md](docs/MEASUREMENTS.md) | Measurement algorithm, girth calculations, confidence scoring |
| [mobile/README.md](mobile/README.md) | Flutter app structure, running on devices, testing |
| [backend/README.md](backend/README.md) | C# backend structure, running server, debugging |

---

## Running End-to-End

### Scenario: Full Scan → Reconstruction → Print Order

1. **Start Backend**
   ```bash
   cd backend && dotnet run
   ```
   Listens on `http://localhost:5000`

2. **Run Mobile App**
   ```bash
   cd mobile && flutter run
   ```

3. **Walk Through UI**
   - Tap "Start Scan"
   - Capture 50 images (follow guidance)
   - Tap "Done" → "Upload to Server"
   - Wait for upload to complete
   - View reconstruction status (auto-polls every 3 seconds)
   - Once complete, view measurements
   - Tap "Order 3D Print"
   - Select material (PLA/ABS/PETG/Resin), quality (draft/standard/premium), finish
   - Confirm order

4. **Backend Processing**
   - Images stored in `backend/scans/{sessionId}/`
   - Reconstruction in `backend/reconstructions/{sessionId}/`
   - Status JSON in `reconstructions/{sessionId}/status.json`
   - Measurements in `reconstructions/{sessionId}/measurements.json`
   - Print order logged (mock service)

---

## Architecture Highlights

### Separation of Concerns
- **Mobile** (Flutter/Dart): UI, camera, user interaction
- **Backend** (C#/.NET): API, orchestration, business logic
- **Scripts** (Python): Heavy computation (image processing, 3D geometry)

### Async Processing
- Upload: Synchronous (real-time feedback)
- Reconstruction: Async (status polling) – can take 1-5 minutes
- Measurements: Async (extracted after reconstruction)
- Print orders: Async (queued for print service integration)

### Data Flow
```
Images → Validation → Storage → Colmap SfM → Point Cloud → 
Mesh Processing → Measurements & STL → Print Stats → Order
```

### Error Handling
- Image validation (JPEG/PNG headers, dimensions, count)
- Colmap step timeouts & exit code checking
- Mesh integrity validation (NaN/Inf checks)
- STL validation before print (structure, coordinates)
- Graceful fallback (e.g., skip mesh processing if Python fails)

---

## Current Limitations & Next Steps

### Known Limitations
- **File-based storage**: Scales to ~1K sessions on single machine
- **No authentication**: All sessions public (add auth layer in Phase 3)
- **Mock print service**: Print orders logged but not sent to actual printer
- **Single-machine processing**: No job queue or worker distribution
- **No AR preview**: Could visualize fitted objects on user's body

### Recommended Next Steps (Phase 3)
1. **Database Integration**: PostgreSQL for sessions, measurements, orders
2. **Print Service Integration**: Hook up actual 3D printing service (Shapeways, etc.)
3. **Authentication & Authorization**: User accounts, payment, order history
4. **AR Preview**: Show fitted templates on live camera feed
5. **Job Queuing**: Celery/RabbitMQ for distributed reconstruction
6. **Object Storage**: S3/Azure Blob for images and models
7. **Performance**: CDN for downloads, caching for measurements
8. **Analytics**: Track success rates, measurement accuracy, user feedback

---

## Contributing

If you're working on this project:

1. **Read** the relevant docs (e.g., API.md for endpoint changes, MEASUREMENTS.md for algorithm work)
2. **Update** docs when code changes (keep index/README in sync)
3. **Test** end-to-end (scan → reconstruction → measurements → order)
4. **Log decisions** in `_ai_workspace/` for future reference
5. **Review** error handling for new features

---

## Support & Troubleshooting

### Common Issues

**"colmap: command not found"**
- Colmap not in PATH. See SETUP.md for installation.

**"ModuleNotFoundError: No module named 'open3d'"**
- Python dependencies missing. Run: `pip install open3d numpy`

**Images not uploading**
- Check image format (JPEG/PNG), dimensions (>800px), and device storage permissions.

**Reconstruction stuck at "processing"**
- Check backend logs for Colmap errors. May require more/better images.

**STL validation fails**
- Rare: indicates corrupted mesh. Check Open3D/Poisson output.

See [docs/SETUP.md](docs/SETUP.md) for detailed troubleshooting.

---

## Performance Benchmarks

Typical timings (5-core server, 50 images, 4MP):
- **Upload**: 10-30 seconds
- **Feature Extraction**: 30-60 seconds
- **Feature Matching**: 20-40 seconds
- **Sparse Reconstruction**: 60-180 seconds
- **STL Validation**: 5 seconds
- **Measurement Extraction**: 10-20 seconds
- **Total**: 2-6 minutes

---

## License

Proprietary (Wearable Customization Platform)

---

## Contact

Issue tracker: `_ai_workspace/` directory
Documentation: Start here, then see specific docs
Development: See SETUP.md

---

**Last Updated**: March 31, 2026 – Phase 2 Complete ✅
