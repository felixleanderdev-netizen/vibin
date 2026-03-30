# Form-Fitting Prints - Backend API

C# ASP.NET Core REST API for handling body scans and wearable object fitting.

## Getting Started

### Prerequisites

- **.NET 9.0 SDK** or later
- A text editor or IDE (VS Code, Visual Studio, JetBrains Rider)

### Installation

1. Restore dependencies:
```bash
dotnet restore
```

2. Build the project:
```bash
dotnet build
```

### Running the Server

```bash
dotnet run
```

The server will start on `https://localhost:5001` (HTTPS) and `http://localhost:5000` (HTTP).

**Note**: On first run, you may need to trust the HTTPS certificate:
```bash
dotnet dev-certs https --trust
```

## Project Structure

```
backend/
├── Controllers/          # API endpoints
│   └── ScansController.cs
├── Models/              # Data models
│   ├── ScanSession.cs
│   └── UploadResponse.cs
├── Services/            # Business logic
│   └── ScanStorageService.cs
├── Middleware/          # Custom middleware
│   └── ErrorHandlingMiddleware.cs
├── scans/               # (Runtime) Uploaded scan sessions
├── Program.cs           # Startup configuration
├── appsettings.json     # Configuration
└── README.md            # This file
```

## API Endpoints

### POST `/api/scans/upload`

**Description**: Upload multiple images for a single body scan session.

**Request**:
- **Content-Type**: `multipart/form-data`
- **Body**:
  - `images`: Array of image files (JPEG, PNG)
  - `deviceInfo`: (optional) JSON string with device metadata

**Response** (200 OK):
```json
{
  "sessionId": "uuid-here",
  "imagesReceived": 15,
  "status": "success",
  "timestamp": "2026-03-30T12:34:56Z"
}
```

**Error Responses**:
- `400 Bad Request`: Invalid file format or missing images
- `413 Payload Too Large`: File size exceeds limit (100MB per file)
- `500 Internal Server Error`: Server-side failure

## Configuration

Edit `appsettings.json` to adjust:
- Max file size
- Upload directory path
- API CORS settings
- Logging level

## Development Notes

- **Logging**: Structured logging via ASP.NET Core's built-in providers
- **Error Handling**: Custom middleware catches and logs exceptions
- **Storage**: MVP uses local disk (`./scans/{sessionId}/`); upgrade to S3 later
- **Validation**: Image format, size, and integrity validated on upload

## Testing

Mock image generation and upload tests (Phase 1):
```bash
# Coming soon - see ../scripts/
```

## Future Enhancements

- [ ] Database integration (PostgreSQL)
- [ ] S3 upload support
- [ ] Image metadata extraction (EXIF)
- [ ] Session retry/resume logic
- [ ] Colmap integration for reconstruction
- [ ] Measurement extraction API

---

**Last Updated**: 2026-03-30
