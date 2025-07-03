# OpenTofu Infrastructure for Summons Scraper

This directory contains the OpenTofu configuration for deploying the AWS infrastructure.

## Architecture Overview

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Streamlit     │    │   Webscraper     │    │   PDF Parser    │
│   (EC2)         │───▶│   (Lambda)       │───▶│   (Lambda)      │
│                 │    │                  │    │                 │
└─────────────────┘    └──────────────────┘    └─────────────────┘
         │                        │                       │
         │                        ▼                       ▼
         │              ┌─────────────────┐    ┌─────────────────┐
         └──────────────▶│   S3 Bucket     │    │   DynamoDB      │
                        │   (PDFs)        │    │   (Parsed Data) │
                        └─────────────────┘    └─────────────────┘
```

## Components

- **EC2 Instance**: t3.small running Streamlit UI (with cost optimization options)
- **Lambda Functions**: Webscraper and PDF parser (containerized)
- **S3 Bucket**: Storage for PDF files
- **DynamoDB**: Storage for parsed data
- **IAM Roles**: Proper permissions for all components
- **VPC/Security Groups**: Network configuration
- **Auto-Scheduler**: Optional EC2 auto-shutdown for cost savings

## Cost Optimization Features

### 1. **Spot Instances** (Optional)
- Enable with `enable_spot_instance = true`
- **Up to 90% cost savings** compared to on-demand
- Can be interrupted by AWS (suitable for dev/test environments)

### 2. **Auto-Shutdown Scheduling** (Enabled by default)
- Automatically stops EC2 during off-hours
- **Saves ~70% on compute costs** if used 8 hours/day
- Configurable schedules via cron expressions
- Default: Shutdown 10 PM UTC, Start 8 AM UTC (Mon-Fri)

### 3. **On-Demand Pricing**
- **Default configuration** uses on-demand instances
- No upfront costs, pay per hour used
- Can be combined with auto-scheduling for optimal savings

## Cost Estimates

| Configuration | Monthly Cost | Savings |
|---------------|-------------|---------|
| **On-demand 24/7** | ~$15 | Baseline |
| **On-demand + Auto-shutdown** | ~$4-6 | **60-70%** |
| **Spot + Auto-shutdown** | ~$1-2 | **85-90%** |

*Note: Spot instances best for development; use on-demand for production.*

## Prerequisites

1. OpenTofu installed
2. AWS CLI configured
3. GitHub repository secrets configured

## Local Development

```bash
# Initialize OpenTofu
cd infrastructure
tofu init

# Plan changes
tofu plan

# Apply changes (with approval)
tofu apply

# Destroy infrastructure
tofu destroy
```

## Environment Variables

Set these in your shell or CI/CD:
- `TF_VAR_environment` (dev/staging/prod)
- `AWS_REGION=us-east-1`
- `TF_VAR_enable_spot_instance=true` (optional, for cost savings)
- `TF_VAR_auto_shutdown_enabled=true` (optional, enabled by default)

## Quick Start for Cost Optimization

```bash
# For maximum cost savings (development)
export TF_VAR_enable_spot_instance=true
export TF_VAR_auto_shutdown_enabled=true

# Apply with cost optimizations
tofu apply -var="enable_spot_instance=true" -var="auto_shutdown_enabled=true"

# Manual start/stop commands
aws ec2 start-instances --instance-ids $(tofu output -raw ec2_instance_id)
aws ec2 stop-instances --instance-ids $(tofu output -raw ec2_instance_id)
```
