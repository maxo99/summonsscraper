#!/bin/bash
# Focused cleanup script for confirmed orphaned resources

set -e

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

# Orphaned Elastic IPs found by the scan
ORPHANED_EIPS=(
    "eipalloc-0a4fe7132d882f251"  # 18.235.72.117
    "eipalloc-013e7ca1bd564f0bd"  # 54.204.15.234
)

echo
log "=== CLEANING UP ORPHANED RESOURCES ==="
echo

# 1. Clean up orphaned Elastic IPs
log "🧹 Cleaning up orphaned Elastic IPs..."
for eip in "${ORPHANED_EIPS[@]}"; do
    EIP_IP=$(aws ec2 describe-addresses --allocation-ids $eip --query 'Addresses[0].PublicIp' --output text 2>/dev/null || echo "NOT_FOUND")
    
    if [ "$EIP_IP" == "NOT_FOUND" ]; then
        warn "EIP $eip not found (already deleted?)"
        continue
    fi
    
    # Double-check it's not associated
    EIP_ASSOCIATED=$(aws ec2 describe-addresses --allocation-ids $eip --query 'Addresses[0].InstanceId' --output text 2>/dev/null || echo "")
    
    if [ -n "$EIP_ASSOCIATED" ] && [ "$EIP_ASSOCIATED" != "None" ]; then
        error "EIP $eip ($EIP_IP) is associated with $EIP_ASSOCIATED - SKIPPING for safety"
        continue
    fi
    
    log "Releasing orphaned EIP: $eip ($EIP_IP)"
    if aws ec2 release-address --allocation-id $eip; then
        success "✅ Released EIP $eip ($EIP_IP)"
    else
        error "❌ Failed to release EIP $eip ($EIP_IP)"
    fi
done

# 2. Verify cleanup
echo
log "🔍 Verifying cleanup..."
REMAINING_EIPS=$(aws ec2 describe-addresses --query 'Addresses[?InstanceId==null].AllocationId' --output text)
if [ -z "$REMAINING_EIPS" ]; then
    success "✅ No unassociated Elastic IPs remaining"
else
    warn "⚠️  Still have unassociated EIPs: $REMAINING_EIPS"
fi

# 3. Cost savings summary
echo
log "=== COST SAVINGS SUMMARY ==="
echo "✅ Cleaned up orphaned Elastic IPs"
echo "💰 Monthly savings: ~$7.30 (2 EIPs × $3.65/month each)"
echo "💰 Annual savings: ~$87.60"
echo

success "🎉 Cleanup completed successfully!"
echo
warn "📝 Next steps:"
echo "   1. Monitor your AWS bill to confirm cost reduction"
echo "   2. Run the full scan script periodically to catch future orphans"
echo "   3. Consider setting up AWS Config rules for automated detection"
