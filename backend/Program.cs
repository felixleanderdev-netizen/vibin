using FormFittingPrints.API.Services;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container
builder.Services.AddControllers();
builder.Services.AddScoped<ScanStorageService>();
builder.Services.AddScoped<ReconstructionService>();
builder.Services.AddLogging();
builder.Services.AddOpenApi();

// Add CORS support for mobile app
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", builder =>
    {
        builder
            .AllowAnyOrigin()
            .AllowAnyMethod()
            .AllowAnyHeader();
    });
});

var app = builder.Build();

// Configure the HTTP request pipeline
if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
    app.UseDeveloperExceptionPage();
}

app.UseHttpsRedirection();
app.UseCors("AllowAll");
app.MapControllers();

// Health check endpoint
app.MapGet("/health", () => new { status = "ok", timestamp = DateTime.UtcNow })
    .WithName("Health")
    .WithOpenApi();

app.Run();
