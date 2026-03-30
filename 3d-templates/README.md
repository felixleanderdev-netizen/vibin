# 3D Wearable Object Templates

This directory contains pre-made 3D object templates (STL format) that users can select from and fit to their body measurements.

## Template Files

| File | Object Type | Body Target | Status |
|------|------|---------|--------|
| `collar.stl` | Neck collar/choker | Neck | User-provided |
| `armband.stl` | Arm band / bracelet | Upper arm | User-provided |
| `armor.stl` | Full body armor | Torso / full body | User-provided |

## File Format

- **Format**: STL (STereoLithography binary)
- **Units**: Millimeters (mm)
- **Scale**: Objects should be designed for average body dimensions (see [MEASUREMENTS.md](../docs/MEASUREMENTS.md))
- **Origin**: Centered at coordinate system origin

## Design Guidelines (Phase 4+)

### Parametric Adjustments

Each object must support the following transformations:

1. **Scaling** (girth adjustment)
   - Uniform scaling along circumference axis
   - Example: collar girth 350mm → 380mm = 1.086× scale

2. **Rotation/Positioning**
   - Position template to align with body anatomy
   - Compute placement transform from pose landmarks (Phase 3)

3. **Padding/Offset**
   - Ensure 5-15mm safety margin from body surface
   - Prevent collision with skin

### Mesh Requirements

- **Manifold**: Closed, water-tight mesh
- **Vertex count**: 1k-10k triangles (balance detail vs. performance)
- **Normals**: Consistent outward-facing normals
- **No intersections**: Internal geometric consistency

---

## Usage in Fitting Pipeline (Phase 4)

```
User Input: 
  - Selects object type (collar, armband, armor)
  - Body measurements extracted (Phase 3)
        ↓
Load Template:
  - Read collar.stl from disk
        ↓
Fit to Measurements:
  - Scale to match body girth
  - Position using anatomical landmarks
  - Check for collisions
        ↓
Generate Fitted Model:
  - Output fitted_collar_{sessionId}.stl
        ↓
AR Preview:
  - Load fitted model in AR
  - Show on-body visualization
        ↓
Export for 3D Print:
  - Save final STL ready for print farm
```

---

## Obtaining Templates

**Option 1: User-Provided** (Current)
- User has existing STL files
- Place them here before Phase 2

**Option 2: Design / Procurement** (Future)
- Source from 3D design repositories (Thingiverse, MyMiniFactory)
- Design custom using CAD software (Fusion 360, FreeCAD)

**Option 3: Parametric Generation** (Future)
- Write parametric OpenSCAD scripts for dynamic object generation
- Example: `collar.scad` parameterized by girth

---

## Testing & Validation

- [ ] STL files are manifold (open with Meshlab, check for holes)
- [ ] Dimensions reasonable (not too small/large for human wear)
- [ ] Orientation correct (collar should wrap neck, etc.)
- [ ] Fit test: scale armband to 280mm → preview on test body

---

**Last Updated**: 2026-03-30
