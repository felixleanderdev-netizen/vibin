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

public class ReconstructionStatus
{
    public string SessionId { get; set; } = string.Empty;
    public string Status { get; set; } = "not_started"; // not_started, processing, succeeded, failed
    public string? Message { get; set; }
    public string? ModelPath { get; set; } // Point cloud PLY
    public string? MeshObjPath { get; set; } // Processed OBJ mesh
    public string? MeshStlPath { get; set; } // Processed STL mesh (for 3D printing)
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
}

public class MeasurementResult
{
    public string SessionId { get; set; } = string.Empty;
    public double NeckGirthMm { get; set; }
    public double LeftArmGirthMm { get; set; }
    public double RightArmGirthMm { get; set; }
    public double LeftLegGirthMm { get; set; }
    public double RightLegGirthMm { get; set; }
    public double Confidence { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}

public class PrintStats
{
    public double[] DimensionsMm { get; set; } = [];
    public double EstimatedWeightGrams { get; set; }
    public double EstimatedPrintTimeHours { get; set; }
    public bool StlValid { get; set; }
    public string? ValidationMessage { get; set; }
}

public class PrintOrder
{
    public string SessionId { get; set; } = string.Empty;
    public string Material { get; set; } = "PLA"; // PLA, ABS, PETG, Resin
    public string Quality { get; set; } = "standard"; // draft, standard, premium
    public int Quantity { get; set; } = 1;
    public string FinishType { get; set; } = "raw"; // raw, sanded, painted
    public string ShippingAddress { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public string Status { get; set; } = "pending"; // pending, confirmed, printing, shipped, completed
}

