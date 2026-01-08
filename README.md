# AWS ECS Node.js Application

A complete AWS infrastructure setup for deploying Node.js applications using ECR and ECS with GitHub Actions CI/CD.

## Project Structure

```
aws-project/
├── src/                          # Node.js application
│   ├── index.js
│   ├── index.test.js
│   └── package.json
├── terraform/                    # Infrastructure as Code
│   ├── provider.tf
│   ├── variables.tf
│   ├── vpc.tf
│   ├── security_groups.tf
│   ├── ecr.tf
│   ├── alb.tf
│   ├── ecs.tf
│   └── outputs.tf
├── .github/workflows/
│   └── deploy.yml                # CI/CD pipeline
├── Dockerfile
└── README.md
```

## Prerequisites

- AWS Account with appropriate permissions
- Terraform >= 1.0
- AWS CLI configured
- GitHub repository

## Setup Instructions

### Step 1: Create S3 Backend for Terraform State

```bash
# Create S3 bucket for Terraform state
aws s3 mb s3://your-terraform-state-bucket --region us-east-1

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket your-terraform-state-bucket \
  --versioning-configuration Status=Enabled

# Create DynamoDB table for state locking
aws dynamodb create-table \
  --table-name terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1
```

Update `terraform/provider.tf` with your bucket name.

### Step 2: Deploy AWS Infrastructure

```bash
cd terraform

# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply the infrastructure
terraform apply
```

### Step 3: Add GitHub Secrets

1. Go to your GitHub repository
2. Navigate to **Settings → Secrets and variables → Actions**
3. Click **New repository secret**
4. Add the following secrets:

| Secret Name | Value |
|-------------|-------|
| `AWS_ACCESS_KEY_ID` | Your AWS access key |
| `AWS_SECRET_ACCESS_KEY` | Your AWS secret key |

### Step 4: Push Initial Image

Before the ECS service can start, push an initial image:

```bash
# Get ECR login
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-east-1.amazonaws.com

# Build and push
docker build -t nodejs-ecs-app .
docker tag nodejs-ecs-app:latest <account-id>.dkr.ecr.us-east-1.amazonaws.com/nodejs-ecs-app:latest
docker push <account-id>.dkr.ecr.us-east-1.amazonaws.com/nodejs-ecs-app:latest
```

### Step 5: Access the Application

```bash
cd terraform
terraform output application_url
```

## CI/CD Pipeline

Every push to `main` triggers:

```
┌──────────┐     ┌─────────────────┐
│   Test   │     │ Terraform Apply │   ← Parallel
└────┬─────┘     └────────┬────────┘
     │                    │
     └─────────┬──────────┘
               ▼
     ┌───────────────────┐
     │  Build/Scan/Push  │
     └─────────┬─────────┘
               ▼
     ┌───────────────────┐
     │  Deploy to ECS    │
     └───────────────────┘
```

**Pipeline Steps:**
1. **Test** - Run Jest tests with coverage, ESLint
2. **Terraform** - Apply infrastructure changes
3. **Build** - Build Docker image
4. **Scan** - Trivy vulnerability scan (filesystem + Docker image)
5. **Push** - Push to Amazon ECR
6. **Deploy** - Update ECS service

## GitHub Secrets Required

| Secret | Description |
|--------|-------------|
| `AWS_ACCESS_KEY_ID` | AWS access key |
| `AWS_SECRET_ACCESS_KEY` | AWS secret key |

## Configuration

### Terraform Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `aws_region` | us-east-1 | AWS region |
| `project_name` | nodejs-ecs-app | Project name |
| `container_port` | 3000 | Container port |
| `cpu` | 256 | Fargate CPU units |
| `memory` | 512 | Fargate memory (MB) |
| `desired_count` | 2 | Number of tasks |

## Infrastructure Components

- **VPC** - Custom VPC with public/private subnets across 2 AZs
- **ECR** - Private container registry with image scanning
- **ECS Fargate** - Serverless container orchestration
- **ALB** - Application Load Balancer with health checks
- **NAT Gateway** - Outbound internet for private subnets
- **CloudWatch** - Centralized logging

## Cleanup

```bash
cd terraform
terraform destroy
```
