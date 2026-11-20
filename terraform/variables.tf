variable "aws_region" {
  description = "AWS region for CloudForge infrastructure"
  type        = string
  default     = "us-east-1"
}
variable "image_tag" {
  description = "Immutable CareerFlow image tag already pushed to the CloudForge ECR repository before starting tasks"
  type        = string
  default     = "careerflow-v1"
  nullable    = false

  validation {
    condition     = can(regex("^[A-Za-z0-9_][A-Za-z0-9_.-]{0,127}$", var.image_tag)) && lower(var.image_tag) != "latest"
    error_message = "Use a valid version-specific Docker image tag other than latest."
  }
}

variable "desired_count" {
  description = "Number of CareerFlow Fargate tasks to run"
  type        = number
  default     = 0
  nullable    = false

  validation {
    condition     = var.desired_count >= 0 && var.desired_count == floor(var.desired_count)
    error_message = "The desired task count must be a nonnegative integer."
  }
}

variable "database_secret_arn" {
  description = "Full ARN of an existing Secrets Manager secret containing the DATABASE_URL as a raw string"
  type        = string
  default     = null

  validation {
    condition     = var.database_secret_arn == null || can(regex("^arn:[^:]+:secretsmanager:[^:]+:[0-9]{12}:secret:[A-Za-z0-9/_+=.@-]+-[A-Za-z0-9]{6}$", var.database_secret_arn))
    error_message = "Provide a full Secrets Manager secret ARN, including its six-character suffix."
  }
}

variable "api_ingress_cidr" {
  description = "Optional trusted IPv4 CIDR that may access the API directly on TCP port 8000"
  type        = string
  default     = null

  validation {
    condition     = var.api_ingress_cidr == null || try(can(cidrnetmask(var.api_ingress_cidr)) && tonumber(split("/", var.api_ingress_cidr)[1]) > 0, false)
    error_message = "Use a trusted IPv4 CIDR with a prefix longer than /0."
  }
}
