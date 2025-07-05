output "ec2_instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.streamlit.id
}

output "ec2_public_ip" {
  description = "Public IP address of the EC2 instance (Elastic IP)"
  value       = aws_eip.streamlit_eip.public_ip
}

output "ec2_public_dns" {
  description = "Public DNS name of the EC2 instance"
  value       = aws_eip.streamlit_eip.public_dns
}

output "streamlit_url" {
  description = "URL to access the Streamlit application"
  value       = "http://${aws_eip.streamlit_eip.public_ip}:8501"
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket for PDFs"
  value       = aws_s3_bucket.pdf_storage.bucket
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB table"
  value       = aws_dynamodb_table.case_data.name
}

output "webscraper_lambda_function_name" {
  description = "Name of the webscraper Lambda function"
  value       = aws_lambda_function.webscraper.function_name
}

output "pdf_parser_lambda_function_name" {
  description = "Name of the PDF parser Lambda function"
  value       = aws_lambda_function.pdf_parser.function_name
}

output "lambda_role_arn" {
  description = "ARN of the Lambda execution role"
  value       = aws_iam_role.lambda_role.arn
}

output "ec2_role_arn" {
  description = "ARN of the EC2 instance role"
  value       = aws_iam_role.ec2_role.arn
}

output "ecr_webscraper_repository_url" {
  description = "ECR repository URL for webscraper Lambda"
  value       = aws_ecr_repository.webscraper.repository_url
}

output "ecr_pdf_parser_repository_url" {
  description = "ECR repository URL for PDF parser Lambda"
  value       = aws_ecr_repository.pdf_parser.repository_url
}

output "ecr_login_command" {
  description = "Command to login to ECR"
  value       = "aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${aws_ecr_repository.webscraper.repository_url}"
}
