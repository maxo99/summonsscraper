#!/bin/bash
yum update -y

# Install Python 3.11
yum groupinstall -y "Development Tools"
yum install -y openssl-devel bzip2-devel libffi-devel xz-devel sqlite-devel

# Download and compile Python 3.11
cd /opt
wget https://www.python.org/ftp/python/3.11.9/Python-3.11.9.tgz
tar xzf Python-3.11.9.tgz
cd Python-3.11.9
./configure --enable-optimizations
make altinstall

# Create symlinks
ln -sf /usr/local/bin/python3.11 /usr/local/bin/python3
ln -sf /usr/local/bin/pip3.11 /usr/local/bin/pip3

# Install uv
curl -LsSf https://astral.sh/uv/install.sh | sh
echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> /home/ec2-user/.bashrc

# Install git
yum install -y git

# Create application directory
mkdir -p /opt/summonsscraper
chown ec2-user:ec2-user /opt/summonsscraper

# Create systemd service for Streamlit
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
ExecStart=/home/ec2-user/.cargo/bin/uv run streamlit run src/ui/main.py --server.port 8501 --server.address 0.0.0.0
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

# Enable the service (but don't start it yet - will be started after deployment)
systemctl enable streamlit

# Create deployment script
cat > /opt/deploy.sh << 'EOF'
#!/bin/bash
cd /opt/summonsscraper

# Pull latest code
git pull origin main

# Install/update dependencies
/home/ec2-user/.cargo/bin/uv pip install ".[ui]"

# Restart the service
sudo systemctl restart streamlit
EOF

chmod +x /opt/deploy.sh
chown ec2-user:ec2-user /opt/deploy.sh

# Log completion
echo "User data script completed at $(date)" >> /var/log/user-data.log
