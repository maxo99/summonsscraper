#!/bin/bash
# Docker Build and Push Script for Local Development
# This script builds and pushes the Lambda container images to GitHub Container Registry

set -e

VERSION=${1:-"dev-local"}
REGISTRY=${2:-"ghcr.io"}
REPOSITORY=${3:-"maxo99/summonsscraper"}

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}🐳 Building and Pushing Lambda Container Images${NC}"
echo "Registry: $REGISTRY"
echo "Repository: $REPOSITORY"
echo "Version: $VERSION"
echo ""

# Check if Docker is running
echo -e "${YELLOW}🔍 Checking Docker...${NC}"
docker version > /dev/null 2>&1

# Check authentication
echo -e "${YELLOW}🔑 Checking GitHub Container Registry authentication...${NC}"
if ! docker manifest inspect "$REGISTRY/hello-world:latest" > /dev/null 2>&1; then
    echo -e "${YELLOW}⚠️  Not authenticated with GitHub Container Registry${NC}"
    echo "Please run: docker login ghcr.io"
    echo "Use your GitHub username and a Personal Access Token with 'write:packages' permission"
    echo ""
    echo "To create a token:"
    echo "1. Go to https://github.com/settings/tokens"
    echo "2. Generate new token (classic)"
    echo "3. Select 'write:packages' scope"
    echo "4. Use token as password when prompted"
    echo ""
    read -p "Press Enter after logging in, or Ctrl+C to quit..."
fi

# Build and push webscraper image
echo -e "${GREEN}📦 Building webscraper image...${NC}"
WEBSCRAPER_IMAGE="$REGISTRY/$REPOSITORY-webscraper:$VERSION"
docker build -f src/webscraper/Dockerfile -t "$WEBSCRAPER_IMAGE" --build-arg VERSION="$VERSION" .

echo -e "${GREEN}🚀 Pushing webscraper image...${NC}"
docker push "$WEBSCRAPER_IMAGE"

# Build and push pdf_parser image  
echo -e "${GREEN}📦 Building pdf_parser image...${NC}"
PDF_PARSER_IMAGE="$REGISTRY/$REPOSITORY-pdf_parser:$VERSION"
docker build -f src/pdf_parser/Dockerfile -t "$PDF_PARSER_IMAGE" --build-arg VERSION="$VERSION" .

echo -e "${GREEN}🚀 Pushing pdf_parser image...${NC}"
docker push "$PDF_PARSER_IMAGE"

# Also tag as 'latest' for the infrastructure
echo -e "${GREEN}🏷️  Tagging images as 'latest'...${NC}"
docker tag "$WEBSCRAPER_IMAGE" "$REGISTRY/$REPOSITORY-webscraper:latest"
docker tag "$PDF_PARSER_IMAGE" "$REGISTRY/$REPOSITORY-pdf_parser:latest"

docker push "$REGISTRY/$REPOSITORY-webscraper:latest"
docker push "$REGISTRY/$REPOSITORY-pdf_parser:latest"

echo ""
echo -e "${GREEN}✅ Successfully built and pushed all images!${NC}"
echo ""
echo "Images pushed:"
echo "  • $WEBSCRAPER_IMAGE"
echo "  • $PDF_PARSER_IMAGE"  
echo "  • $REGISTRY/$REPOSITORY-webscraper:latest"
echo "  • $REGISTRY/$REPOSITORY-pdf_parser:latest"
echo ""
echo -e "${GREEN}🚀 You can now run: ${YELLOW}tofu apply${GREEN} to deploy your infrastructure!${NC}"
