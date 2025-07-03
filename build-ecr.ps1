#!/usr/bin/env pwsh

# Build and Push to ECR Script for Windows PowerShell
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

# Login to ECR
Write-Info "Logging in to Amazon ECR..."
try {
    $registryUrl = $WebscraperRepo.Split('/')[0]
    $loginPassword = aws ecr get-login-password --region $AWSRegion
    $loginPassword | docker login --username AWS --password-stdin $registryUrl
    
    if ($LASTEXITCODE -ne 0) {
        throw "ECR login failed"
    }
    Write-Success "Successfully logged in to ECR"
} catch {
    Write-Error "Failed to login to ECR: $_"
    Write-Info "Make sure your AWS credentials are configured correctly."
    exit 1
}

# Build and tag images (latest only)
$Images = @()

# Build Webscraper
Write-Info "Building webscraper image..."
try {
    docker build -t "${WebscraperRepo}:latest" -f src/webscraper/Dockerfile .
    if ($LASTEXITCODE -ne 0) {
        throw "Build failed"
    }
    $Images += "${WebscraperRepo}:latest"
    Write-Success "Built webscraper:latest"
} catch {
    Write-Error "Failed to build webscraper"
    exit 1
}

# Build PDF Parser
Write-Info "Building pdf_parser image..."
try {
    docker build -t "${PDFParserRepo}:latest" -f src/pdf_parser/Dockerfile .
    if ($LASTEXITCODE -ne 0) {
        throw "Build failed"
    }
    $Images += "${PDFParserRepo}:latest"
    Write-Success "Built pdf_parser:latest"
} catch {
    Write-Error "Failed to build pdf_parser"
    exit 1
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
    Write-Info "  • $Image"
}

Write-Info ""
Write-Info "🚀 You can now run: tofu apply to deploy your infrastructure with the updated Lambda images!"
