# Test Docker Build Script
# This script tests building one image at a time with verbose output

param(
    [string]$Service = "pdf_parser"
)

$Registry = "ghcr.io"
$Repository = "maxo99/summonsscraper"
$Version = "dev-local"

Write-Host "Testing $Service image build..." -ForegroundColor Green
Write-Host ""

if ($Service -eq "pdf_parser") {
    $imageName = "$Registry/$Repository-pdf_parser:$Version"
    Write-Host "Building: $imageName" -ForegroundColor Cyan
    Write-Host "Command: docker build -f src/pdf_parser/Dockerfile -t $imageName --build-arg VERSION=$Version . --no-cache --progress=plain" -ForegroundColor Gray
    docker build -f src/pdf_parser/Dockerfile -t $imageName --build-arg VERSION=$Version . --no-cache --progress=plain
} elseif ($Service -eq "webscraper") {
    $imageName = "$Registry/$Repository-webscraper:$Version"
    Write-Host "Building: $imageName" -ForegroundColor Cyan
    Write-Host "Command: docker build -f src/webscraper/Dockerfile -t $imageName --build-arg VERSION=$Version . --no-cache --progress=plain" -ForegroundColor Gray
    docker build -f src/webscraper/Dockerfile -t $imageName --build-arg VERSION=$Version . --no-cache --progress=plain
}

if ($LASTEXITCODE -eq 0) {
    Write-Host "Build successful!" -ForegroundColor Green
} else {
    Write-Host "Build failed with exit code: $LASTEXITCODE" -ForegroundColor Red
}
