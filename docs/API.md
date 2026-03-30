# API Specification

## Base URL

- **Development**: `http://localhost:5000` (HTTP) or `https://localhost:5001` (HTTPS)
- **Production**: TBD

---

## Endpoints

### 1. Upload Scan Images

**Endpoint**: `POST /api/scans/upload`

**Description**: Upload multiple body scan images for a single session.

**Request Headers**:
```
Content-Type: multipart/form-data
```

**Request Body**:
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `images` | `IFormFileCollection` | Yes | Array of image files (JPEG, PNG) |
| `deviceInfo` | `string` | No | JSON string with device metadata (optional) |

**Example Request** (cURL):
```bash
curl -X POST https://localhost:5001/api/scans/upload \
  -F "images=@img_001.jpg" \
  -F "images=@img_002.jpg" \
  -F "images=@img_003.jpg" \
  -F 'deviceInfo={"model":"iPhone14","os":"iOS","version":"16.0"}'
```

**Response** (200 OK):
```json
{
  "sessionId": "550e8400-e29b-41d4-a716-446655440000",
  "imagesReceived": 3,
  "status": "completed",
  "timestamp": "2026-03-30T12:34:56Z",
  "message": "Successfully stored 3 images"
}
```

**Error Responses**:

| Status | Condition | Response |
|--------|-----------|----------|
| `400` | No images provided | `{"status": "error", "message": "No images provided"}` |
| `413` | File exceeds 100MB | `{"status": "error", "message": "..."}` |
| `500` | Server error | `{"status": "error", "message": "Internal server error..."}` |

**Notes**:
- Supported formats: JPEG, PNG
- Max file size per image: 100 MB
- Max request size: 1 GB
- Images are stored in: `./scans/{sessionId}/img_000.jpg`, `img_001.jpg`, etc.
- `deviceInfo` is optional but recommended for troubleshooting cross-device issues

---

### 2. Health Check

**Endpoint**: `GET /api/scans/health`

**Description**: Check if the API is running.

**Response** (200 OK):
```json
{
  "status": "ok",
  "timestamp": "2026-03-30T12:34:56Z"
}
```

---

## Data Models

### ScanSession (Internal)
```csharp
{
  "sessionId": "string",          // UUID
  "createdAt": "2026-03-30T...",  // ISO 8601 timestamp
  "deviceInfo": "string",         // User-provided JSON or null
  "imageCount": 0,                // Number of stored images
  "status": "string",             // pending | completed | processing | error
  "imagePaths": ["string"]        // List of stored file paths
}
```

### UploadResponse
```csharp
{
  "sessionId": "string",
  "imagesReceived": 0,
  "status": "string",             // success | error
  "timestamp": "2026-03-30T...",
  "message": "string"             // Optional error message
}
```

---

## Implementation Notes

- **Storage**: MVP uses local disk (`./scans/{sessionId}/`). Upgrade to S3 in Phase 2.
- **Validation**: Images validated for format (.jpg, .jpeg, .png) and file size.
- **Logging**: All uploads logged to console/file for debugging.
- **CORS**: Enabled for all origins in development; restrict in production.
- **Retry Logic**: Client should handle network timeouts and retry with exponential backoff.

---

## Future Endpoints (Planned)

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/api/scans/{sessionId}` | GET | Retrieve session details |
| `/api/scans/{sessionId}/images` | GET | List images in session |
| `/api/scans/{sessionId}/reconstruct` | POST | Trigger 3D reconstruction |
| `/api/scans/{sessionId}/measurements` | GET | Get body measurements |
| `/api/objects/fit` | POST | Fit template object |

---

**Last Updated**: 2026-03-30
