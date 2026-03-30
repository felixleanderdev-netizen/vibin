# Form-Fitting Prints

**Description**: Wearable 3D-printed objects customized to individual body dimensions via smartphone scanning and AR preview.

## Project Structure

```
formFittingPrints/
├── _ai_workspace/          # AI agent planning & documentation
│   ├── index.md            # Project state & decisions
│   ├── phase-1.md          # Phase 1: Scanning pipeline (detailed task board)
│   ├── phase-2.md          # Phase 2: 3D reconstruction (TBD)
│   ├── tasks.md            # Active task tracking (TBD)
│   └── decisions.md        # Decision log (TBD)
│
├── mobile/                 # Flutter mobile app (iOS + Android)
│   ├── lib/                # Dart source code
│   ├── pubspec.yaml        # Flutter dependencies
│   └── README.md           # Mobile setup instructions
│
├── backend/                # C# ASP.NET Core API server
│   ├── src/                # C# source code
│   ├── *.csproj            # Project file
│   └── README.md           # Backend setup instructions
│
├── 3d-templates/           # Pre-made wearable object templates
│   ├── collar.stl          # (User-provided)
│   ├── armband.stl         # (User-provided)
│   └── armor.stl           # (User-provided)
│
├── docs/                   # Project documentation
│   ├── API.md              # API endpoint specification
│   ├── DATA_FLOW.md        # System architecture & data flow
│   ├── SCANNING_FLOW.md    # User scanning journey
│   ├── MEASUREMENTS.md     # Measurement extraction spec
│   └── SETUP.md            # Full development setup
│
├── scripts/                # Utility scripts (testing, data prep)
│   └── README.md           # Script documentation
│
├── .gitignore              # Git ignore rules
└── README.md               # This file
```

## Quick Start

### Backend (C# ASP.NET Core)
```bash
cd backend
dotnet restore
dotnet build
dotnet run
# Server runs on https://localhost:5001
```

### Mobile (Flutter)
```bash
cd mobile
flutter pub get
flutter run -d <device-id>
```

## Project Phases

- **Phase 1**: Scanning Pipeline (image capture + upload)
- **Phase 2**: 3D Reconstruction (images → 3D mesh)
- **Phase 3**: Measurement Extraction (mesh → body girths)
- **Phase 4**: Object Fitting (template scaling/positioning)
- **Phase 5**: AR Preview (try-on + visualization)

See [_ai_workspace/](/_ai_workspace/) for detailed phase planning.

## Tech Stack

| Component | Technology | Notes |
|-----------|-----------|-------|
| Mobile | Flutter (Dart) | Cross-platform iOS + Android |
| Backend | C# ASP.NET Core | REST API, type-safe |
| 3D | Python + Open3D | Photogrammetry, measurement extraction |
| AR | ARCore/ARKit | Native mobile AR rendering |
| Database | PostgreSQL + S3 | (Phase 2+) |

## Development Notes

- **No JavaScript**: Entire stack avoids JavaScript per project requirements
- **Solo Development**: Optimized for one developer + one AI agent iterating
- **Cross-Device**: Supports wide range of smartphone devices (iOS 12+, Android 9+)

## Getting Help

- See [docs/](docs/) for architecture and API documentation
- See [_ai_workspace/](/_ai_workspace/) for phase plans and decisions
- See individual `README.md` files in `backend/` and `mobile/` for component setup

---

**Last Updated**: 2026-03-30  
**Lead Developer**: FlanDev  
**AI Agent**: GitHub Copilot (Claude Haiku 4.5)
