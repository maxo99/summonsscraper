#!/bin/bash
# Docker Build and Push Script for Local Development
# This script builds and pushes the Lambda container images to AWS ECR

set -e

VERSION=${1:-"latest"}
AWS_ACCOUNT_ID=${2:-"018176718701"}
AWS_REGION=${3:-"us-east-1"}

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}🐳 Building and Pushing Lambda Container Images${NC}"
echo "AWS Account ID: $AWS_ACCOUNT_ID"
echo "AWS Region: $AWS_REGION"
echo "Version: $VERSION"
echo ""

# Check if Docker is running
echo -e "${YELLOW}🔍 Checking Docker...${NC}"
docker version > /dev/null 2>&1

# Check if AWS CLI is installed
echo -e "${YELLOW}� Checking AWS CLI...${NC}"
if ! command -v aws &> /dev/null; then
    echo -e "${RED}❌ AWS CLI not found. Please install AWS CLI first.${NC}"
    exit 1
fi

# Check AWS authentication and get ECR login
echo -e "${YELLOW}🔑 Authenticating with AWS ECR...${NC}"
aws ecr get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"

# Build and push webscraper image
echo -e "${GREEN}📦 Building webscraper image...${NC}"
WEBSCRAPER_IMAGE="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/summonsscraper-webscraper:$VERSION"
docker build --platform linux/amd64 --provenance=false -f src/webscraper/Dockerfile -t "$WEBSCRAPER_IMAGE" --build-arg VERSION="$VERSION" .

echo -e "${GREEN}🚀 Pushing webscraper image...${NC}"
docker push "$WEBSCRAPER_IMAGE"

# Build and push pdf_parser image  
echo -e "${GREEN}📦 Building pdf_parser image...${NC}"
PDF_PARSER_IMAGE="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/summonsscraper-pdf_parser:$VERSION"
docker build --platform linux/amd64 --provenance=false -f src/pdf_parser/Dockerfile -t "$PDF_PARSER_IMAGE" --build-arg VERSION="$VERSION" .

echo -e "${GREEN}🚀 Pushing pdf_parser image...${NC}"
docker push "$PDF_PARSER_IMAGE"

# Also tag as 'latest' for the infrastructure
echo -e "${GREEN}🏷️  Tagging images as 'latest'...${NC}"
docker tag "$WEBSCRAPER_IMAGE" "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/summonsscraper-webscraper:latest"
docker tag "$PDF_PARSER_IMAGE" "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/summonsscraper-pdf_parser:latest"

docker push "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/summonsscraper-webscraper:latest"
docker push "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/summonsscraper-pdf_parser:latest"

echo ""
echo -e "${GREEN}✅ Successfully built and pushed all images!${NC}"
echo ""
echo "Images pushed:"
echo "  • $WEBSCRAPER_IMAGE"
echo "  • $PDF_PARSER_IMAGE"  
echo "  • $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/summonsscraper-webscraper:latest"
echo "  • $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/summonsscraper-pdf_parser:latest"
echo ""
echo -e "${GREEN}🚀 You can now run: ${YELLOW}tofu apply${GREEN} to deploy your infrastructure!${NC}"
