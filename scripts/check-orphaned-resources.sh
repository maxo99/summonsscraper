#!/bin/bash
# Comprehensive cleanup script for orphaned AWS resources
# This script identifies and helps clean up resources not in the current Terraform state

set -e

# Get the script directory and infrastructure directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFRA_DIR="$(cd "${SCRIPT_DIR}/../infrastructure" && pwd)"

echo "📂 Using infrastructure directory: $INFRA_DIR"

# Change to infrastructure directory for tofu commands
cd "$INFRA_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
}

success() {
    echo -e "${GREEN}[SUCCESS] $1${NC}"
}

# Check if AWS CLI is available
if ! command -v aws &> /dev/null; then
    error "AWS CLI is not installed or not in PATH"
    exit 1
fi

# Get current region
REGION=$(aws configure get region 2>/dev/null || echo "us-east-1")
log "Working in region: $REGION"

# Get current Terraform-managed resources
log "Getting current Terraform state resources..."
MANAGED_VPC=""
MANAGED_SUBNET=""
MANAGED_IGW=""
MANAGED_RT=""
MANAGED_SG=""
MANAGED_EIP=""
MANAGED_INSTANCE=""

if [ -f "terraform.tfstate" ]; then
    MANAGED_VPC=$(tofu show -json | jq -r '.values.root_module.resources[] | select(.type == "aws_vpc") | .values.id' 2>/dev/null || echo "")
    MANAGED_SUBNET=$(tofu show -json | jq -r '.values.root_module.resources[] | select(.type == "aws_subnet") | .values.id' 2>/dev/null || echo "")
    MANAGED_IGW=$(tofu show -json | jq -r '.values.root_module.resources[] | select(.type == "aws_internet_gateway") | .values.id' 2>/dev/null || echo "")
    MANAGED_RT=$(tofu show -json | jq -r '.values.root_module.resources[] | select(.type == "aws_route_table") | .values.id' 2>/dev/null || echo "")
    MANAGED_SG=$(tofu show -json | jq -r '.values.root_module.resources[] | select(.type == "aws_security_group") | .values.id' 2>/dev/null || echo "")
    MANAGED_EIP=$(tofu show -json | jq -r '.values.root_module.resources[] | select(.type == "aws_eip") | .values.id' 2>/dev/null || echo "")
    MANAGED_INSTANCE=$(tofu show -json | jq -r '.values.root_module.resources[] | select(.type == "aws_instance") | .values.id' 2>/dev/null || echo "")
fi

log "Managed VPC: $MANAGED_VPC"
log "Managed Subnet: $MANAGED_SUBNET"
log "Managed Instance: $MANAGED_INSTANCE"

echo
log "=== SCANNING FOR ORPHANED RESOURCES ==="
echo

# 1. Find all VPCs
log "🔍 Scanning VPCs..."
ALL_VPCS=$(aws ec2 describe-vpcs --query 'Vpcs[].VpcId' --output text)
DEFAULT_VPC=$(aws ec2 describe-vpcs --filters "Name=isDefault,Values=true" --query 'Vpcs[0].VpcId' --output text 2>/dev/null || echo "")

echo "All VPCs found:"
for vpc in $ALL_VPCS; do
    VPC_NAME=$(aws ec2 describe-vpcs --vpc-ids $vpc --query 'Vpcs[0].Tags[?Key==`Name`].Value' --output text 2>/dev/null || echo "")
    VPC_DEFAULT=$(aws ec2 describe-vpcs --vpc-ids $vpc --query 'Vpcs[0].IsDefault' --output text 2>/dev/null || echo "false")
    
    if [ "$vpc" == "$MANAGED_VPC" ]; then
        success "  ✅ $vpc ($VPC_NAME) - MANAGED by Terraform"
    elif [ "$vpc" == "$DEFAULT_VPC" ] || [ "$VPC_DEFAULT" == "true" ]; then
        echo "  ⚠️  $vpc ($VPC_NAME) - DEFAULT VPC (keep)"
    else
        warn "  ❌ $vpc ($VPC_NAME) - ORPHANED"
        echo "      Command to delete: aws ec2 delete-vpc --vpc-id $vpc"
    fi
done

