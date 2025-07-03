variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "summonsscraper"
}

variable "ec2_instance_type" {
  description = "EC2 instance type for Streamlit app"
  type        = string
  default     = "t3.small"
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access the EC2 instance"
  type        = list(string)
  default     = ["0.0.0.0/0"] # WARNING: This allows all IPs. Restrict in production!
}

variable "key_pair_name" {
  description = "Name of the AWS key pair for EC2 access"
  type        = string
  default     = "summonsscraper-key"
}

variable "container_registry" {
  description = "Container registry URL for Lambda images"
  type        = string
  default     = "ghcr.io"
}

variable "repository_name" {
  description = "GitHub repository name (owner/repo)"
  type        = string
  # No default - should be set via environment variable or terraform.tfvars
}

variable "enable_spot_instance" {
  description = "Use Spot instances for cost savings (up to 90% cheaper but can be interrupted)"
  type        = bool
  default     = true
}

variable "auto_shutdown_enabled" {
  description = "Enable automatic shutdown of EC2 during off-hours"
  type        = bool
  default     = true
}

variable "shutdown_schedule" {
  description = "Cron expression for when to shutdown EC2 (UTC time)"
  type        = string
  default     = "0 22 * * ? *"  # 10 PM UTC daily
}

variable "startup_schedule" {
  description = "Cron expression for when to start EC2 (UTC time)"
  type        = string
  default     = "0 8 ? * MON-FRI *"  # 8 AM UTC, Monday-Friday
}
