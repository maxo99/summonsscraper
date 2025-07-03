# 🐳 Local Container Build and Deploy Guide

Before deploying your infrastructure, you need to build and push the Lambda container images. Here's how:

## Prerequisites

1. **Docker installed and running**
2. **GitHub Personal Access Token** with `write:packages` permission
3. **GitHub Container Registry access**

## Quick Setup Steps

### 1. Create GitHub Personal Access Token

1. Go to [GitHub Settings > Tokens](https://github.com/settings/tokens)
2. Click "Generate new token (classic)"
3. Select scopes: `write:packages` and `read:packages`
4. Copy the token (save it somewhere safe!)

### 2. Login to GitHub Container Registry

```powershell
# Login to GitHub Container Registry
docker login ghcr.io
# Username: your-github-username
# Password: paste-your-token-here
```

### 3. Build and Push Images

**Option A: PowerShell (Windows)**
```powershell
# Make script executable and run
powershell -ExecutionPolicy Bypass -File .\build-and-push.ps1
```

**Option B: Bash (Linux/Mac/WSL)**
```bash
# Make script executable and run
chmod +x build-and-push.sh
./build-and-push.sh
```

**Option C: Manual Commands**
```powershell
# Build webscraper image
docker build -f src/webscraper/Dockerfile -t ghcr.io/maxo99/summonsscraper-webscraper:latest --build-arg VERSION=dev-local .
docker push ghcr.io/maxo99/summonsscraper-webscraper:latest

# Build pdf_parser image
docker build -f src/pdf_parser/Dockerfile -t ghcr.io/maxo99/summonsscraper-pdf_parser:latest --build-arg VERSION=dev-local .
docker push ghcr.io/maxo99/summonsscraper-pdf_parser:latest
```

### 4. Deploy Infrastructure

Once images are pushed:

```powershell
cd infrastructure
tofu apply
```

## 🔧 Custom Configuration

You can customize the build with parameters:

```powershell
# PowerShell - Custom version and repository
.\build-and-push.ps1 -Version "v1.0.0" -Repository "yourusername/yourproject"

# Bash - Custom parameters
./build-and-push.sh "v1.0.0" "ghcr.io" "yourusername/yourproject"
```

## 🐛 Troubleshooting

### Authentication Issues
```powershell
# Test authentication
docker pull ghcr.io/hello-world
```

### Build Issues
```powershell
# Check Docker is running
docker version

# Clean Docker cache if needed
docker system prune -f
```

### Permission Issues
```powershell
# Verify token has correct permissions
# Token needs: write:packages, read:packages
```

## 📦 What Gets Built

The script builds two Lambda container images:

1. **Webscraper**: Selenium-based web scraping with Chrome
2. **PDF Parser**: PDF processing and text extraction

Both images are based on `amazon/aws-lambda-python:3.11` and include your shared core modules.

## 🎯 Next Steps

After successful image push:

1. ✅ Images are available in GitHub Container Registry
2. ✅ Run `tofu apply` to deploy infrastructure
3. ✅ Lambda functions will pull the images automatically
4. ✅ Your application will be live!

**Total deployment time: ~5-10 minutes** 🚀
