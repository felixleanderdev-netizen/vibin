using Microsoft.AspNetCore.Mvc;
using FormFittingPrints.API.Models;
using FormFittingPrints.API.Services;

namespace FormFittingPrints.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public class ScansController : ControllerBase
{
    private readonly ScanStorageService _storageService;
    private readonly ILogger<ScansController> _logger;

    public ScansController(ScanStorageService storageService, ILogger<ScansController> logger)
    {
        _storageService = storageService;
        _logger = logger;
    }

    /// <summary>
    /// Upload images for a body scan session.
    /// </summary>
    /// <remarks>
    /// Accepts multiple image files (JPEG, PNG) and optional device information.
    /// Files are stored in session-specific directory: scans/{sessionId}/
    /// </remarks>
    [HttpPost("upload")]
    [RequestSizeLimit(1_000_000_000)] // 1 GB for entire request
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

            _logger.LogInformation("Received upload with {ImageCount} images", images.Count);

            var session = await _storageService.SaveScanImagesAsync(images, deviceInfo);

            var response = new UploadResponse
            {
                SessionId = session.SessionId,
                ImagesReceived = session.ImageCount,
                Status = session.Status,
                Message = session.Status == "completed" 
                    ? $"Successfully stored {session.ImageCount} images" 
                    : "No valid images were stored"
            };

            return Ok(response);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error processing upload");
            return StatusCode(500, new UploadResponse
            {
                Status = "error",
                Message = "Internal server error during image storage"
            });
        }
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
