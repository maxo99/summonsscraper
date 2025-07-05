#!/bin/bash
# Script to import existing AWS resources into Terraform state

set -e

echo "🔄 Importing existing AWS resources into Terraform state..."

# Import ECR repositories
echo "📦 Importing ECR repositories..."
tofu import aws_ecr_repository.webscraper summonsscraper-webscraper
tofu import aws_ecr_repository.pdf_parser summonsscraper-pdf_parser

# Import IAM roles
echo "🔐 Importing IAM roles..."
tofu import aws_iam_role.lambda_role summonsscraper-lambda-role-dev
tofu import aws_iam_role.ec2_role summonsscraper-ec2-role-dev
tofu import aws_iam_role.github_actions_role summonsscraper-github-actions-role-dev

# Import DynamoDB table
echo "🗄️ Importing DynamoDB table..."
tofu import aws_dynamodb_table.case_data summonsscraper-case-data-dev

# Import IAM inline policies
echo "📋 Importing IAM inline policies..."
tofu import aws_iam_role_policy.lambda_policy summonsscraper-lambda-role-dev:summonsscraper-lambda-policy-dev || true
tofu import aws_iam_role_policy.ec2_policy summonsscraper-ec2-role-dev:summonsscraper-ec2-policy-dev || true
tofu import aws_iam_role_policy.github_actions_policy summonsscraper-github-actions-role-dev:summonsscraper-github-actions-policy-dev || true

# Import IAM instance profile
echo "👤 Importing IAM instance profile..."
tofu import aws_iam_instance_profile.ec2_profile summonsscraper-ec2-profile-dev || true

echo "✅ Import completed! Now run 'tofu plan' to see if there are any configuration drifts."
