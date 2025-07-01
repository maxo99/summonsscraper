
# Development
`uv sync --extra lambda --extra selenium`

# Build 
`docker build -f src/lambda_service/Dockerfile -t summonsscraper-lambda .`
`docker tag summonsscraper-lambda {AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/docker-images:v0.0.0`
`aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin {AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/summonsscraper`
`docker push {AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/summonsscraper:v0.0.0`