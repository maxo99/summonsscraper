#!/bin/bash
# Optimized user_data script for Amazon Linux 2023

# Enable logging
exec > >(tee /var/log/user-data.log)
exec 2>&1

set -e

# Function to log with timestamp
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Function to check if a step was completed
check_step() {
    [ -f "/var/log/setup-$1.done" ]
}

# Function to mark step as completed
mark_step() {
    touch "/var/log/setup-$1.done"
    log "✅ Step $1 completed"
}

log "🚀 Starting user_data script for Amazon Linux 2023"

# Step 1: System update
if ! check_step "system-update"; then
    log "📦 Updating system packages..."
    dnf update -y
    mark_step "system-update"
fi

# Step 2: Install basic development tools
if ! check_step "dev-tools"; then
    log "🔧 Installing development tools..."
    dnf groupinstall -y "Development Tools"
    dnf install -y openssl-devel bzip2-devel libffi-devel xz-devel sqlite-devel git
    mark_step "dev-tools"
fi

# Step 3: Install uv (Python package manager)
if ! check_step "uv-install"; then
    log "📦 Installing uv..."
    sudo -u ec2-user bash -c 'curl -LsSf https://astral.sh/uv/install.sh | sh'
    mark_step "uv-install"
fi

# Step 4: Setup application directory and clone repository
if ! check_step "repo-clone"; then
    log "📁 Setting up application directory..."
    mkdir -p /opt/summonsscraper
    chown ec2-user:ec2-user /opt/summonsscraper
    
    log "📥 Cloning repository..."
    cd /opt/summonsscraper
    sudo -u ec2-user git clone https://github.com/${repository_name}.git .
    chown -R ec2-user:ec2-user /opt/summonsscraper
    mark_step "repo-clone"
fi

# Step 5: Create systemd service
if ! check_step "systemd-service"; then
    log "⚙️ Creating systemd service..."
    cat > /etc/systemd/system/streamlit.service << EOF
[Unit]
Description=Streamlit Application
After=network.target

[Service]
Type=simple
User=ec2-user
WorkingDirectory=/opt/summonsscraper
Environment=PATH=/home/ec2-user/.cargo/bin:/usr/local/bin:/usr/bin:/bin
Environment=AWS_DEFAULT_REGION=${aws_region}
Environment=APP_AWS_REGION=${aws_region}
Environment=S3_BUCKET_NAME=${s3_bucket_name}
Environment=DYNAMODB_TABLE_NAME=${dynamodb_table}
ExecStart=/home/ec2-user/.cargo/bin/uv run --extra ui streamlit run src/ui/main.py --server.port 8501 --server.address 0.0.0.0
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF
    
    systemctl enable streamlit
    mark_step "systemd-service"
fi

# Step 6: Install dependencies and start service
if ! check_step "app-setup"; then
    log "📦 Installing application dependencies..."
    cd /opt/summonsscraper
    sudo -u ec2-user bash -c 'export PATH="/home/ec2-user/.cargo/bin:$PATH" && /home/ec2-user/.cargo/bin/uv sync --extra ui'

    log "🚀 Starting Streamlit service..."
    systemctl start streamlit
    mark_step "app-setup"
fi

# Step 7: Create deployment script
if ! check_step "deploy-script"; then
    log "📝 Creating deployment script..."
    cat > /opt/deploy.sh << 'EOF'
#!/bin/bash
cd /opt/summonsscraper

# Pull latest code
git pull origin main

# Install/update dependencies using uv
export PATH="/home/ec2-user/.cargo/bin:$PATH"
/home/ec2-user/.cargo/bin/uv sync --extra ui

# Restart the service
sudo systemctl restart streamlit
EOF
    
    chmod +x /opt/deploy.sh
    chown ec2-user:ec2-user /opt/deploy.sh
    mark_step "deploy-script"
fi

log "✅ User data script completed successfully at $(date)"