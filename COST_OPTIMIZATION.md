# Cost-Optimized Deployment Guide

## 💰 Cost Summary with Current Configuration

### Monthly Cost Estimates (US East 1)

**t3.micro (Recommended for Development):**
- On-demand 24/7: ~$8.35/month
- **On-demand with auto-shutdown (8h/day): ~$2.78/month** ⭐ **CURRENT CONFIG**
- Spot 24/7: ~$0.84/month
- Spot with auto-shutdown (8h/day): ~$0.28/month

**Additional AWS Services:**
- Lambda functions: ~$0.20/month (very low usage)
- DynamoDB: Free tier eligible
- S3 storage: ~$0.10/month (small files)
- **Total estimated monthly cost: ~$3.00-$3.50/month**

## 🚀 Quick Deployment Steps

### 1. Configure Your Settings

Edit `infrastructure/terraform.tfvars`:

```bash
# REQUIRED: Update these values
key_pair_name = "your-actual-key-pair-name"        # Your AWS key pair
allowed_cidr_blocks = ["YOUR.IP.ADDRESS/32"]       # Your IP for security
```

### 2. Deploy Infrastructure

```powershell
cd infrastructure

# Initialize OpenTofu
tofu init

# Plan the deployment
tofu plan

# Deploy (cost: ~$3/month with current config)
tofu apply
```

### 3. Manual Cost Control

Use the cost management script:

```bash
# Check status and costs
./cost-management.sh costs
./cost-management.sh status

# Manual control
./cost-management.sh stop   # Stop to save money
./cost-management.sh start  # Start when needed
```

## 🔧 Configuration Options

### For Maximum Reliability (Small Cost Increase)
```hcl
ec2_instance_type = "t3.small"        # $15/month → $5/month with auto-shutdown
enable_spot_instance = false          # Reliable but more expensive
auto_shutdown_enabled = true          # Keep this for cost savings
```

### For Maximum Savings (Small Reliability Risk)
```hcl
ec2_instance_type = "t3.small"        # Better for spot instances
enable_spot_instance = true           # Up to 90% savings
auto_shutdown_enabled = true          # Additional savings
```

### For Testing/Development (Current Config)
```hcl
ec2_instance_type = "t3.micro"        # Cheapest option
enable_spot_instance = false          # Reliable for development
auto_shutdown_enabled = true          # Auto-saves money
```

## 📊 Auto-Shutdown Schedule

**Current schedule (UTC times):**
- **Shutdown:** 10 PM UTC daily (automatically stops)
- **Startup:** 8 AM UTC, Monday-Friday (automatically starts)
- **Savings:** ~65% cost reduction vs 24/7 operation

**To adjust for your timezone:**
1. Convert your working hours to UTC
2. Update `shutdown_schedule` and `startup_schedule` in terraform.tfvars
3. Run `tofu apply` to update

## 🛡️ Security Best Practices

1. **Update your IP address:**
   ```bash
   # Get your current IP
   curl -s https://ipinfo.io/ip
   
   # Add to terraform.tfvars
   allowed_cidr_blocks = ["YOUR.IP.HERE/32"]
   ```

2. **Use a proper key pair:**
   - Create an AWS key pair in the EC2 console
   - Update `key_pair_name` in terraform.tfvars

## 📈 Monitoring Costs

1. **AWS Cost Explorer:** Monitor actual usage in AWS console
2. **CloudWatch:** Set up billing alerts for $5-10/month
3. **Script monitoring:** Use `./cost-management.sh costs` regularly

Your infrastructure is now configured for **maximum cost efficiency with on-demand reliability**! 🎉
