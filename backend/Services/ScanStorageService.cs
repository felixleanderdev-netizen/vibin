namespace FormFittingPrints.API.Services;

using FormFittingPrints.API.Models;
using Microsoft.Extensions.Logging;

public class ScanStorageService
{
    private readonly string _scanBaseDirectory;
    private readonly ILogger<ScanStorageService> _logger;
    private const long MaxFileSize = 100 * 1024 * 1024; // 100 MB per file
    private const int MinImageWidth = 320;
    private const int MinImageHeight = 320;
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
                    _logger.LogWarning("Invalid file skipped: {FileName} - unsupported extension", file.FileName);
                    continue;
                }

                if (file.Length > MaxFileSize)
                {
                    _logger.LogWarning("File too large: {FileName} ({SizeBytes} bytes, max {MaxBytes})", 
                        file.FileName, file.Length, MaxFileSize);
                    continue;
                }

                // Validate image dimensions
                var (isValid, width, height) = await ValidateImageDimensionsAsync(file);
                if (!isValid)
                {
                    _logger.LogWarning("Image resolution too small: {FileName} ({Width}x{Height}), min required: {MinWidth}x{MinHeight}",
                        file.FileName, width, height, MinImageWidth, MinImageHeight);
                    continue;
                }

                _logger.LogInformation("Image validated: {FileName} ({Width}x{Height}, {SizeBytes} bytes)",
                    file.FileName, width, height, file.Length);

                // Save file
                var fileName = $"img_{imageCount:D3}{Path.GetExtension(file.FileName).ToLower()}";
                var filePath = Path.Combine(sessionDirectory, fileName);

                using (var stream = new FileStream(filePath, FileMode.Create))
                {
                    await file.CopyToAsync(stream);
                }

                session.ImagePaths.Add(filePath);
                imageCount++;
                _logger.LogInformation("Saved image {ImageNumber}: {ImagePath}", imageCount, filePath);
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

    /// <summary>
    /// Validates image dimensions meet minimum requirements.
    /// Parses JPEG/PNG headers to extract width and height.
    /// Returns tuple of (isValid, width, height).
    /// </summary>
    private async Task<(bool IsValid, int Width, int Height)> ValidateImageDimensionsAsync(IFormFile file)
    {
        try
        {
            using (var stream = file.OpenReadStream())
            {
                var extension = Path.GetExtension(file.FileName).ToLower();
                
                if (extension == ".png")
                {
                    var (width, height) = await ReadPngDimensionsAsync(stream);
                    var isValid = width >= MinImageWidth && height >= MinImageHeight;
                    return (isValid, width, height);
                }
                else if (extension == ".jpg" || extension == ".jpeg")
                {
                    var (width, height) = await ReadJpegDimensionsAsync(stream);
                    var isValid = width >= MinImageWidth && height >= MinImageHeight;
                    return (isValid, width, height);
                }
            }
            return (false, 0, 0);
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Failed to validate image dimensions for {FileName}", file.FileName);
            return (false, 0, 0);
        }
    }

    /// <summary>
    /// Reads PNG image dimensions from file header.
    /// PNG width/height are stored at bytes 16-24 in big-endian format.
    /// </summary>
    private async Task<(int Width, int Height)> ReadPngDimensionsAsync(Stream stream)
    {
        byte[] buffer = new byte[24];
        int bytesRead = await stream.ReadAsync(buffer, 0, 24);
        if (bytesRead < 24)
            return (0, 0);
        
        if (buffer[0] != 0x89 || buffer[1] != 0x50 || buffer[2] != 0x4E) // PNG signature check
            return (0, 0);
        
        // Width is at bytes 16-19 (big-endian)
        int width = (buffer[16] << 24) | (buffer[17] << 16) | (buffer[18] << 8) | buffer[19];
        // Height is at bytes 20-23 (big-endian)
        int height = (buffer[20] << 24) | (buffer[21] << 16) | (buffer[22] << 8) | buffer[23];
        
        return (width, height);
    }

    /// <summary>
    /// Reads JPEG image dimensions by scanning for SOF (Start Of Frame) marker.
    /// JPEG dimensions are stored after the SOF marker.
    /// </summary>
    private async Task<(int Width, int Height)> ReadJpegDimensionsAsync(Stream stream)
    {
        byte[] buffer = new byte[2];
        int bytesRead = await stream.ReadAsync(buffer, 0, 2);
        if (bytesRead < 2)
            return (0, 0);
        
        if (buffer[0] != 0xFF || buffer[1] != 0xD8) // JPEG SOI marker check
            return (0, 0);

        while (true)
        {
            bytesRead = await stream.ReadAsync(buffer, 0, 2);
            if (bytesRead < 2 || buffer[0] != 0xFF)
                return (0, 0);

            byte marker = buffer[1];
            
            // SOF markers (Start Of Frame)
            if ((marker >= 0xC0 && marker <= 0xC3) || 
                (marker >= 0xC5 && marker <= 0xC7) ||
                (marker >= 0xC9 && marker <= 0xCB) ||
                (marker >= 0xCD && marker <= 0xCF))
            {
                byte[] sof = new byte[7];
                bytesRead = await stream.ReadAsync(sof, 0, 7);
                if (bytesRead < 7)
                    return (0, 0);
                
                // Height at bytes 3-4, Width at bytes 5-6 (big-endian)
                int height = (sof[3] << 8) | sof[4];
                int width = (sof[5] << 8) | sof[6];
                
                return (width, height);
            }

            // Skip other markers
            byte[] lengthBytes = new byte[2];
            bytesRead = await stream.ReadAsync(lengthBytes, 0, 2);
            if (bytesRead < 2)
                return (0, 0);
            
            int length = ((lengthBytes[0] << 8) | lengthBytes[1]) - 2;
            
            if (length > 0)
            {
                byte[] skipBuffer = new byte[length];
                await stream.ReadAsync(skipBuffer, 0, length);
            }
        }
    }

    public string GetSessionDirectory(string sessionId)
    {
        return Path.Combine(_scanBaseDirectory, sessionId);
    }
}
