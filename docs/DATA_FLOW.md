# Data Flow & System Architecture

## System Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Form-Fitting Prints System                │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────┐         ┌──────────────┐                 │
│  │   Mobile     │         │   Backend    │                 │
│  │  (Flutter)   │────────▶│  (C# API)    │                 │
│  │              │         │              │                 │
│  │  • Camera    │         │  • Upload    │                 │
│  │  • Preview   │◀────────│  • Storage   │                 │
│  │  • AR View   │         │  • Logs      │                 │
│  └──────────────┘         └──────────────┘                 │
│           │                      │                         │
│           │                      ▼                         │
│           │              ┌────────────────┐                │
│           │              │ File Storage   │                │
│           │              │ (./scans/{id}) │                │
│           │              └────────────────┘                │
│           │                                                │
│           └──────────────────────────────────────────      │
│                                                            │
│  ┌──────────────────────────────────────────────────┐    │
│  │         Processing (Phase 2+)                     │    │
│  │  • Colmap 3D Reconstruction                       │    │
│  │  • Measurement Extraction                         │    │
│  │  • Object Fitting                                 │    │
│  │  • AR Preview Generation                          │    │
│  └──────────────────────────────────────────────────┘    │
│                                                            │
└─────────────────────────────────────────────────────────────┘
```

---

## Phase 1: Scanning Pipeline

### Request Flow

```
User Action               Mobile App              Backend API
───────────────────────────────────────────────────────────────

1. "Start Scan"    ──▶  Show guidance UI
                        Show camera preview

2. "Capture" (×N)  ──▶  Capture image
                        Store locally
                        Update frame counter

3. "Upload"        ──▶  Build multipart request
                        Add images + metadata
                        POST /api/scans/upload ──▶  Validate images
                                                     Create session dir
                                                     Store images
                                                     ◀── Return SessionId

4. Confirm         ◀──  Display session ID
                        Clear local files
```

### File Structure (on server)

```
./scans/
├── 550e8400-e29b-41d4-a716-446655440000/  (sessionId #1)
│   ├── img_000.jpg
│   ├── img_001.jpg
│   ├── img_002.jpg
│   └── ...
├── a1b2c3d4-e5f6-47g8-h9i0-j1k2l3m4n5o6/  (sessionId #2)
│   ├── img_000.jpg
│   ├── img_001.jpg
│   └── ...
└── ...
```

---

## Network Communication

### HTTP Request (Mobile → Backend)

**Type**: `POST` with `multipart/form-data`

**Headers**:
```
POST /api/scans/upload HTTP/1.1
Host: localhost:5001
Content-Type: multipart/form-data; boundary=----WebKitFormBoundary7MA4YWxkTrZu0gW
Content-Length: 5242880

------WebKitFormBoundary7MA4YWxkTrZu0gW
Content-Disposition: form-data; name="images"; filename="img_001.jpg"
Content-Type: image/jpeg

[binary image data]
------WebKitFormBoundary7MA4YWxkTrZu0gW
Content-Disposition: form-data; name="deviceInfo"

{"model":"iPhone14Pro","os":"iOS","version":"16.0"}
------WebKitFormBoundary7MA4YWxkTrZu0gW--
```

**Response** (200 OK):
```json
{
  "sessionId": "550e8400-e29b-41d4-a716-446655440000",
  "imagesReceived": 45,
  "status": "completed",
  "timestamp": "2026-03-30T12:34:56Z",
  "message": "Successfully stored 45 images"
}
```

---

## Data Persistence

### Session Storage

- **Location**: `./backend/scans/{sessionId}/`
- **Files**: `img_000.jpg`, `img_001.jpg`, ... (sequential, zero-padded)
- **Metadata**: Logged to console/file (device info, upload time, file sizes)
- **Backup**: None in Phase 1 (MVP); implement S3 in Phase 2

### Image Metadata Captured

| Field | Type | Example |
|-------|------|---------|
| `deviceInfo` | JSON | `{"model":"iPhone14","os":"iOS"}` |
| `uploadTime` | Timestamp | `2026-03-30T12:34:56Z` |
| `fileSize` | Bytes | `2097152` (2 MB) |
| `resolution` | String | `3024x4032` (extracted later) |
| `imageCount` | Integer | `45` |

---

## Error Handling

### Client-Side (Mobile)

1. **Network Error**: Show retry dialog × 3attempts
2. **Timeout** (>30s): Cancel upload, ask user to retry
3. **Server Error** (5xx): Show error message, offer support contact
4. **File Error**: Validate image format before upload

### Server-Side (Backend)

1. **Invalid File Format**: Skip file, log warning, continue upload
2. **Oversized File** (>100MB): Reject file, return 413 error
3. **Session Directory Error**: Return 500, log exception
4. **Disk Full**: Return 507 error

---

## Phase 2: Integration Points (Preview)

Once Phase 1 is complete, Phase 2 will:

1. **Read** images from `./scans/{sessionId}/`
2. **Invoke** Colmap for 3D reconstruction
3. **Output** mesh files (`.obj`, `.ply`) to `./scans/{sessionId}/models/`
4. **Trigger** measurement extraction (Python service)
5. **Store** measurements in database (Phase 2.5)

### API Extension (Phase 2)

```
POST /api/scans/{sessionId}/reconstruct
  ├─ Trigger Colmap pipeline
  └─ Return jobId (async)

GET /api/scans/{sessionId}/models
  └─ Return available 3D models

GET /api/scans/{sessionId}/measurements
  └─ Return body measurements (girth values)
```

---

## Security Considerations

### Phase 1

- [x] HTTPS enforced (localhost: self-signed cert)
- [x] File format validation (only .jpg, .jpeg, .png)
- [x] Maximum file size limits (100 MB per file, 1 GB per request)
- [ ] CSRF token (not needed for file uploads in development)
- [ ] Authentication (not yet; anyone can upload)

### Phase 2+

- [ ] User authentication (OAuth, JWT)
- [ ] Session encryption (optional PII protection)
- [ ] Data deletion after processing (privacy compliance)
- [ ] S3 access via IAM roles (avoid hardcoded credentials)

---

## Performance Metrics (Phase 1 Targets)

| Metric | Target | Notes |
|--------|--------|-------|
| Upload speed | ≥5 Mbps | Depends on network |
| Server latency | <100ms | Per request |
| Disk usage | ~100MB per scan | 45 images × ~2.5MB avg |
| Concurrent uploads | 5+ | Single server |

---

**Last Updated**: 2026-03-30
