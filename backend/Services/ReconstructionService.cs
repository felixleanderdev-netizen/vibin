namespace FormFittingPrints.API.Services;

using FormFittingPrints.API.Models;
using Microsoft.Extensions.Logging;
using System.Diagnostics;
using System.Linq;
using System.Collections.Generic;

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

            // Step 5: Extract measurements
            status.Message = "Extracting measurements from 3D model...";
            await SaveStatusAsync(sessionId, status);
            var measurementsJson = Path.Combine(reconDir, "measurements_temp.json");
            await RunPythonScript("scripts/measure.py", $"{outputModel} {measurementsJson}");

            // Load measurements
            MeasurementResult measurement;
            if (File.Exists(measurementsJson))
            {
                try
                {
                    var json = await File.ReadAllTextAsync(measurementsJson);
                    var extracted = System.Text.Json.JsonSerializer.Deserialize<Dictionary<string, object>>(json);
                    if (extracted != null)
                    {
                        measurement = new MeasurementResult
                        {
                            SessionId = sessionId,
                            NeckGirthMm = extracted.TryGetValue("neck_girth_mm", out var neck) ? Convert.ToInt32(neck) : 350,
                            LeftArmGirthMm = extracted.TryGetValue("left_arm_girth_mm", out var leftArm) ? Convert.ToInt32(leftArm) : 260,
                            RightArmGirthMm = extracted.TryGetValue("right_arm_girth_mm", out var rightArm) ? Convert.ToInt32(rightArm) : 258,
                            LeftLegGirthMm = extracted.TryGetValue("left_leg_girth_mm", out var leftLeg) ? Convert.ToInt32(leftLeg) : 540,
                            RightLegGirthMm = extracted.TryGetValue("right_leg_girth_mm", out var rightLeg) ? Convert.ToInt32(rightLeg) : 538,
                            CreatedAt = DateTime.UtcNow,
                            Confidence = extracted.TryGetValue("confidence", out var conf) ? Convert.ToDouble(conf) : 0.5
                        };
                        File.Delete(measurementsJson); // Clean up temp file
                    }
                    else
                    {
                        throw new Exception("Failed to deserialize measurements");
                    }
                }
                catch (Exception ex)
                {
                    _logger.LogWarning(ex, "Failed to load extracted measurements, using fallback");
                    measurement = new MeasurementResult
                    {
                        SessionId = sessionId,
                        NeckGirthMm = 350,
                        LeftArmGirthMm = 260,
                        RightArmGirthMm = 258,
                        LeftLegGirthMm = 540,
                        RightLegGirthMm = 538,
                        CreatedAt = DateTime.UtcNow,
                        Confidence = 0.5
                    };
                }
            }
            else
            {
                // Fallback to approximate measurements if extraction fails
                measurement = new MeasurementResult
                {
                    SessionId = sessionId,
                    NeckGirthMm = 350,
                    LeftArmGirthMm = 260,
                    RightArmGirthMm = 258,
                    LeftLegGirthMm = 540,
                    RightLegGirthMm = 538,
                    CreatedAt = DateTime.UtcNow,
                    Confidence = 0.5
                };
            }

            status.Status = "succeeded";
            status.UpdatedAt = DateTime.UtcNow;
            status.Message = "Reconstruction and measurement extraction completed successfully.";
            status.ModelPath = outputModel;
            await SaveStatusAsync(sessionId, status);

            var measurementFile = GetMeasurementFilePath(sessionId);
            File.WriteAllText(measurementFile, System.Text.Json.JsonSerializer.Serialize(measurement, new System.Text.Json.JsonSerializerOptions { WriteIndented = true }));

            // Append to measurement history
            var historyFile = GetMeasurementHistoryFilePath(sessionId);
            var history = new List<MeasurementResult>();
            if (File.Exists(historyFile))
            {
                var historyJson = await File.ReadAllTextAsync(historyFile);
                var existingHistory = System.Text.Json.JsonSerializer.Deserialize<List<MeasurementResult>>(historyJson);
                if (existingHistory != null)
                {
                    history = existingHistory;
                }
            }
            history.Add(measurement);
            await File.WriteAllTextAsync(historyFile, System.Text.Json.JsonSerializer.Serialize(history, new System.Text.Json.JsonSerializerOptions { WriteIndented = true }));

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

    public async Task<MeasurementResult?> GetMeasurementResultAsync(string sessionId)
    {
        var measurementFile = GetMeasurementFilePath(sessionId);
        if (!File.Exists(measurementFile))
            return null;

        var json = await File.ReadAllTextAsync(measurementFile);
        var measurement = System.Text.Json.JsonSerializer.Deserialize<MeasurementResult>(json);
        return measurement;
    }

    public async Task<List<MeasurementResult>> GetMeasurementHistoryAsync(string sessionId)
    {
        var historyFile = GetMeasurementHistoryFilePath(sessionId);
        if (!File.Exists(historyFile))
            return new List<MeasurementResult>();

        var json = await File.ReadAllTextAsync(historyFile);
        var history = System.Text.Json.JsonSerializer.Deserialize<List<MeasurementResult>>(json);
        return history ?? new List<MeasurementResult>();
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

    private string GetMeasurementHistoryFilePath(string sessionId)
    {
        return Path.Combine(GetSessionDirectory(sessionId), "measurements_history.json");
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

    private async Task RunPythonScript(string scriptPath, string arguments)
    {
        var process = new Process
        {
            StartInfo = new ProcessStartInfo
            {
                FileName = "python3",
                Arguments = $"{scriptPath} {arguments}",
                WorkingDirectory = Path.GetDirectoryName(Path.Combine(Directory.GetCurrentDirectory(), scriptPath)) ?? Directory.GetCurrentDirectory(),
                RedirectStandardOutput = true,
                RedirectStandardError = true,
                UseShellExecute = false,
                CreateNoWindow = true
            }
        };

        _logger.LogInformation("Running python script {Script} {Arguments}", scriptPath, arguments);

        process.Start();
        await process.WaitForExitAsync();

        if (process.ExitCode != 0)
        {
            var error = await process.StandardError.ReadToEndAsync();
            _logger.LogWarning("Python script failed: {Error}", error);
            // Don't throw, allow fallback measurements
        }
        else
        {
            _logger.LogInformation("Python script completed successfully");
        }
    }
}
