## AWS Networking Infrastructure Setup using Terraform
# Introduction
* This repository (tf-aws-infra) contains Terraform configuration files to create a complete networking setup on AWS. The infrastructure includes:
  - A Virtual Private Cloud (VPC)
  - Public and private subnets across 3 availability zones
  - An Internet Gateway
  - Route tables for public and private subnets
  - An Application Security Group for web applications
  - An EC2 instance using a custom AMI
  - An RDS instance for hosting postgresql databases
  - A Load Balancer
  - An Auto scaling group
  - DNS Management
  - Storage Group
  - AWS Lambda (Event Driven Architecture)
  - SNS (Simple Notification Service)
  - KMS Key Management Service
  - ACM (Amazon Certificate Manager)

- This Terraform setup allows creating multiple VPCs with their own subnets, gateways, and routing tables without hardcoded values. This is achieved by utilizing variables for customization.
- Application Security Group Configuration
  - To allow traffic to the EC2 instance running your web application, the following resources are defined in the Terraform configuration:

  - Application Security Group: This security group allows incoming TCP traffic on ports 22 (SSH), 80 (HTTP), 443 (HTTPS), and a specified port for your application.
- **EC2 Instance**: The EC2 instance will be launched using the specified custom AMI and will be associated with the application security group.

- **Database Security Group**: Restricts database access; allows only internal traffic.  
- **RDS Instance**: Sets up a private database with secure credentials.  
- **EC2 Security Group**: Controls app instance access via SSH and Load Balancer.  
- **S3 Bucket**: Stores data securely with encryption and lifecycle policies.  
- **Application Load Balancer**: Distributes app traffic; forwards HTTP to EC2.  
- **Auto Scaling Group**: Manages EC2 instances based on CPU utilization.  
- **DNS Configuration**: Routes traffic using Route 53 for domain and subdomains.  
- **SNS & Lambda**: Configures notifications and database interaction via AWS Lambda. 

- **AWS Key Management Service (KMS)**:

  Separate KMS keys for:
   - EC2
   - RDS
   - S3 Buckets
   - Secret Manager (Database Password and Email Service C   redentials)
   - KMS key rotation period: 90 days
   - KMS keys are referenced in Terraform configurations.

- **Secrets Management**:

  -- Database Password: Auto-generated using Terraform and stored in AWS Secret     Manager with a custom KMS key.

  -- Retrieved via user-data script to configure the web application.

  -- Email Service Credentials:
  Stored securely in AWS Secret Manager with a custom KMS key.

- Automatically retrieved by the Lambda function during execution.

**SSL Certificates**:

Development Environment: 
- Uses AWS Certificate Manager for SSL certificates.
Demo Environment: 
- Requires an SSL certificate imported from a third-party vendor (e.g., Namecheap).
Import command:
```
aws acm import-certificate --certificate file://certificate.pem --private-key file://private-key.pem --certificate-chain file://certificate-chain.pem --region <region>
```

- Load balancer is configured to use the imported SSL certificate.
Notes:
- Only HTTPS traffic is supported for the application.
- HTTP-to-HTTPS redirection is not required.
- Traffic between the load balancer and EC2 instance uses plain HTTP.
- Direct connections to the EC2 instance are blocked.

**Prerequisites**
AWS CLI
Install and configure the AWS CLI with access to the required AWS resources.




# Prerequisites
Before you begin, ensure that the following are installed and set up on your local machine:

- Terraform (v1.9.7 or later)
- AWS CLI (configured with proper credentials and region)
- AWS account with permissions to create networking resources

# Instructions for Setting Up Infrastructure
- Step 1: Clone the Repository
```
git@github.com:CSYE-6225-Fall-2024-Nikitha/tf-aws-infra.git
cd tf-aws-infra
```
- Step 2: Initialize Terraform
This command initializes the working directory and downloads the necessary provider plugins.
```
terraform init
``` 
- Step 3: Format the Code
To ensure proper formatting of all Terraform files:
```
terraform fmt -recursive
```

- Step 4: Validate the Configuration
Run the validation command to ensure the Terraform configuration files are correct:
```
terraform validate
``` 

- Step 5: Create a Plan
Generate an execution plan to preview the actions Terraform will take:
```
terraform plan -var-file="dev.tfvars"
```
The dev.tfvars file contains environment-specific values such as VPC CIDR block, subnet CIDR ranges, and more.

- Step 6: Apply the Plan
Run the following command to create the infrastructure on AWS:

```
terraform apply -var-file="dev.tfvars"
```

- Step 7: Destroy the Infrastructure (if needed)
To tear down and remove all resources created by Terraform:

```
terraform destroy -var-file="dev.tfvars"
```

# Variables
- vpc_cidr: CIDR block for the VPC.
- public_subnet_cidrs: List of CIDR blocks for the public subnets.
- private_subnet_cidrs: List of CIDR blocks for the private subnets.
- region: AWS region where the infrastructure will be deployed.
- availability_zones: List of availability zones to use in the region.
- app_security_group_id: ID of the application security group.
- ami_id: Custom AMI ID for the EC2 instance.
- key_pair: Name of the key pair for SSH access.


# Using Multiple Environments
- You can create multiple environments (e.g., dev, prod) by maintaining separate .tfvars files with different variable values (like dev.tfvars and prod.tfvars).

- To apply the configuration for the production environment:

```
terraform plan -var-file="prod.tfvars"
terraform apply -var-file="prod.tfvars"
```