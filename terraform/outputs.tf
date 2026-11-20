output "ecr_repository_url" {
  description = "ECR repository URL for the CareerFlow API"
  value       = aws_ecr_repository.careerflow_api.repository_url
}
output "ecs_cluster_name" {
  description = "ECS cluster hosting CareerFlow"
  value       = aws_ecs_cluster.main.name
}

output "ecs_service_name" {
  description = "CareerFlow ECS service name"
  value       = aws_ecs_service.careerflow.name
}

output "cloudwatch_log_group_name" {
  description = "CloudWatch Logs group for the CareerFlow API"
  value       = aws_cloudwatch_log_group.careerflow.name
}
