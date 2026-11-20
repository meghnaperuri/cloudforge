output "ecr_repository_url" {
  description = "ECR repository URL for the CareerFlow API"
  value       = aws_ecr_repository.careerflow_api.repository_url
}