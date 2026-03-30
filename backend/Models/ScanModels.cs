namespace FormFittingPrints.API.Models;

public class ScanSession
{
    public string SessionId { get; set; } = Guid.NewGuid().ToString();
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public string? DeviceInfo { get; set; }
    public int ImageCount { get; set; } = 0;
    public string Status { get; set; } = "pending"; // pending, completed, processing, error
    public List<string> ImagePaths { get; set; } = new();
}

public class UploadResponse
{
    public string SessionId { get; set; } = string.Empty;
    public int ImagesReceived { get; set; } = 0;
    public string Status { get; set; } = "success";
    public DateTime Timestamp { get; set; } = DateTime.UtcNow;
    public string? Message { get; set; }
}

public class UploadRequest
{
    public IFormFileCollection? Images { get; set; }
    public string? DeviceInfo { get; set; }
}
