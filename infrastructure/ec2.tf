# Data source to get the latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Security group for EC2 instance
resource "aws_security_group" "streamlit_sg" {
  name        = "${var.project_name}-streamlit-sg-${var.environment}"
  description = "Security group for Streamlit EC2 instance"
  vpc_id      = aws_vpc.main.id

  # Streamlit port
  ingress {
    from_port   = 8501
    to_port     = 8501
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  # SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  # All outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-streamlit-sg-${var.environment}"
  }
}

# EC2 instance for Streamlit
resource "aws_instance" "streamlit" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.ec2_instance_type
  key_name              = var.key_pair_name
  vpc_security_group_ids = [aws_security_group.streamlit_sg.id]
  subnet_id             = aws_subnet.public.id
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  # Cost optimization: Use Spot instances if enabled
  dynamic "instance_market_options" {
    for_each = var.enable_spot_instance ? [1] : []
    content {
      market_type = "spot"
      spot_options {
        spot_instance_type             = "persistent"
        instance_interruption_behavior = "stop"
        max_price                      = "0.02"  # Set a reasonable max price
      }
    }
  }

  # Prevent accidental termination
  disable_api_termination = false
  disable_api_stop        = false

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    project_name     = var.project_name
    environment      = var.environment
    s3_bucket_name   = aws_s3_bucket.pdf_storage.bucket
    dynamodb_table   = aws_dynamodb_table.case_data.name
    aws_region       = var.aws_region
    repository_name  = var.repository_name
  }))

  # Allow necessary recreation for AMI/user_data changes
  lifecycle {
    create_before_destroy = true
    ignore_changes = [
      key_name,              # Don't recreate when key changes
    ]
  }

  tags = {
    Name = "${var.project_name}-streamlit-${var.environment}"
  }
}

# Elastic IP for consistent access
resource "aws_eip" "streamlit_eip" {
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-streamlit-eip-${var.environment}"
  }
}

# Associate EIP with the instance
resource "aws_eip_association" "streamlit_eip_assoc" {
  instance_id   = aws_instance.streamlit.id
  allocation_id = aws_eip.streamlit_eip.id
}
