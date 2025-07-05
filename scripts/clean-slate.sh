#!/bin/bash
# CAUTION: This script will DELETE existing AWS resources
# Only use this if you're sure you want to recreate everything

set -e

# Get the script directory and infrastructure directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFRA_DIR="$(cd "${SCRIPT_DIR}/../infrastructure" && pwd)"

echo "📂 Using infrastructure directory: $INFRA_DIR"

# Change to infrastructure directory for tofu commands
cd "$INFRA_DIR"

echo "⚠️  WARNING: This will DELETE existing AWS resources!"
echo "Resources to be deleted:"
echo "  - ECR repositories (and all container images)"
echo "  - IAM roles and policies"
echo "  - DynamoDB table (and all data)"
echo ""
read -p "Are you sure you want to continue? Type 'yes' to proceed: " confirm

if [ "$confirm" != "yes" ]; then
    echo "Operation cancelled."
    exit 1
fi

echo "🗑️ Deleting existing resources..."

# Delete ECR repositories
aws ecr delete-repository --repository-name summonsscraper-webscraper --force || true
aws ecr delete-repository --repository-name summonsscraper-pdf_parser --force || true

# Delete IAM roles (this will also delete attached policies)
aws iam delete-role --role-name summonsscraper-lambda-role-dev || true
aws iam delete-role --role-name summonsscraper-ec2-role-dev || true
aws iam delete-role --role-name summonsscraper-github-actions-role-dev || true
aws iam delete-role --role-name summonsscraper-scheduler-lambda-role-dev || true

# Delete DynamoDB table
aws dynamodb delete-table --table-name summonsscraper-case-data-dev || true

echo "✅ Resources deleted. You can now run 'tofu apply' to recreate them."
