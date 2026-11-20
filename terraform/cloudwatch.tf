resource "aws_cloudwatch_log_group" "careerflow" {
  name              = "/ecs/${local.project_name}/careerflow-api"
  retention_in_days = 14
  tags              = local.common_tags
}
