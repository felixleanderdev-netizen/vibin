# Scanning Flow & User Journey

## User Story

> As a casual user, I want to easily scan my body with my smartphone so that I can get a form-fitted wearable object in my correct size.

---

## Scanning Journey (Phase 1)

### Step 0: App Launch

1. **User opens app** → Sees title "Form-Fitting Prints"
2. **Welcome screen** with CTA: "Start Scanning"
3. **Permissions dialog** (iOS/Android):
   - Camera: "We need access to capture your body"
   - File storage: "We need access to save scan images"

### Step 1: Preparation

1. **Guidance screen**:
   - "Stand in a well-lit area"
   - "Wear form-fitting clothes or underwear for accurate fit"
   - "Stand 1.5m away from wall/background"
   - "Have ~3 minutes available"
   - **[Start Scanning]** button

### Step 2: Camera Setup

1. **Live preview** opens (full-screen camera feed)
2. **Overlay indicators**:
   - Center frame guide (where user should stand)
   - Frame counter: "Image 0 of 50"
   - Light level indicator (green=good, yellow=okay, red=too dark)

### Step 3: Guided Capture

**Rough guidance** (via text prompts):

```
[Frame 1-5]      "Stand straight, arms at sides"
[Frame 6-15]     "Rotate 45° (left side toward camera)"
[Frame 16-25]    "Rotate 90° (profile view)"
[Frame 26-35]    "Rotate 135° (far left side)"
[Frame 36-45]    "Return to facing camera, arms raised above head"
[Frame 46-50]    "Turn to look at camera from side, arms down"
```

**UI Flow**:
1. Guidance text displayed
2. Large **[Capture]** button (tappable)
3. User presses → Image snapped → Frame counter increments
4. Green flash = image captured successfully
5. Repeat until all frames captured

### Step 4: Upload

1. **Summary screen**:
   ```
   Scan Complete ✓
   Images captured: 50
   Total size: ~125 MB
   
   [Upload to Server]  [Re-scan]  [Cancel]
   ```

2. **[Upload]** pressed → Progress bar:
   ```
   Uploading... [████████░░] 82% (42 MB / 50 MB)
   Elapsed: 45s | Est. remaining: 10s
   ```

3. **Upload completes** → Confirmation:
   ```
   Upload Successful ✓
   
   Session ID: 550e8400-e29b-41d4
   Images received: 50
   Status: Ready for processing
   
   [Next Steps]  [Home]
   ```

### Step 5: Handoff (Phase 2)

In Phase 2, the user will:
1. **See 3D reconstruction** (model of their body)
2. **Select object type** (collar, armband, armor)
3. **Preview fit** in AR (try-on view)
4. **Adjust fit** (padding, scaling)
5. **Place order** → 3D print

---

## UI Wireframe (Phase 1)

### Welcome Screen
```
┌─────────────────────────────┐
│     Form-Fitting Prints     │
│                             │
│      🎯 Welcome             │
│                             │
│  Stand in a well-lit area   │
│  Wear form-fitting clothes  │
│  Have ~3 minutes available  │
│                             │
│    [Start Scanning] ────▶   │
│                             │
└─────────────────────────────┘
```

### Camera Scanning Screen
```
┌─────────────────────────────┐
│  ┌───────────────────────┐  │
│  │                       │  │
│  │   [Live Camera Feed]  │  │
│  │                       │  │
│  │  🟢 (Light OK)        │  │
│  │                       │  │
│  └───────────────────────┘  │
│                             │
│  Stand straight, arms down  │
│                             │
│  Image 15 of 50             │
│                             │
│    [📷 Capture] (large)     │
│                             │
│      [⊘ Cancel]  [↻ Reset]  │
└─────────────────────────────┘
```

### Upload Progress Screen
```
┌─────────────────────────────┐
│   Upload In Progress...     │
│                             │
│  [████████░░░░░░░░] 50%     │
│                             │
│  27.5 MB / 50 MB            │
│  ~45 seconds remaining      │
│                             │
│  Do not close the app       │
│                             │
└─────────────────────────────┘
```

### Success Screen
```
┌─────────────────────────────┐
│  Upload Successful ✓        │
│                             │
│  Session: 550e8400-e29b...  │
│  Images: 50 received        │
│  Status: Ready              │
│                             │
│    [View Details]           │
│    [Scan Another]           │
│    [Home]                   │
│                             │
└─────────────────────────────┘
```

---

## Technical Triggers

### Events (Mobile → Backend)

| Event | Trigger | API Call |
|-------|---------|----------|
| Scan complete | User presses [Upload] | POST `/api/scans/upload` |
| Auto-retry | Network timeout × 3 | POST `/api/scans/upload` (resume) |
| Cancel upload | User presses [Cancel] | (Local cleanup only) |

---

## Error States

### Network Failure
```
Upload Failed ⚠

Connection lost. Retry?

[Retry]        [Cancel & Save Locally]
```

### Invalid Device Info
```
Capture Failed ⚠

Poor lighting detected. 
Try a brighter location.

[Retake]       [Continue Anyway]
```

---

## Timing & UX Goals

| Task | Est. Duration | Notes |
|------|---|---|
| Preparation (welcome + permissions) | 15 sec | One-time |
| Scanning (capture 50 images) | 3-5 min | User-dependent |
| Upload (50 images, ~125MB) | 30-60 sec | Network-dependent |
| **Total** | **4-6 min** | Casual user flow |

---

**Last Updated**: 2026-03-30
