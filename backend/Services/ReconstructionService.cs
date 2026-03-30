namespace FormFittingPrints.API.Services;

using FormFittingPrints.API.Models;
using Microsoft.Extensions.Logging;

public class ReconstructionService
{
    private readonly string _reconBaseDirectory;
    private readonly string _scanBaseDirectory;
    private readonly ILogger<ReconstructionService> _logger;

    public ReconstructionService(ILogger<ReconstructionService> logger)
    {
        _logger = logger;
        _reconBaseDirectory = Path.Combine(Directory.GetCurrentDirectory(), "reconstructions");
        _scanBaseDirectory = Path.Combine(Directory.GetCurrentDirectory(), "scans");
        Directory.CreateDirectory(_reconBaseDirectory);
    }

    public Task<ReconstructionStatus> GetStatusAsync(string sessionId)
    {
        var statusFile = GetStatusFilePath(sessionId);
        if (!File.Exists(statusFile))
        {
            return Task.FromResult(new ReconstructionStatus
            {
                SessionId = sessionId,
                Status = "not_started",
                UpdatedAt = DateTime.UtcNow,
                Message = "No reconstruction found for session."
            });
        }

        var json = File.ReadAllText(statusFile);
        var status = System.Text.Json.JsonSerializer.Deserialize<ReconstructionStatus>(json);
        if (status == null)
        {
            return Task.FromResult(new ReconstructionStatus
            {
                SessionId = sessionId,
                Status = "error",
                UpdatedAt = DateTime.UtcNow,
                Message = "Failed to parse status file."
            });
        }

        return Task.FromResult(status);
    }

    public async Task<ReconstructionStatus> StartReconstructionAsync(string sessionId)
    {
        var status = new ReconstructionStatus
        {
            SessionId = sessionId,
            Status = "processing",
            UpdatedAt = DateTime.UtcNow,
            Message = "Starting reconstruction"
        };

        EnsureDirectoryExists(sessionId);
        await SaveStatusAsync(sessionId, status);

        var scanDir = Path.Combine(_scanBaseDirectory, sessionId);
        if (!Directory.Exists(scanDir))
        {
            status.Status = "failed";
            status.UpdatedAt = DateTime.UtcNow;
            status.Message = "Scan images directory not found.";
            await SaveStatusAsync(sessionId, status);
            return status;
        }

        // TODO: Call Colmap and 3D pipeline here instead of dummy simulation.
        // Simulated work for Phase 2 scaffolding.
        try
        {
            await Task.Delay(2000); // placeholder for pipeline runtime

            var reconFolder = GetSessionDirectory(sessionId);
            var outputModel = Path.Combine(reconFolder, "model.ply");

            File.WriteAllText(outputModel, "ply\nformat ascii 1.0\nend_header\n");

            status.Status = "succeeded";
            status.UpdatedAt = DateTime.UtcNow;
            status.Message = "Reconstruction completed successfully.";
            status.ModelPath = outputModel;
            await SaveStatusAsync(sessionId, status);

            // Bootstrap some fake measurement results
            var measurement = new MeasurementResult
            {
                SessionId = sessionId,
                NeckGirthMm = 350,
                LeftArmGirthMm = 260,
                RightArmGirthMm = 258,
                LeftLegGirthMm = 540,
                RightLegGirthMm = 538,
                CreatedAt = DateTime.UtcNow,
                Confidence = 0.85
            };
            var measurementFile = GetMeasurementFilePath(sessionId);
            File.WriteAllText(measurementFile, System.Text.Json.JsonSerializer.Serialize(measurement, new System.Text.Json.JsonSerializerOptions { WriteIndented = true }));

            return status;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Reconstruction failed for session {SessionId}", sessionId);
            status.Status = "failed";
            status.UpdatedAt = DateTime.UtcNow;
            status.Message = ex.Message;
            await SaveStatusAsync(sessionId, status);
            throw;
        }
    }

    public Task<MeasurementResult?> GetMeasurementResultAsync(string sessionId)
    {
        var measurementFile = GetMeasurementFilePath(sessionId);
        if (!File.Exists(measurementFile))
            return Task.FromResult<MeasurementResult?>(null);

        var json = File.ReadAllText(measurementFile);
        var measurement = System.Text.Json.JsonSerializer.Deserialize<MeasurementResult>(json);
        return Task.FromResult(measurement);
    }

    public string GetSessionDirectory(string sessionId)
    {
        var path = Path.Combine(_reconBaseDirectory, sessionId);
        Directory.CreateDirectory(path);
        return path;
    }

    private void EnsureDirectoryExists(string sessionId)
    {
        Directory.CreateDirectory(_reconBaseDirectory);
        Directory.CreateDirectory(GetSessionDirectory(sessionId));
    }

    private string GetStatusFilePath(string sessionId)
    {
        return Path.Combine(GetSessionDirectory(sessionId), "status.json");
    }

    private string GetMeasurementFilePath(string sessionId)
    {
        return Path.Combine(GetSessionDirectory(sessionId), "measurements.json");
    }

    private async Task SaveStatusAsync(string sessionId, ReconstructionStatus status)
    {
        var statusFile = GetStatusFilePath(sessionId);
        var json = System.Text.Json.JsonSerializer.Serialize(status, new System.Text.Json.JsonSerializerOptions { WriteIndented = true });
        await File.WriteAllTextAsync(statusFile, json);
    }
}
