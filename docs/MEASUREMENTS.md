# Body Measurement Specifications

**Scope**: Phase 3 measurement extraction from 3D body mesh.

---

## Measurement Definitions

### Primary Girths (Circumferences)

These are the key measurements for fitting wearable objects. Measured as circumference around body parts.

| Measurement | Body Location | Use Case | Accuracy | Notes |
|-------------|---------------|----------|----------|-------|
| **Neck girth** | Around base of neck | Collar, armor neck area | ±5mm | Just below jawline |
| **Upper arm girth** | Around bicep (mid-arm) | Armband, sleeve | ±5mm | Arm at rest, side |
| **Forearm girth** | Around wrist/forearm | Armband, glove | ±5mm | Narrowest point wrist or mid-forearm |
| **Thigh girth** | Around largest part of thigh | Leg armor, leggings | ±5mm | Upper thigh, standing |
| **Calf girth** | Around largest part of calf | Leg armor, shin guard | ±5mm | Mid-calf, standing |
| **Ankle girth** | Around ankle bone | Footwear, ankle guards | ±5mm | Ankle joint, standing |

### Secondary Measurements (Lengths)

For iterating object fit in future phases.

| Measurement | Direction | Use Case | Accuracy |
|-------------|-----------|----------|----------|
| **Height** | Head to feet (vertical) | Reference, scaling | ±20mm |
| **Arm length** | Shoulder to fingertip | Sleeve length | ±10mm |
| **Leg length** | Hip to ankle | Pants/leg length | ±10mm |
| **Torso length** | Shoulder to waist | Vest, corset fit | ±10mm |

---

## Measurement Extraction Workflow (Phase 3)

### Input
- **3D mesh**: Point cloud or manifold mesh from Colmap (Phase 2)
- **Body segmentation**: Person isolated from background (automatic in Phase 1)
- **Pose**: User standing in canonical pose (front-facing, arms at sides or raised)

### Process

1. **Plane fitting**: Fit horizontal planes at key anatomical landmarks
   - Neck: ~130-140mm below head apex
   - Arm: ~200-250mm below shoulder
   - Wrist: ~60-80mm above hand
   - Thigh: ~300mm below hip
   - Calf: ~100mm above ankle
   - Ankle: At ankle joint

2. **Circumference calculation**: For each plane, compute:
   - Intersect plane with 3D mesh
   - Trace perimeter of resulting 2D shape
   - Sum edge lengths = girth

3. **Validation**: Check plausibility
   - Neck girth: 300-450mm (12-18")
   - Arm girth: 200-400mm (8-16")
   - Leg girth: 400-650mm (16-26")

4. **Output**: JSON struct
```json
{
  "sessionId": "550e8400-e29b-41d4-a716-446655440000",
  "measurements": {
    "neckGirth": 365,      // mm
    "upperArmGirth": 280,  // mm
    "forearmGirth": 210,   // mm
    "thighGirth": 550,     // mm
    "calfGirth": 380,      // mm
    "ankleGirth": 220,     // mm
    "height": 1780,        // mm
    "armLength": 720,      // mm
    "legLength": 950,      // mm
    "torsoLength": 580     // mm
  },
  "timestamp": "2026-03-30T13:45:00Z",
  "confidenceScores": {
    "neckGirth": 0.92,
    "upperArmGirth": 0.88,
    // ... etc
  }
}
```

---

## Measurement-to-Fitting Mapping (Phase 4)

Once measurements extracted, Phase 4 fits objects using these rules:

### Collar
```
Fitted dimension = Neck girth + 15mm padding
Expected range: 315-465mm
```

### Armband
```
Fitted dimension = (Upper arm girth + Forearm girth) / 2 + 10mm padding
Expected range: 245-405mm
```

### Armor Vambrace (Forearm)
```
Fitted dimension = Forearm girth + 15mm padding
Expected range: 225-395mm
```

### Armor Greave (Shin)
```
Fitted dimension = Calf girth + 15mm padding
Expected range: 395-575mm
```

---

## Measurement Algorithm (Pseudocode)

```python
def extract_girths(mesh: Mesh3D, pose_landmarks: Dict[str, Vector3]) -> Dict[str, float]:
    """
    Extract body girths from 3D mesh given anatomical landmarks.
    
    Args:
        mesh: 3D triangle mesh (from Colmap reconstruction)
        pose_landmarks: Dict with keys like 'neck', 'shoulder_r', 'wrist_r', etc.
    
    Returns:
        Dict of girth measurements in mm
    """
    girths = {}
    
    # Define measurement planes
    planes = {
        'neck': (pose_landmarks['neck'], Vector3.UP),
        'upper_arm': (
            pose_landmarks['shoulder_r'] + offset_down(150),
            Vector3.RIGHT
        ),
        'forearm': (
            pose_landmarks['wrist_r'] + offset_up(70),
            Vector3.RIGHT
        ),
        'thigh': (
            pose_landmarks['hip_r'] + offset_down(300),
            Vector3.RIGHT
        ),
        'calf': (
            pose_landmarks['ankle_r'] + offset_up(100),
            Vector3.RIGHT
        ),
        'ankle': (
            pose_landmarks['ankle_r'],
            Vector3.RIGHT
        ),
    }
    
    for label, (plane_origin, plane_normal) in planes.items():
        # Intersect plane with mesh
        intersection = mesh.plane_intersection(plane_origin, plane_normal)
        
        # Compute perimeter
        girth_mm = compute_perimeter(intersection)
        
        # Validate
        if is_plausible(label, girth_mm):
            girths[label] = girth_mm
        else:
            girths[label] = None  # Mark as unreliable
    
    return girths
```

---

## Data Quality & Confidence

Each measurement includes a **confidence score** (0.0-1.0):

- **0.9+**: High confidence (use directly)
- **0.7-0.9**: Medium confidence (use with padding)
- **<0.7**: Low confidence (flag for manual review)

**Factors affecting confidence**:
- Mesh resolution (high 3D detail = higher confidence)
- Body segmentation quality (clean isolation = higher confidence)
- Anatomical landmark detection (accurate landmark = higher confidence)
- Image coverage (more images = higher confidence)

---

## Reference Measurements (Adult Averages)

| Measurement | Male | Female | Notes |
|-------------|------|--------|-------|
| Neck girth | 380mm | 320mm | Average adult |
| Upper arm girth | 300mm | 240mm | Relaxed arm |
| Forearm girth | 250mm | 210mm | Mid-forearm |
| Thigh girth | 580mm | 500mm | Upper thigh |
| Calf girth | 390mm | 340mm | Mid-calf |
| Ankle girth | 210mm | 190mm | At joint |

---

## Testing & Validation (Phase 3)

**Test Dataset**:
- 10 calibration scans (known manual measurements)
- Measure each with tape → CCD scanner → app
- Compare outputs; aim for ±10mm accuracy

**QA Checklist**:
- [ ] Confidence scores realistic
- [ ] Edge cases handled (very large/small bodies)
- [ ] Outliers flagged for review
- [ ] Measurement repeatability (same scan → same measurements)

---

**Last Updated**: 2026-03-30
