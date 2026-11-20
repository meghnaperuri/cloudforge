# CloudForge

CloudForge defines AWS infrastructure for the [CareerFlow FastAPI backend](https://github.com/meghnaperuri/careerflow). Terraform lives in `terraform/`.

- **ECR and ECS Fargate.** ECR scans images on push and uses immutable tags. ECS runs a Linux x86-64 task with 0.25 vCPU and 512 MiB, checks `/health` on port 8000, and uses the ECS deployment circuit breaker with rollback.
- **Networking.** The VPC has two public subnets with an internet gateway. Fargate assigns each task a public IPv4 address for outbound access. Inbound access is closed by default. A trusted IPv4 CIDR can be set for direct HTTP testing. Task IPs may change when tasks are replaced.
- **IAM and logs.** The ECS execution role pulls images from the project ECR repository, sends container logs to `/ecs/cloudforge/careerflow-api`, and can read only the specified database secret. The application receives no separate AWS task role. CloudWatch Logs retains stdout and stderr for 14 days.

## Validate locally

Run from the repository root with Terraform 1.10 or newer. Initialization downloads the locked AWS provider. These checks need no AWS credentials and make no changes to AWS resources.

```sh
terraform -chdir=terraform fmt -check -recursive
terraform -chdir=terraform init -backend=false -lockfile=readonly
terraform -chdir=terraform validate
```

Terraform CI runs formatting and validation on pull requests and pushes to `main`. Docker CI builds the CareerFlow image with publishing disabled.

## Runtime inputs

| Input | Default | Purpose |
| --- | --- | --- |
| `aws_region` | `us-east-1` | Region for the VPC, ECS, ECR and logs. The configuration uses the region's `a` and `b` Availability Zones. |
| `image_tag` | `careerflow-v1` | Immutable tag for a Linux x86-64 CareerFlow image in the ECR repository. |
| `desired_count` | `0` | Number of running tasks. |
| `database_secret_arn` | Unset | Full ARN of an existing same-account, same-region Secrets Manager secret. Required when the task count is positive. |
| `api_ingress_cidr` | Unset | Trusted IPv4 network allowed to reach task port 8000 over HTTP. Leave unset for closed ingress. |

CareerFlow opens a PostgreSQL connection during startup. Before starting tasks, an operator needs an image in ECR and a reachable PostgreSQL instance with credentials that can create the application tables. The existing secret must use the AWS-managed Secrets Manager key and contain the full SQLAlchemy connection string as its raw string value. Terraform accepts only the ARN and never reads the secret value. Keep credentials out of Git and Terraform inputs. Restart the tasks after rotating the secret so they pick up its new value.

The network is intended for development. Direct HTTP has no TLS, and CareerFlow's application endpoints should be kept off the public internet. Use a trusted source address and test data if you enable direct access.

Running tasks, public IPv4 addresses, ECR storage, CloudWatch log ingestion and storage, and separately managed database and secret resources can incur AWS charges. A desired count of zero prevents Fargate tasks from starting. Review costs and obtain approval before provisioning resources or increasing the task count.
