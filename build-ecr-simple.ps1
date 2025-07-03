param(
    [string]$Environment = "dev",
    [string]$AWSRegion = "us-east-1",
    [string]$ProjectName = "summonsscraper"
)

function Write-Success {
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
}

Write-Info "Checking Docker status..."
try {
    docker --version | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "Docker not found"
    }
    Write-Success "Docker is available"
} catch {
    Write-Error "Docker is not running or not installed. Please start Docker Desktop."
    exit 1
}

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
    exit 1
}

Write-Info "Logging in to Amazon ECR..."
try {
    # Use cmd for ECR login as it handles pipes better than PowerShell
    $LoginResult = cmd /c "aws ecr get-login-password --region $AWSRegion | docker login --username AWS --password-stdin $($WebscraperRepo.Split('/')[0])"
    if ($LASTEXITCODE -ne 0) {
        throw "ECR login failed"
    }
    Write-Success "Successfully logged in to ECR"
} catch {
    Write-Error "Failed to login to ECR"
    exit 1
}

$Tags = @("latest")
$Images = @()

foreach ($Tag in $Tags) {
    Write-Info "Building webscraper image with tag: $Tag"
    try {
        docker build --platform linux/amd64 -t "${WebscraperRepo}:${Tag}" -f src/webscraper/Dockerfile .
        if ($LASTEXITCODE -ne 0) {
            throw "Build failed"
        }
        $Images += "${WebscraperRepo}:${Tag}"
        Write-Success "Built webscraper:$Tag"
    } catch {
        Write-Error "Failed to build webscraper:$Tag"
        exit 1
    }

    Write-Info "Building pdf_parser image with tag: $Tag"
    try {
        docker build --platform linux/amd64 -t "${PDFParserRepo}:${Tag}" -f src/pdf_parser/Dockerfile .
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

Write-Success "Successfully built and pushed all images to ECR!"
Write-Info ""
Write-Info "Images pushed:"
foreach ($Image in $PushedImages) {
    Write-Info "  - $Image"
}
Write-Info ""
Write-Info "You can now run: tofu apply to deploy your infrastructure!"
