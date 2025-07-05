#!/bin/bash
# Script to check EC2 instance status and Streamlit service

set -e

echo "🔍 Checking EC2 instance and Streamlit service status..."

# Get the script directory and infrastructure directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFRA_DIR="$(cd "${SCRIPT_DIR}/../infrastructure" && pwd)"

echo "📂 Using infrastructure directory: $INFRA_DIR"

# Change to infrastructure directory for tofu commands
cd "$INFRA_DIR"

# Get instance ID
INSTANCE_ID=$(tofu output -raw ec2_instance_id 2>/dev/null || echo "Instance ID not found")
if [ "$INSTANCE_ID" = "Instance ID not found" ]; then
    echo "❌ Could not get instance ID. Make sure Terraform has been applied."
    echo "💡 Expected state file at: $INFRA_DIR/terraform.tfstate"
    exit 1
fi

echo "📋 Instance ID: $INSTANCE_ID"

# Get public IP
PUBLIC_IP=$(tofu output -raw ec2_public_ip 2>/dev/null || echo "Public IP not found")
echo "🌐 Public IP: $PUBLIC_IP"

# Check instance status
echo ""
echo "🔧 Instance Status:"
aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].State.Name' --output text

# Check if we can connect
echo ""
echo "🔗 Testing connectivity:"
if [ "$PUBLIC_IP" != "Public IP not found" ]; then
    echo "Testing HTTP connection to Streamlit..."
    curl -I --connect-timeout 5 "http://$PUBLIC_IP:8501" 2>/dev/null && echo "✅ Streamlit is responding at http://$PUBLIC_IP:8501" || echo "❌ Streamlit is not responding"
else
    echo "❌ Cannot test connectivity - no public IP"
fi
