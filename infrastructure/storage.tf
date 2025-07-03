# S3 Bucket for PDF storage
resource "aws_s3_bucket" "pdf_storage" {
  bucket = "${var.project_name}-pdfs-${var.environment}-${random_string.bucket_suffix.result}"
}

resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "aws_s3_bucket_versioning" "pdf_storage_versioning" {
  bucket = aws_s3_bucket.pdf_storage.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "pdf_storage_encryption" {
  bucket = aws_s3_bucket.pdf_storage.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "pdf_storage_pab" {
  bucket = aws_s3_bucket.pdf_storage.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 bucket notification to trigger PDF parser Lambda
resource "aws_s3_bucket_notification" "pdf_upload_notification" {
  bucket = aws_s3_bucket.pdf_storage.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.pdf_parser.arn
    events              = ["s3:ObjectCreated:*"]
    filter_suffix       = ".pdf"
  }

  depends_on = [aws_lambda_permission.allow_s3_invoke_pdf_parser]
}

# DynamoDB table for parsed case data
resource "aws_dynamodb_table" "case_data" {
  name           = "${var.project_name}-case-data-${var.environment}"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "caseId"

  attribute {
    name = "caseId"
    type = "S"
  }

  attribute {
    name = "query_id"
    type = "S"
  }

  # Global secondary index for querying by query_id
  global_secondary_index {
    name               = "QueryIdIndex"
    hash_key           = "query_id"
    projection_type    = "ALL"
  }

  tags = {
    Name = "${var.project_name}-case-data-${var.environment}"
  }
}
