#!/bin/bash
# EC2 Cost Management Script
# Usage: ./cost-management.sh [start|stop|status|costs]

set -e

INSTANCE_ID=$(tofu output -raw ec2_instance_id 2>/dev/null || echo "")

if [ -z "$INSTANCE_ID" ]; then
    echo "Error: Could not get EC2 instance ID. Make sure infrastructure is deployed."
    exit 1
fi

case "${1:-status}" in
    "start")
        echo "Starting EC2 instance $INSTANCE_ID..."
        aws ec2 start-instances --instance-ids $INSTANCE_ID
        echo "Instance starting. It may take a few minutes to be fully available."
        ;;
    
    "stop")
        echo "Stopping EC2 instance $INSTANCE_ID..."
        aws ec2 stop-instances --instance-ids $INSTANCE_ID
        echo "Instance stopping. This will save money while stopped."
        ;;
    
    "status")
        echo "EC2 Instance Status:"
        aws ec2 describe-instances \
            --instance-ids $INSTANCE_ID \
            --query 'Reservations[0].Instances[0].[InstanceId,State.Name,PublicIpAddress,InstanceType]' \
            --output table
        ;;
    
    "costs")
        echo "Cost Estimates for t3.small instance:"
        echo ""
        echo "📊 PRICING COMPARISON:"
        echo "├── On-demand (24/7):     ~\$15.00/month"
        echo "├── On-demand (8h/day):   ~\$5.00/month  (67% savings)"
        echo "├── Spot (24/7):          ~\$1.50/month  (90% savings)"
        echo "└── Spot (8h/day):        ~\$0.50/month  (97% savings)"
        echo ""
        echo "💡 RECOMMENDATIONS:"
        echo "• Development: Use Spot instances with auto-scheduling"
        echo "• Production: Use On-demand with auto-scheduling"
        echo "• Manual control: Use this script to start/stop as needed"
        echo ""
        echo "Current instance type: $(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].InstanceType' --output text)"
        ;;
    
    *)
        echo "Usage: $0 [start|stop|status|costs]"
        echo ""
        echo "Commands:"
        echo "  start   - Start the EC2 instance"
        echo "  stop    - Stop the EC2 instance (saves money)"
        echo "  status  - Show current instance status"
        echo "  costs   - Show cost estimates and recommendations"
        exit 1
        ;;
esac
