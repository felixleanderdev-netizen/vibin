using Microsoft.AspNetCore.Mvc;
using System.IO;
using FormFittingPrints.API.Models;
using FormFittingPrints.API.Services;

namespace FormFittingPrints.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public class ScansController : ControllerBase
{
    private readonly ScanStorageService _storageService;
    private readonly ReconstructionService _reconstructionService;
    private readonly ILogger<ScansController> _logger;

    public ScansController(
        ScanStorageService storageService,
        ReconstructionService reconstructionService,
        ILogger<ScansController> logger)
    {
        _storageService = storageService;
        _reconstructionService = reconstructionService;
        _logger = logger;
    }

    /// <summary>
    /// Upload images for a body scan session.
    /// </summary>
    /// <remarks>
    /// Accepts multiple image files (JPEG, PNG) and optional device information.
    /// Files are stored in session-specific directory: scans/{sessionId}/
    /// - Validates file format (.jpg, .jpeg, .png)
    /// - Validates file size (max 100 MB per file)
    /// - Validates image resolution (min 320x320)
    /// - Returns 200 OK on success, 400/413 on validation errors
    /// </remarks>
    [HttpPost("upload")]
    [RequestSizeLimit(1_000_000_000)] // 1 GB for entire request
    [Consumes("multipart/form-data")]
    public async Task<ActionResult<UploadResponse>> UploadScan(
        [FromForm] IFormFileCollection images,
        [FromForm] string? deviceInfo = null)
    {
        try
        {
            if (images == null || images.Count == 0)
            {
                _logger.LogWarning("Upload attempt with no images");
                return BadRequest(new UploadResponse
                {
                    Status = "error",
                    Message = "No images provided"
                });
            }

            // Check for oversized files before processing
            const long maxFileSize = 100 * 1024 * 1024; // 100 MB
            foreach (var file in images)
            {
                if (file.Length > maxFileSize)
                {
                    _logger.LogWarning("File exceeds size limit: {FileName} ({Size} bytes)", 
                        file.FileName, file.Length);
                    return StatusCode(
                        StatusCodes.Status413PayloadTooLarge,
                        new UploadResponse
                        {
                            Status = "error",
                            Message = $"File '{file.FileName}' exceeds maximum size of 100 MB"
                        }
                    );
                }
            }

            _logger.LogInformation("Received upload with {ImageCount} images, deviceInfo: {DeviceInfo}", 
                images.Count, deviceInfo ?? "none");

            var session = await _storageService.SaveScanImagesAsync(images, deviceInfo);

            if (session.ImageCount == 0)
            {
                _logger.LogWarning("No valid images were stored for session {SessionId}", session.SessionId);
                return BadRequest(new UploadResponse
                {
                    SessionId = session.SessionId,
                    ImagesReceived = 0,
                    Status = "error",
                    Message = "No valid images were stored. Check file format, size, and resolution."
                });
            }

            var response = new UploadResponse
            {
                SessionId = session.SessionId,
                ImagesReceived = session.ImageCount,
                Status = "success",
                Message = $"Successfully stored {session.ImageCount} images"
            };

            _logger.LogInformation("Upload succeeded: sessionId={SessionId}, images={ImageCount}",
                session.SessionId, session.ImageCount);

            return Ok(response);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error processing upload");
            return StatusCode(
                StatusCodes.Status500InternalServerError,
                new UploadResponse
                {
                    Status = "error",
                    Message = "Internal server error during image storage"
                }
            );
        }
    }

    [HttpPost("{sessionId}/reconstruct")]
    public async Task<ActionResult<ReconstructionStatus>> StartReconstruction(string sessionId)
    {
        try
        {
            var status = await _reconstructionService.StartReconstructionAsync(sessionId);
            if (status.Status == "failed")
            {
                return StatusCode(500, status);
            }

            return Ok(status);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Reconstruction start failed for {SessionId}", sessionId);
            return StatusCode(500, new { sessionId, status = "failed", message = ex.Message });
        }
    }

    [HttpGet("{sessionId}/reconstruct/status")]
    public async Task<ActionResult<ReconstructionStatus>> GetReconstructionStatus(string sessionId)
    {
        var status = await _reconstructionService.GetStatusAsync(sessionId);
        return Ok(status);
    }

    [HttpGet("{sessionId}/reconstruct/model")]
    public async Task<IActionResult> DownloadReconstructionModel(string sessionId)
    {
        var status = await _reconstructionService.GetStatusAsync(sessionId);
        if (status?.Status != "succeeded" || string.IsNullOrEmpty(status.ModelPath) || !System.IO.File.Exists(status.ModelPath))
        {
            return NotFound(new { sessionId, message = "Reconstructed model not available" });
        }

        var fileBytes = await System.IO.File.ReadAllBytesAsync(status.ModelPath);
        return File(fileBytes, "application/octet-stream", Path.GetFileName(status.ModelPath));
    }

    [HttpGet("{sessionId}/measurements")]
    public async Task<ActionResult<MeasurementResult>> GetMeasurements(string sessionId)
    {
        var measurements = await _reconstructionService.GetMeasurementResultAsync(sessionId);
        if (measurements == null)
        {
            return NotFound(new { sessionId, message = "Measurements not available" });
        }

        return Ok(measurements);
    }

    /// <summary>
    /// Health check endpoint.
    /// </summary>
    [HttpGet("health")]
    public ActionResult<object> HealthCheck()
    {
        return Ok(new { status = "healthy", timestamp = DateTime.UtcNow });
    }
}
