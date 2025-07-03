# ECR repositories for Lambda container images
resource "aws_ecr_repository" "webscraper" {
  name = "${var.project_name}-webscraper"
  
  image_tag_mutability = "MUTABLE"
  
  image_scanning_configuration {
    scan_on_push = false  # Disable to save costs
  }

  tags = {
    Name = "${var.project_name}-webscraper-${var.environment}"
  }
}

resource "aws_ecr_repository" "pdf_parser" {
  name = "${var.project_name}-pdf_parser"
  
  image_tag_mutability = "MUTABLE"
  
  image_scanning_configuration {
    scan_on_push = false  # Disable to save costs
  }

  tags = {
    Name = "${var.project_name}-pdf_parser-${var.environment}"
  }
}

# ECR lifecycle policies to manage image retention (cost optimization)
resource "aws_ecr_lifecycle_policy" "webscraper_policy" {
  repository = aws_ecr_repository.webscraper.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 5 images"
        selection = {
          tagStatus     = "untagged"
          countType     = "imageCountMoreThan"
          countNumber   = 5
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Keep tagged images for 30 days"
        selection = {
          tagStatus       = "tagged"
          tagPrefixList   = ["latest", "dev"]
          countType       = "sinceImagePushed"
          countUnit       = "days"
          countNumber     = 30
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

resource "aws_ecr_lifecycle_policy" "pdf_parser_policy" {
  repository = aws_ecr_repository.pdf_parser.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 5 images"
        selection = {
          tagStatus     = "untagged"
          countType     = "imageCountMoreThan"
          countNumber   = 5
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Keep tagged images for 30 days"
        selection = {
          tagStatus       = "tagged"
          tagPrefixList   = ["latest", "dev"]
          countType       = "sinceImagePushed"
          countUnit       = "days"
          countNumber     = 30
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