# 2. Find all EC2 instances
log "🔍 Scanning EC2 Instances..."
ALL_INSTANCES=$(aws ec2 describe-instances --query 'Reservations[].Instances[?State.Name!=`terminated`].InstanceId' --output text)

echo "All running instances:"
for instance in $ALL_INSTANCES; do
    INSTANCE_NAME=$(aws ec2 describe-instances --instance-ids $instance --query 'Reservations[0].Instances[0].Tags[?Key==`Name`].Value' --output text 2>/dev/null || echo "")
    INSTANCE_STATE=$(aws ec2 describe-instances --instance-ids $instance --query 'Reservations[0].Instances[0].State.Name' --output text 2>/dev/null || echo "")
    
    if [ "$instance" == "$MANAGED_INSTANCE" ]; then
        success "  ✅ $instance ($INSTANCE_NAME) - MANAGED by Terraform"
    else
        warn "  ❌ $instance ($INSTANCE_NAME) - State: $INSTANCE_STATE - ORPHANED"
        echo "      Command to terminate: aws ec2 terminate-instances --instance-ids $instance"
    fi
done

# 3. Find all Elastic IPs
log "🔍 Scanning Elastic IPs..."
ALL_EIPS=$(aws ec2 describe-addresses --query 'Addresses[].AllocationId' --output text)

echo "All Elastic IPs:"
for eip in $ALL_EIPS; do
    EIP_IP=$(aws ec2 describe-addresses --allocation-ids $eip --query 'Addresses[0].PublicIp' --output text 2>/dev/null || echo "")
    EIP_ASSOCIATED=$(aws ec2 describe-addresses --allocation-ids $eip --query 'Addresses[0].InstanceId' --output text 2>/dev/null || echo "")
    
    if [ "$eip" == "$MANAGED_EIP" ]; then
        success "  ✅ $eip ($EIP_IP) - MANAGED by Terraform"
    elif [ "$EIP_ASSOCIATED" == "None" ] || [ -z "$EIP_ASSOCIATED" ]; then
        warn "  ❌ $eip ($EIP_IP) - UNASSOCIATED - ORPHANED"
        echo "      Command to release: aws ec2 release-address --allocation-id $eip"
    else
        echo "  ⚠️  $eip ($EIP_IP) - Associated with $EIP_ASSOCIATED"
    fi
done

# 4. Find all Security Groups
log "🔍 Scanning Security Groups..."
ALL_SGS=$(aws ec2 describe-security-groups --query 'SecurityGroups[?GroupName!=`default`].GroupId' --output text)

echo "All non-default Security Groups:"
for sg in $ALL_SGS; do
    SG_NAME=$(aws ec2 describe-security-groups --group-ids $sg --query 'SecurityGroups[0].GroupName' --output text 2>/dev/null || echo "")
    SG_VPC=$(aws ec2 describe-security-groups --group-ids $sg --query 'SecurityGroups[0].VpcId' --output text 2>/dev/null || echo "")
    
    if [ "$sg" == "$MANAGED_SG" ]; then
        success "  ✅ $sg ($SG_NAME) - MANAGED by Terraform"
    else
        warn "  ❌ $sg ($SG_NAME) in VPC $SG_VPC - ORPHANED"
        echo "      Command to delete: aws ec2 delete-security-group --group-id $sg"
    fi
done

# 5. Find all Subnets
log "🔍 Scanning Subnets..."
ALL_SUBNETS=$(aws ec2 describe-subnets --query 'Subnets[].SubnetId' --output text)

echo "All Subnets:"
for subnet in $ALL_SUBNETS; do
    SUBNET_VPC=$(aws ec2 describe-subnets --subnet-ids $subnet --query 'Subnets[0].VpcId' --output text 2>/dev/null || echo "")
    SUBNET_NAME=$(aws ec2 describe-subnets --subnet-ids $subnet --query 'Subnets[0].Tags[?Key==`Name`].Value' --output text 2>/dev/null || echo "")
    
    if [ "$subnet" == "$MANAGED_SUBNET" ]; then
        success "  ✅ $subnet ($SUBNET_NAME) in VPC $SUBNET_VPC - MANAGED by Terraform"
    elif [ "$SUBNET_VPC" == "$DEFAULT_VPC" ]; then
        echo "  ⚠️  $subnet ($SUBNET_NAME) in DEFAULT VPC $SUBNET_VPC (keep)"
    else
        warn "  ❌ $subnet ($SUBNET_NAME) in VPC $SUBNET_VPC - ORPHANED"
        echo "      Command to delete: aws ec2 delete-subnet --subnet-id $subnet"
    fi
