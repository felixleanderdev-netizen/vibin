# Quick Start Guide

**TL;DR**: Scan body with phone → upload images → automatic 3D reconstruction → view measurements → order 3D print

---

## 🚀 For New Users (Non-Technical)

1. **Download App** (coming soon to App Stores)
2. **"Start Scan"** on home screen
3. **Follow AR guidance** – hold phone at waist, move in circle capturing 50 images
4. **"Upload"** when done
5. **Wait 2-5 minutes** for 3D reconstruction
6. **View measurements** (neck, arm, leg girths)
7. **"Order Print"** – choose material (PLA/ABS) and quality (draft/standard/premium)
8. **Confirm order** – get tracking number, estimated shipping in 7 days

---

## 👨‍💻 For Developers (Setup in 10 Minutes)

### Prerequisites
```bash
# Check you have these installed:
dotnet --version        # Should be 9.0 or higher
flutter --version       # Should be latest stable
python3 --version       # Should be 3.9 or higher
colmap -h               # If not: see SETUP.md
```

### Clone & Navigate
```bash
cd formFittingPrints
# You're here!
```

### Start Backend
```bash
cd backend
dotnet restore
dotnet build
dotnet run
# Listen on http://localhost:5000
# Ctrl+C to stop
```

### (In new terminal) Start Mobile
```bash
cd mobile
flutter pub get
flutter run
# Select device (Android emulator, iOS simulator, or physical device)
```

### Take a Test Scan
1. **App**: "Start Scan"
2. **Camera**: Capture ~50 images (or just tap quickly 50 times for test)
3. **App**: "Done" → "Upload"
4. **Backend logs**: Should show image upload, reconstruction starting
5. **App**: Automatically polls for status update
6. **Wait**: 2-5 minutes for backend processing
7. **App**: Shows measurements and print order button

### Troubleshooting

| Issue | Fix |
|-------|-----|
| `colmap: command not found` | Install Colmap (SETUP.md) |
| `No module named 'open3d'` | `pip install open3d numpy` |
| Flutter build fails | `flutter clean && flutter pub get` |
| Backend port 5000 in use | Change in `backend/Program.cs` |
| Images don't upload | Check backend logs for image validation errors |

See [docs/SETUP.md](docs/SETUP.md) for detailed troubleshooting.

---

## 📚 Documentation Map (Pick Your Starting Point)

**I want to...** | **Read this**
---|---
Understand the whole project | [INDEX.md](INDEX.md) ← Start here
Understand the architecture | [docs/DATA_FLOW.md](docs/DATA_FLOW.md)
Set up development environment | [docs/SETUP.md](docs/SETUP.md)
Use the REST API | [docs/API.md](docs/API.md)
Understand body measurements | [docs/MEASUREMENTS.md](docs/MEASUREMENTS.md)
Work on mobile app | [mobile/README.md](mobile/README.md)
Work on backend | [backend/README.md](backend/README.md)
See Phase 2 completion | [PHASE-2-COMPLETE.md](PHASE-2-COMPLETE.md)
See user journey | [docs/SCANNING_FLOW.md](docs/SCANNING_FLOW.md)

---

## 🔌 Key API Endpoints (from Mobile Perspective)

All endpoints prefixed with `http://localhost:5000/api/scans/{sessionId}`

### Upload Phase (Phase 1)
```
POST   /upload              → Upload image batch
GET    /status              → Check upload progress
```

### Reconstruction Phase (Phase 2)
```
POST   /reconstruct         → Start 3D reconstruction
GET    /reconstruct/status  → Check progress (polls every 3s)
GET    /measurements        → Get body measurements
GET    /mesh/stl            → Download print-ready STL
GET    /mesh/obj            → Download mesh for editing
GET    /reconstruct/model   → Download point cloud
```

### Print Service (Phase 2)
```
GET    /print/stats         → Get validation + cost estimate
POST   /print/order         → Submit print order
```

Full reference: [docs/API.md](docs/API.md)

---

## 📂 Directory Guide

```
formFittingPrints/              # Root
├── INDEX.md                    ← Project overview (start here)
├── README.md                   ← Feature summary
├── QUICK_START.md             ← This file
├── PHASE-2-COMPLETE.md        ← What was implemented
│
├── mobile/                     # Flutter app
│   ├── lib/
│   │   ├── screens/           # UI pages
│   │   ├── services/          # API clients
│   │   ├── providers/         # State (Provider)
│   │   └── models/            # Data models
│   └── README.md              # Mobile-specific docs
│
├── backend/                    # C# API server
│   ├── Controllers/           # REST endpoints
│   ├── Services/              # Business logic
│   ├── Models/                # Data models
│   └── README.md              # Backend-specific docs
│
├── scripts/                    # Python processing
│   ├── measure.py             # Extract girths from 3D
│   ├── mesh_processing.py     # Poisson reconstruction
│   └── validate_stl.py        # Print validation
│
├── docs/                       # Detailed documentation
│   ├── SETUP.md               # Environment setup
│   ├── API.md                 # Endpoint reference
│   ├── DATA_FLOW.md           # Architecture
│   ├── MEASUREMENTS.md        # Algorithm details
│   └── SCANNING_FLOW.md       # User journey
│
└── _ai_workspace/             # AI planning & notes
    ├── index.md               # Current state
    ├── phase-1.md             # Phase 1 tasks
    └── phase-2.md             # Phase 2 tasks
```

---

## 🎯 What to Do Next

### If You're Investigating the Project
1. Read [INDEX.md](INDEX.md) for complete overview
2. Run the setup (see above)
3. Take a test scan to see the flow
4. Explore the code in `backend/Services/ReconstructionService.cs`

