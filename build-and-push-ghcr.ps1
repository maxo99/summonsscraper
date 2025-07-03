# Docker Build and Push Script for Local Development
# This script builds and pushes the Lambda container images to GitHub Container Registry
# Run this before deploying infrastructure to ensure images are available

param(
    [string]$Version = "dev-local",
    [string]$Registry = "ghcr.io",
    [string]$Repository = "maxo99/summonsscraper"
)

Write-Host "Building and Pushing Lambda Container Images" -ForegroundColor Green
Write-Host "Registry: $Registry"
Write-Host "Repository: $Repository"  
Write-Host "Version: $Version"
Write-Host ""

# Function to check if command succeeded
function Check-Command {
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Command failed with exit code $LASTEXITCODE" -ForegroundColor Red
        exit 1
    }
}

# Check if Docker is running
Write-Host "Checking Docker..." -ForegroundColor Yellow
docker version --format '{{.Server.Version}}' > $null 2>&1
Check-Command

# Check if logged into GitHub Container Registry
Write-Host "Checking GitHub Container Registry authentication..." -ForegroundColor Yellow
$authCheck = docker manifest inspect "$Registry/hello-world:latest" 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "Not authenticated with GitHub Container Registry" -ForegroundColor Yellow
    Write-Host "Please run: " -NoNewline
    Write-Host "docker login ghcr.io" -ForegroundColor Cyan
    Write-Host "Use your GitHub username and a Personal Access Token with 'write:packages' permission"
    Write-Host ""
    Write-Host "To create a token:"
    Write-Host "1. Go to https://github.com/settings/tokens"
    Write-Host "2. Generate new token (classic)"
    Write-Host "3. Select 'write:packages' scope"
    Write-Host "4. Use token as password when prompted"
    Write-Host ""
    $continue = Read-Host "Press Enter after logging in, or 'q' to quit"
    if ($continue -eq 'q') { exit 1 }
}

# Build and push webscraper image
Write-Host "Building webscraper image..." -ForegroundColor Green
$webscraperImage = "$Registry/$Repository-webscraper:$Version"
Write-Host "Command: docker build -f src/webscraper/Dockerfile -t $webscraperImage --build-arg VERSION=$Version ." -ForegroundColor Gray
docker build -f src/webscraper/Dockerfile -t $webscraperImage --build-arg VERSION=$Version . --progress=plain
Check-Command

Write-Host "Pushing webscraper image..." -ForegroundColor Green
docker push $webscraperImage
Check-Command

# Build and push pdf_parser image  
Write-Host "Building pdf_parser image..." -ForegroundColor Green
$pdfParserImage = "$Registry/$Repository-pdf_parser:$Version"
Write-Host "Command: docker build -f src/pdf_parser/Dockerfile -t $pdfParserImage --build-arg VERSION=$Version ." -ForegroundColor Gray
docker build -f src/pdf_parser/Dockerfile -t $pdfParserImage --build-arg VERSION=$Version . --progress=plain
Check-Command

Write-Host "Pushing pdf_parser image..." -ForegroundColor Green
docker push $pdfParserImage
Check-Command

# Also tag as 'latest' for the infrastructure
Write-Host "Tagging images as 'latest'..." -ForegroundColor Green
docker tag $webscraperImage "$Registry/$Repository-webscraper:latest"
docker tag $pdfParserImage "$Registry/$Repository-pdf_parser:latest"

docker push "$Registry/$Repository-webscraper:latest"
Check-Command
docker push "$Registry/$Repository-pdf_parser:latest"
Check-Command

Write-Host ""
Write-Host "Successfully built and pushed all images!" -ForegroundColor Green
Write-Host ""
Write-Host "Images pushed:"
Write-Host "  • $webscraperImage"
Write-Host "  • $pdfParserImage"  
Write-Host "  • $Registry/$Repository-webscraper:latest"
Write-Host "  • $Registry/$Repository-pdf_parser:latest"
Write-Host ""
Write-Host "You can now run: " -NoNewline -ForegroundColor Green
Write-Host "tofu apply" -ForegroundColor Cyan -NoNewline
Write-Host " to deploy your infrastructure!" -ForegroundColor Green
