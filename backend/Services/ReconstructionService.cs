namespace FormFittingPrints.API.Services;

using FormFittingPrints.API.Models;
using Microsoft.Extensions.Logging;
using System.Diagnostics;
using System.Linq;

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

        // Run Colmap reconstruction pipeline
        try
        {
            var reconDir = GetSessionDirectory(sessionId);
            var databasePath = Path.Combine(reconDir, "database.db");
            var sparseDir = Path.Combine(reconDir, "sparse");
            var outputModel = Path.Combine(reconDir, "model.ply");

            // Step 1: Feature extraction
            status.Message = "Extracting features from images...";
            await SaveStatusAsync(sessionId, status);
            await RunColmapCommand("feature_extractor", $"--database_path {databasePath} --image_path {scanDir}");

            // Step 2: Feature matching
            status.Message = "Matching features...";
            await SaveStatusAsync(sessionId, status);
            await RunColmapCommand("exhaustive_matcher", $"--database_path {databasePath}");

            // Step 3: Sparse reconstruction
            status.Message = "Performing sparse reconstruction...";
            await SaveStatusAsync(sessionId, status);
            await RunColmapCommand("mapper", $"--database_path {databasePath} --image_path {scanDir} --output_path {sparseDir}");

            // Step 4: Convert to PLY
            status.Message = "Converting model to PLY...";
            await SaveStatusAsync(sessionId, status);
            var sparseModelDir = Directory.GetDirectories(sparseDir).FirstOrDefault();
            if (sparseModelDir != null)
            {
                await RunColmapCommand("model_converter", $"--input_path {sparseModelDir} --output_path {outputModel} --output_type PLY");
            }
            else
            {
                throw new Exception("No sparse model directory found.");
            }

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

    private async Task RunColmapCommand(string command, string arguments)
    {
        var process = new Process
        {
            StartInfo = new ProcessStartInfo
            {
                FileName = "colmap",
                Arguments = $"{command} {arguments}",
                RedirectStandardOutput = true,
                RedirectStandardError = true,
                UseShellExecute = false,
                CreateNoWindow = true
            }
        };

        _logger.LogInformation("Running colmap {Command} {Arguments}", command, arguments);

        process.Start();
        await process.WaitForExitAsync();

        if (process.ExitCode != 0)
        {
            var error = await process.StandardError.ReadToEndAsync();
            throw new Exception($"Colmap {command} failed: {error}");
        }

        _logger.LogInformation("Colmap {Command} completed successfully", command);
    }
}
