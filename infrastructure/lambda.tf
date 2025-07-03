# Webscraper Lambda function
resource "aws_lambda_function" "webscraper" {
  function_name = "${var.project_name}-webscraper-${var.environment}"
  role          = aws_iam_role.lambda_role.arn
  
  # Use container image from ECR
  package_type = "Image"
  image_uri    = "${aws_ecr_repository.webscraper.repository_url}:latest"
  
  timeout     = 300  # 5 minutes
  memory_size = 1024
  
  # Specify architecture explicitly for Lambda
  architectures = ["x86_64"]

  environment {
    variables = {
      S3_BUCKET_NAME     = aws_s3_bucket.pdf_storage.bucket
      DYNAMODB_TABLE_NAME = aws_dynamodb_table.case_data.name
      APP_AWS_REGION     = var.aws_region
    }
  }

  depends_on = [
    aws_iam_role_policy.lambda_policy,
    aws_ecr_repository.webscraper
  ]

  tags = {
    Name = "${var.project_name}-webscraper-${var.environment}"
  }
}

# PDF Parser Lambda function
resource "aws_lambda_function" "pdf_parser" {
  function_name = "${var.project_name}-pdf_parser-${var.environment}"
  role          = aws_iam_role.lambda_role.arn
  
  # Use container image from ECR
  package_type = "Image"
  image_uri    = "${aws_ecr_repository.pdf_parser.repository_url}:latest"
  
  timeout     = 300  # 5 minutes
  memory_size = 512
  
  # Specify architecture explicitly for Lambda
  architectures = ["x86_64"]

  environment {
    variables = {
      S3_BUCKET_NAME     = aws_s3_bucket.pdf_storage.bucket
      DYNAMODB_TABLE_NAME = aws_dynamodb_table.case_data.name
      APP_AWS_REGION     = var.aws_region
    }
  }

  depends_on = [
    aws_iam_role_policy.lambda_policy,
    aws_ecr_repository.pdf_parser
  ]

  tags = {
    Name = "${var.project_name}-pdf_parser-${var.environment}"
  }
}

# Permission for S3 to invoke PDF parser Lambda
resource "aws_lambda_permission" "allow_s3_invoke_pdf_parser" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.pdf_parser.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.pdf_storage.arn
}
