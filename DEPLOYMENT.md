# Deployment Configuration

## Environment Variables
Create the following GitHub Secrets in your repository settings:

### For Container Registry
- `GITHUB_TOKEN` (automatically provided by GitHub)

### For EC2 Deployment (Optional)
- `EC2_SSH_KEY` - Private SSH key for EC2 access
- `EC2_HOST` - EC2 instance hostname/IP
- `EC2_USER` - SSH username (e.g., ec2-user, ubuntu)

### For AWS Lambda Deployment (Optional)
- `AWS_ACCESS_KEY_ID` - AWS access key
- `AWS_SECRET_ACCESS_KEY` - AWS secret key
- `AWS_REGION` - AWS region for Lambda deployment

## Container Images
The workflow will build and push the following images to GitHub Container Registry:

- `ghcr.io/{owner}/{repo}-webscraper:v{version}`
- `ghcr.io/{owner}/{repo}-pdf_parser:v{version}`

Each image will be tagged with:
- Full semantic version (e.g., `v1.2.3`)
- Major.minor version (e.g., `v1.2`)
- Major version (e.g., `v1`)
- `latest`

## Local Development
Install dependencies for specific services:

```bash
# UI service
uv pip install ".[ui]"

# Webscraper lambda
uv pip install ".[webscraper]"

# PDF parser lambda
uv pip install ".[pdf_parser]"

# All services (development)
uv pip install ".[ui,webscraper,pdf_parser]" --group dev
```
