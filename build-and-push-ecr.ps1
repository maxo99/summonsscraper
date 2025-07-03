#!/usr/bin/function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Blue
}uild and Push to ECR Script for Windows PowerShell
# This script builds Docker images and pushes them to Amazon ECR

param(
    [string]$Environment = "dev",
    [string]$AWSRegion = "us-east-1",
    [string]$ProjectName = "summonsscraper"
)

# Color functions for output
function Write-Success {
    param([string]$Message)
    Write-Host "✅ $Message" -ForegroundColor Green
}

function Write-Error {
    param([string]$Message)
    Write-Host "❌ $Message" -ForegroundColor Red
}

function Write-Info {
    param([string]$Message)
    Write-Host "ℹ️  $Message" -ForegroundColor Cyan
}

function Write-Warning {
    param([string]$Message)
    Write-Host "⚠️  $Message" -ForegroundColor Yellow
}

# Check if Docker is running
Write-Info "Checking Docker..."
try {
    docker version | Out-Null
    Write-Success "Docker is running"
} catch {
    Write-Error "Docker is not running. Please start Docker and try again."
    exit 1
}

# Check if AWS CLI is available
Write-Info "Checking AWS CLI..."
try {
    aws --version | Out-Null
    Write-Success "AWS CLI is available"
} catch {
    Write-Error "AWS CLI is not installed. Please install AWS CLI and try again."
    exit 1
}

# Get ECR repository URLs from Terraform outputs
Write-Info "Getting ECR repository URLs from Terraform..."
try {
    Set-Location infrastructure
    $WebscraperRepo = tofu output -raw ecr_webscraper_repository_url
    $PDFParserRepo = tofu output -raw ecr_pdf_parser_repository_url
    Set-Location ..
    
    if (-not $WebscraperRepo -or -not $PDFParserRepo) {
        throw "Failed to get repository URLs"
    }
    
    Write-Success "Got ECR repository URLs"
    Write-Info "Webscraper: $WebscraperRepo"
    Write-Info "PDF Parser: $PDFParserRepo"
} catch {
    Write-Error "Failed to get ECR repository URLs. Make sure Terraform has been applied first."
    Write-Info "Run 'tofu apply' in the infrastructure directory first."
    exit 1
}

# Login to ECR using PowerShell variables approach
Write-Info "Logging in to Amazon ECR..."
try {
    $EcrDomain = $WebscraperRepo.Split('/')[0]
    Write-Info "ECR Domain: $EcrDomain"
    
    # Get the login password first
    $LoginPassword = aws ecr get-login-password --region $AWSRegion
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrEmpty($LoginPassword)) {
        throw "Failed to get ECR login password"
    }
    
    # Use the password for Docker login
    Write-Info "Attempting Docker login to ECR..."
    $LoginPassword | docker login --username AWS --password-stdin $EcrDomain
    
    if ($LASTEXITCODE -ne 0) {
        throw "ECR login failed with exit code $LASTEXITCODE"
    }
    Write-Success "Successfully logged in to ECR"
} catch {
    Write-Error "Failed to login to ECR: $_"
    Write-Info "Make sure your AWS credentials are configured correctly."
    Write-Info "You can also try running: aws configure"
    exit 1
}

# Build and tag images
$Tags = @("latest", "$Environment-local")
$Images = @()

foreach ($Tag in $Tags) {
    # Build Webscraper
    Write-Info "Building webscraper image with tag: $Tag"
    try {
        docker build -t "${WebscraperRepo}:${Tag}" -f src/webscraper/Dockerfile .
        if ($LASTEXITCODE -ne 0) {
            throw "Build failed"
        }
        $Images += "${WebscraperRepo}:${Tag}"
        Write-Success "Built webscraper:$Tag"
    } catch {
        Write-Error "Failed to build webscraper:$Tag"
        exit 1
    }

    # Build PDF Parser
    Write-Info "Building pdf_parser image with tag: $Tag"
    try {
        docker build -t "${PDFParserRepo}:${Tag}" -f src/pdf_parser/Dockerfile .
        if ($LASTEXITCODE -ne 0) {
            throw "Build failed"
        }
        $Images += "${PDFParserRepo}:${Tag}"
        Write-Success "Built pdf_parser:$Tag"
    } catch {
        Write-Error "Failed to build pdf_parser:$Tag"
        exit 1
    }
}

# Push all images
Write-Info "Pushing images to ECR..."
$PushedImages = @()

foreach ($Image in $Images) {
    try {
        Write-Info "Pushing $Image..."
        docker push $Image
        if ($LASTEXITCODE -ne 0) {
            throw "Push failed"
        }
        $PushedImages += $Image
        Write-Success "Pushed $Image"
    } catch {
        Write-Error "Failed to push $Image"
        exit 1
    }
}

# Summary
Write-Success "Successfully built and pushed all images to ECR!"
Write-Info ""
Write-Info "Images pushed:"
foreach ($Image in $PushedImages) {
    Write-Info "  - $Image"
}

Write-Info ""
Write-Info "You can now run: tofu apply to deploy your infrastructure with the updated Lambda images!"
