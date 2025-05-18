#!/bin/bash

# --- CONFIGURE THESE VARIABLES ---
AWS_REGION="us-east-1"
REPO_NAME="flask-crud-app"
IMAGE_TAG="latest"
TERRAFORM_DIR="./terraform"  # Adjust path if needed
# ---------------------------------

set -e

cd ./Application
# Check if AWS CLI is installed
if ! command -v aws &> /dev/null
then
    echo "AWS CLI could not be found. Please install it."
    exit 1
fi

# Check if Docker is installed
if ! command -v docker &> /dev/null
then
    echo "Docker could not be found. Please install it."
    exit 1
fi

# Check if Terraform is installed
if ! command -v terraform &> /dev/null
then
    echo "Terraform could not be found. Please install it."
    exit 1
fi

# Check if AWS credentials are configured
if ! aws sts get-caller-identity &> /dev/null
then
    echo "AWS credentials are not configured. Please configure them using 'aws configure'."
    exit 1
fi

echo "🔐 Getting AWS account ID..."
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_URI="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$REPO_NAME:$IMAGE_TAG"

# 1. Create or confirm ECR repository
echo "📦 Checking/creating ECR repository..."
aws ecr describe-repositories --repository-names $REPO_NAME --region $AWS_REGION >/dev/null 2>&1 || \
  aws ecr create-repository --repository-name $REPO_NAME --region $AWS_REGION

# 2. Build Docker image
echo "🐳 Building Docker image..."
docker build -t $REPO_NAME:$IMAGE_TAG .

# 3. Tag and push to ECR
echo "🏷️ Tagging image as $ECR_URI"
docker tag $REPO_NAME:$IMAGE_TAG $ECR_URI

echo "🔐 Logging into ECR..."
aws ecr get-login-password --region $AWS_REGION | \
  docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

echo "🚀 Pushing image to ECR..."
docker push $ECR_URI

# 4. Deploy infrastructure
echo "🛠️ Deploying infrastructure with Terraform..."
cd $TERRAFORM_DIR
terraform init
terraform apply -auto-approve \
  -var "aws_region=$AWS_REGION" \
  -var "image_uri=$ECR_URI" 

# 5. Output connection info
echo "🌐 Fetching output from Terraform..."
ALB_DNS=$(terraform output -raw alb_dns_name)
RDS_ENDPOINT=$(terraform output -raw rds_endpoint)
BASTION_IP=$(terraform output -raw bastion_public_ip)

echo "✅ Deployment complete!"
echo "----------------------------------------"
echo "🌍 Web App URL: http://$ALB_DNS"
echo "----------------------------------------"
echo "🛡️  Bastion Host Public IP: $BASTION_IP"
echo "----------------------------------------"
echo "🔑 To SSH: ssh -i terraform\my-bastion-key ec2-user@$BASTION_IP"