### If You're Contributing
1. Check [PHASE-2-COMPLETE.md](PHASE-2-COMPLETE.md) for what was done
2. Pick a task from [_ai_workspace/](\_ai_workspace/) or create an issue
3. Follow the [docs](docs/) for architecture guidance
4. Test end-to-end before submitting

### If You're Deploying
1. Follow [docs/SETUP.md](docs/SETUP.md) for production environment
2. Install Colmap and Python dependencies on server
3. Configure backend in `backend/Program.cs`
4. Set up file storage (currently local, move to S3 for production)
5. Test with real device before production

### If You're Doing Phase 3
1. Read [PHASE-2-COMPLETE.md](PHASE-2-COMPLETE.md) "Future Work" section
2. Database: Migrate from JSON to PostgreSQL
3. Auth: Add user authentication layer
4. Print API: Integration real 3D printing service
5. See [_ai_workspace/](\_ai_workspace/) for decision logs

---

## 🧪 Quick Test

Want to verify everything is working?

```bash
# Terminal 1: Start backend
cd backend && dotnet run
# Wait for "Now listening on: http://localhost:5000"

# Terminal 2: Start mobile
cd mobile && flutter run
# Select your device

# Phone: Tap "Start Scan"
# Quickly tap camera button 50 times (or take real scans)
# Tap "Done" then "Upload"
# Watch backend logs
# After 2-5 min: Phone shows measurements
# Tap "Order 3D Print"
# Select material and quality
# Tap "Place Order"
# See confirmation dialog
```

---

## 💾 Data Flow (Technical)

```
Phone Camera
    ↓ (50 images)
Mobile App Validation
    ↓ (HTTP multipart)
Backend Upload Endpoint
    ↓ (JPEG/PNG validation, Storage)
File System: backend/scans/{sessionId}/
    ↓ (on demand)
ReconstructionService
    ├─→ Colmap (feature_extractor)
    ├─→ Colmap (exhaustive_matcher)
    ├─→ Colmap (mapper)
    ├─→ Colmap (model_converter) → Point Cloud
    ├─→ Python: mesh_processing.py → STL/OBJ
    ├─→ Python: validate_stl.py → Print Stats
    └─→ Python: measure.py → Body Measurements
    ↓
File System: backend/reconstructions/{sessionId}/
    ↓ (JSON status, measurements, print approval)
Mobile Status Poll ← ← ← ← ← ← ←
    ↓
Display: Measurements + Download Options + Print Order
```

---

## ❓ FAQ

**Q: How long does reconstruction take?**
A: 2-6 minutes depending on image quality (typically 3-4 min)

**Q: Can I use existing images instead of taking photos?**
A: Yes, put JPEG files in `backend/scans/{sessionId}/` directory structure

**Q: What if reconstruction fails?**
A: Check backend logs for Colmap errors. Usually means poor image quality or insufficient overlap.

**Q: Can I download the 3D model?**
A: Yes! Three formats: PLY (point cloud), OBJ (mesh), STL (for 3D printing)

**Q: Is this production-ready?**
A: Core features yes, but needs database, auth, and real print service integration (Phase 3)

**Q: How do I deploy to production?**
A: Follow [docs/SETUP.md](docs/SETUP.md), use cloud storage (S3), add database, authentication

---

## 🔗 Important Links

- **Main README**: [README.md](README.md)
- **Full Index**: [INDEX.md](INDEX.md)
- **Setup Guide**: [docs/SETUP.md](docs/SETUP.md)
- **API Reference**: [docs/API.md](docs/API.md)
- **Architecture**: [docs/DATA_FLOW.md](docs/DATA_FLOW.md)
- **Phase 2 Summary**: [PHASE-2-COMPLETE.md](PHASE-2-COMPLETE.md)

---

## 📞 Support

### Common Issues → Solutions

**Backend won't build**
- Ensure .NET 9.0 SDK installed: `dotnet --version`
- Run: `dotnet clean && dotnet restore && dotnet build`

**Mobile crashes on camera**
- Check camera permissions on device
- May need to rebuild: `flutter clean && flutter pub get && flutter run`

**Reconstruction takes forever**
- Normal for first run (cache builds)
- Check backend logs: `backend/` console output
- May be slow images (low light, motion blur)

**Images not uploading**
- Check image format (must be JPEG/PNG)
- Verify image dimensions
- Check network connectivity

### If Still Stuck
1. Check [docs/SETUP.md](docs/SETUP.md) Troubleshooting section
2. Review backend logs in console
3. Open issue in `_ai_workspace/` with error message
4. Check if similar issue exists in existing docs

---

## 🎓 Learning Path

1. **Understand the Project** (5 min)
   - Read: [INDEX.md](INDEX.md)
   
2. **Set Up Environment** (30 min)
   - Read: [docs/SETUP.md](docs/SETUP.md)
   - Install dependencies
   - Run tests

3. **Take a Test Scan** (10 min)
   - Run backend + mobile
   - Capture images
   - See reconstruction

4. **Explore Code** (varying)
   - Backend: `backend/Services/ReconstructionService.cs`
   - Mobile: `mobile/lib/screens/reconstruction_status_screen.dart`
   - Scripts: `scripts/measure.py`

5. **Understand Architecture** (15 min)
   - Read: [docs/DATA_FLOW.md](docs/DATA_FLOW.md)

6. **Read API Reference** (10 min)
   - Read: [docs/API.md](docs/API.md)

7. **Check Measurements** (10 min)
   - Read: [docs/MEASUREMENTS.md](docs/MEASUREMENTS.md)

**Total**: ~90 minutes to full understanding ✓

---

**Last Updated**: March 31, 2026 – Phase 2 Complete
**Next**: See [PHASE-2-COMPLETE.md](PHASE-2-COMPLETE.md) for handoff notes
