namespace FormFittingPrints.API.Services;

using FormFittingPrints.API.Models;
using Microsoft.Extensions.Logging;

public class ScanStorageService
{
    private readonly string _scanBaseDirectory;
    private readonly ILogger<ScanStorageService> _logger;
    private const long MaxFileSize = 100 * 1024 * 1024; // 100 MB per file
    private readonly string[] AllowedExtensions = { ".jpg", ".jpeg", ".png" };

    public ScanStorageService(ILogger<ScanStorageService> logger)
    {
        _logger = logger;
        _scanBaseDirectory = Path.Combine(Directory.GetCurrentDirectory(), "scans");
        Directory.CreateDirectory(_scanBaseDirectory);
    }

    public async Task<ScanSession> SaveScanImagesAsync(IFormFileCollection files, string? deviceInfo = null)
    {
        var session = new ScanSession { DeviceInfo = deviceInfo };
        var sessionDirectory = Path.Combine(_scanBaseDirectory, session.SessionId);

        try
        {
            Directory.CreateDirectory(sessionDirectory);
            _logger.LogInformation("Created session directory: {SessionDirectory}", sessionDirectory);

            int imageCount = 0;
            foreach (var file in files)
            {
                // Validate file
                if (!IsValidImageFile(file))
                {
                    _logger.LogWarning("Invalid file skipped: {FileName}", file.FileName);
                    continue;
                }

                if (file.Length > MaxFileSize)
                {
                    _logger.LogWarning("File too large: {FileName} ({Size} bytes)", file.FileName, file.Length);
                    continue;
                }

                // Save file
                var fileName = $"img_{imageCount:D3}{Path.GetExtension(file.FileName).ToLower()}";
                var filePath = Path.Combine(sessionDirectory, fileName);

                using (var stream = new FileStream(filePath, FileMode.Create))
                {
                    await file.CopyToAsync(stream);
                }

                session.ImagePaths.Add(filePath);
                imageCount++;
                _logger.LogInformation("Saved image: {ImagePath}", filePath);
            }

            session.ImageCount = imageCount;
            session.Status = imageCount > 0 ? "completed" : "error";

            _logger.LogInformation("Session {SessionId} completed with {ImageCount} images", 
                session.SessionId, imageCount);

            return session;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error saving scan images for session {SessionId}", session.SessionId);
            session.Status = "error";
            throw;
        }
    }

    private bool IsValidImageFile(IFormFile file)
    {
        var extension = Path.GetExtension(file.FileName).ToLower();
        return AllowedExtensions.Contains(extension);
    }

    public string GetSessionDirectory(string sessionId)
    {
        return Path.Combine(_scanBaseDirectory, sessionId);
    }
}
