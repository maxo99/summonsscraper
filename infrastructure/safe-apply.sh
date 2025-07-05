#!/bin/bash
# Safe Terraform Apply Script
# This script helps prevent orphaned instances by doing proper planning and validation

set -e

echo "🔍 Safe Terraform Apply Process"
echo "=============================="

# Check if there are any running instances that might be orphaned
echo "1. Checking for existing EC2 instances..."
EXISTING_INSTANCES=$(aws ec2 describe-instances \
  --filters "Name=instance-state-name,Values=running,pending" \
  --query 'Reservations[*].Instances[*].InstanceId' \
  --output text | wc -w)

if [ "$EXISTING_INSTANCES" -gt 0 ]; then
    echo "⚠️  Found $EXISTING_INSTANCES running instance(s)"
    echo "   Run './cleanup-duplicate-instances.sh' to identify orphaned instances"
else
    echo "✅ No running instances found"
fi

# Check Terraform state
echo ""
echo "2. Checking Terraform state..."
if [ -f "terraform.tfstate" ]; then
    TERRAFORM_INSTANCE=$(tofu show -json | jq -r '.values.root_module.resources[] | select(.type=="aws_instance" and .name=="streamlit") | .values.id // empty' 2>/dev/null || echo "")
    if [ -n "$TERRAFORM_INSTANCE" ]; then
        echo "✅ Terraform state shows managed instance: $TERRAFORM_INSTANCE"
    else
        echo "⚠️  No instance found in Terraform state"
    fi
else
    echo "ℹ️  No Terraform state file found (first deployment)"
fi

# Plan the changes
echo ""
echo "3. Planning Terraform changes..."
echo "Running: tofu plan -out=tfplan"
tofu plan -out=tfplan

echo ""
echo "4. Reviewing the plan..."
echo "📋 Changes to be applied:"
tofu show tfplan | grep -E "(Plan:|will be created|will be destroyed|will be updated|will be replaced)" || echo "No changes detected"

# Ask for confirmation
echo ""
echo "5. Confirmation required"
echo "Please review the plan above carefully."
echo "Look for any 'will be replaced' or 'will be destroyed' actions that might create orphaned resources."
echo ""
read -p "Do you want to proceed with applying these changes? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "❌ Operation cancelled."
    rm -f tfplan
    exit 1
fi

# Apply the changes
echo ""
echo "6. Applying changes..."
tofu apply tfplan

echo ""
echo "✅ Terraform apply completed successfully!"

# Clean up
rm -f tfplan

# Show current status
echo ""
echo "7. Final status check..."
./check-ec2-status.sh || echo "Status check script not found"

echo ""
echo "🎉 Safe deployment completed!"
