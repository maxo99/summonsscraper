# Setup Instructions for OpenTofu Infrastructure

## Prerequisites

1. **Install OpenTofu**
   ```bash
   # On macOS with Homebrew
   brew install opentofu
   
   # On Windows with Chocolatey
   choco install opentofu
   
   # Or download from https://opentofu.org/docs/intro/install/
   ```

2. **AWS CLI configured** with appropriate permissions

3. **GitHub repository secrets configured**

## Local Setup

1. **Create your terraform.tfvars file:**
   ```bash
   cd infrastructure
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your values
   ```

2. **Create an AWS key pair** (if you don't have one):
   ```bash
   aws ec2 create-key-pair --key-name summonsscraper-key --query 'KeyMaterial' --output text > ~/.ssh/summonsscraper-key.pem
   chmod 400 ~/.ssh/summonsscraper-key.pem
   ```

3. **Initialize and apply OpenTofu:**
   ```bash
   tofu init
   tofu plan
   tofu apply
   ```

## GitHub Secrets Setup

Configure these secrets in your GitHub repository:

### AWS IAM Setup for GitHub Actions

1. **Create OIDC Identity Provider** (one-time setup):
   ```bash
   aws iam create-open-id-connect-provider \
     --url https://token.actions.githubusercontent.com \
     --client-id-list sts.amazonaws.com \
     --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
   ```

2. **Get the role ARN** from OpenTofu outputs:
   ```bash
   tofu output github_actions_role_arn
   ```

3. **Add to GitHub Secrets:**
   - `AWS_ROLE_ARN`: The ARN from step 2

## Architecture Components

- **EC2 Instance**: t3.small with Streamlit
- **Lambda Functions**: Containerized webscraper and PDF parser
- **S3 Bucket**: PDF storage with lifecycle policies
- **DynamoDB**: Case data storage with GSI
- **IAM Roles**: Least-privilege access for all components
- **Security Groups**: Restricted network access

## OpenTofu Tips

1. **State Management**: Consider using remote state storage:
   ```hcl
   terraform {
     backend "s3" {
       bucket = "your-terraform-state-bucket"
       key    = "summonsscraper/terraform.tfstate"
       region = "us-east-1"
     }
   }
   ```

2. **Environment Management**: Use workspaces:
   ```bash
   tofu workspace new dev
   tofu workspace new staging
   tofu workspace new prod
   ```

3. **Planning**: Always review plans before applying:
   ```bash
   tofu plan -out=tfplan
   tofu apply tfplan
   ```

4. **Debugging**: Enable detailed logging:
   ```bash
   export TF_LOG=DEBUG
   tofu plan
   ```

## Cost Optimization

- EC2 t3.small: ~$15/month
- Lambda: Pay per execution (minimal for low usage)
- DynamoDB: Pay per request (minimal for low usage)
- S3: Pay per storage (~$0.023/GB/month)

Total estimated cost: ~$20-30/month for moderate usage.

## Security Best Practices

1. **Restrict CIDR blocks** in `allowed_cidr_blocks` variable
2. **Use least-privilege IAM policies**
3. **Enable S3 encryption** (already configured)
4. **Regular security updates** on EC2 instance
5. **Monitor CloudTrail logs** for audit trail
