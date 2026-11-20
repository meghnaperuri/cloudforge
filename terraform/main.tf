locals {
  project_name = "cloudforge"
  api_port     = 8000

  common_tags = {
    Project     = local.project_name
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}

resource "aws_ecr_repository" "careerflow_api" {
  name                 = "${local.project_name}/careerflow-api"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = local.common_tags
}