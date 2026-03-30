# Form-Fitting Prints: AI Workspace

**Last Updated**: 2026-03-30 (Phase 1 Complete)  
**Status**: Phase 0 ✅ — Phase 1 ✅ — Phase 2 (Reconstruction + Measurements) Planned

---

## 🎯 Project Overview

**Product**: 3D-printed wearable objects (collar, armband, armor) customized to individual body dimensions.

**Core Flow**:
1. User scans body with smartphone → detailed 3D model
2. System extracts body measurements from scan
3. Backend fits pre-made object template to measurements
4. User previews fitted object in AR (try-on)
5. User submits order

**Constraints**:
- No JavaScript in tech stack
- Cross-device smartphone compatibility (iOS + Android)
- Casual userbase focus
- Solo development (user + AI agent only)

---

## 📊 Current State

### Decisions Made ✅
- Object templates: **Pre-made** (user has `.stl` files ready) — collar, armband, armor
- Scanning method: **Smartphone photogrammetry** (multi-image capture with guidance)
- Scanning UX: **Guided sequence** (provide user with rough guidance for rotation/positioning)
- Body segmentation: **Automatic isolation** (auto-detect person from background)
- Mobile framework: **Flutter (Dart)** for cross-device support
- Backend language: **C#** (ASP.NET Core API)
- 3D reconstruction: **Colmap** (open-source SfM)
- Measurement focus: **Arm/leg/neck girth** (circumference measurements)
- Measurement extraction: **Python + Open3D** (mesh → girth calculations)
- AR rendering: **ARCore/ARKit native plugins**

### Risks & Challenges 🔴
- **Phase 2 (Reconstruction)**: Colmap tuning for cross-device images (HIGH effort)
- Image quality variance across phones (lighting, resolution, focus)
- Body pose estimation for consistent measurements
- AR sync between captured body scan and live camera feed

---

## 🧬 Architecture Overview

### Tech Stack (Proposed)

| Component | Technology | Why |
|-----------|-----------|-----|
| Mobile App | Flutter + Dart | Cross-platform, native AR bridges |
| Scanning | Flutter camera plugins | Good device support |
| 3D Reconstruction | Colmap (C++) + Python wrapper | Proven photogrammetry |
| Measurement | Python + Open3D + scipy | Girth extraction from mesh |
| Fitting | Python + trimesh/numpy | Template transformation |
| AR Rendering | ARCore/ARKit (native) | Best performance |
| Backend API | C# + ASP.NET Core | Type-safe, scalable REST API |
| Database | PostgreSQL + S3 | Geometry storage, mesh archives |

### Workspace Structure (Proposed)

```
formFittingPrints/
├── _ai_workspace/          # AI planning & docs (this folder)
│   ├── index.md            # Project state (this file)
│   ├── phase-*.md          # Phase-specific plans
│   ├── tasks.md            # Active tasks & board
│   └── decisions.md        # Decision log
├── mobile/                 # Flutter app
│   ├── lib/
│   ├── pubspec.yaml
│   └── README.md
├── backend/                # C# / ASP.NET Core server
│   ├── src/
│   ├── .csproj
│   └── README.md
├── 3d-templates/           # Pre-made wearable objects
│   ├── collar.stl
│   ├── armband.stl
│   └── armor.stl
├── docs/                   # User & project documentation
│   ├── API.md
│   ├── DATA_FLOW.md
│   ├── MEASUREMENTS.md
│   └── SETUP.md
└── README.md               # Project root
```

---

## 📋 Project Phases

### Phase 1: Scanning Pipeline
**Goal**: Mobile app captures images → server receives safely  
**Inputs**: —  
**Outputs**: iOS + Android app, `/upload` endpoint  

### Phase 2: 3D Reconstruction (CRITICAL PATH)
**Goal**: Image sequence → 3D mesh  
**Inputs**: Raw images from Phase 1  
**Outputs**: Point cloud + mesh (`.obj` / `.ply`)  
**Risk**: Cross-device image quality variance  

### Phase 3: Measurement Extraction
**Goal**: 3D mesh → body girth measurements  
**Inputs**: Mesh from Phase 2 + auto-isolated body segmentation  
**Outputs**: Measurement struct (JSON: arm girth, leg girth, neck girth)  

### Phase 4: Object Fitting
**Goal**: Load template → scale/position to measurements  
**Inputs**: Measurements + template STL  
**Outputs**: Fitted STL + placement transform  

### Phase 5: AR Preview
**Goal**: Render fitted object on body in real-time  
**Inputs**: Fitted model + live device camera feed  
**Outputs**: ARCore/ARKit integration  

---

## 🚀 Next Steps

1. **Create Phase 1 task board** (camera setup, image upload pipeline, test harness)
2. **Prepare template file** (locate/verify user's `.stl` files for collar, armband, armor)
3. **Build minimal viable flow** (capture images → Colmap reconstruction → STL output)
4. **Set up C# backend scaffold** (ASP.NET Core project, POST `/upload` endpoint)
5. **Validate on real device** (test cross-device image quality + Colmap tuning)

---

## 📝 Notes & Observations

- Photogrammetry is **highest-risk** component; prototype early with test photos
- Cross-device image handling requires careful API design + validation
- Colmap has memory overhead → consider GPU acceleration or server-side queuing
- AR preview needs body pose from Phase 2— coordinate systems must align

---

## 🔄 AI Agent Working Notes

**Instructions for future agents**:
- Consult this file before starting work
- Update status + risks as phases progress
- Log decisions in `decisions.md`
- Track blockers in `tasks.md`
- Keep all generated files organized by phase
- Reference this workspace in commit messages: `[_ai_workspace] phase-X update`

---