done

# 6. Find all Internet Gateways
log "🔍 Scanning Internet Gateways..."
ALL_IGWS=$(aws ec2 describe-internet-gateways --query 'InternetGateways[].InternetGatewayId' --output text)

echo "All Internet Gateways:"
for igw in $ALL_IGWS; do
    IGW_VPC=$(aws ec2 describe-internet-gateways --internet-gateway-ids $igw --query 'InternetGateways[0].Attachments[0].VpcId' --output text 2>/dev/null || echo "")
    IGW_NAME=$(aws ec2 describe-internet-gateways --internet-gateway-ids $igw --query 'InternetGateways[0].Tags[?Key==`Name`].Value' --output text 2>/dev/null || echo "")
    
    if [ "$igw" == "$MANAGED_IGW" ]; then
        success "  ✅ $igw ($IGW_NAME) - MANAGED by Terraform"
    elif [ "$IGW_VPC" == "$DEFAULT_VPC" ]; then
        echo "  ⚠️  $igw ($IGW_NAME) attached to DEFAULT VPC $IGW_VPC (keep)"
    elif [ -z "$IGW_VPC" ] || [ "$IGW_VPC" == "None" ]; then
        warn "  ❌ $igw ($IGW_NAME) - UNATTACHED - ORPHANED"
        echo "      Command to delete: aws ec2 delete-internet-gateway --internet-gateway-id $igw"
    else
        warn "  ❌ $igw ($IGW_NAME) attached to VPC $IGW_VPC - ORPHANED"
        echo "      Commands to delete:"
        echo "        aws ec2 detach-internet-gateway --internet-gateway-id $igw --vpc-id $IGW_VPC"
        echo "        aws ec2 delete-internet-gateway --internet-gateway-id $igw"
    fi
done

# 7. Find all Route Tables
log "🔍 Scanning Route Tables..."
ALL_RTS=$(aws ec2 describe-route-tables --query 'RouteTables[].RouteTableId' --output text)

echo "All Route Tables:"
for rt in $ALL_RTS; do
    RT_VPC=$(aws ec2 describe-route-tables --route-table-ids $rt --query 'RouteTables[0].VpcId' --output text 2>/dev/null || echo "")
    RT_MAIN=$(aws ec2 describe-route-tables --route-table-ids $rt --query 'RouteTables[0].Associations[?Main==`true`]' --output text 2>/dev/null || echo "")
    RT_NAME=$(aws ec2 describe-route-tables --route-table-ids $rt --query 'RouteTables[0].Tags[?Key==`Name`].Value' --output text 2>/dev/null || echo "")
    
    if [ "$rt" == "$MANAGED_RT" ]; then
        success "  ✅ $rt ($RT_NAME) - MANAGED by Terraform"
    elif [ "$RT_VPC" == "$DEFAULT_VPC" ]; then
        echo "  ⚠️  $rt ($RT_NAME) in DEFAULT VPC $RT_VPC (keep)"
    elif [ -n "$RT_MAIN" ]; then
        echo "  ⚠️  $rt ($RT_NAME) - MAIN route table for VPC $RT_VPC (automatic)"
    else
        warn "  ❌ $rt ($RT_NAME) in VPC $RT_VPC - ORPHANED"
        echo "      Command to delete: aws ec2 delete-route-table --route-table-id $rt"
    fi
done

echo
log "=== CLEANUP SUMMARY ==="
echo "Review the orphaned resources above and run the suggested commands to clean them up."
echo "⚠️  BE CAREFUL: Only delete resources you're sure are not needed!"
echo "✅ Resources marked as MANAGED are controlled by your current Terraform state."
echo "⚠️  Resources in DEFAULT VPC are usually needed for account functionality."
echo
warn "Always verify resources before deletion. Consider running commands with --dry-run first where available."
