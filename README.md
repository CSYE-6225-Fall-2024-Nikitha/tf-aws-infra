## AWS Networking Infrastructure Setup using Terraform
# Introduction
* This repository (tf-aws-infra) contains Terraform configuration files to create a complete networking setup on AWS. The infrastructure includes:
  - A Virtual Private Cloud (VPC)
  - Public and private subnets across 3 availability zones
  - An Internet Gateway
  - Route tables for public and private subnets
  - An Application Security Group for web applications
  - An EC2 instance using a custom AMI

- This Terraform setup allows creating multiple VPCs with their own subnets, gateways, and routing tables without hardcoded values. This is achieved by utilizing variables for customization.
- Application Security Group Configuration
  - To allow traffic to the EC2 instance running your web application, the following resources are defined in the Terraform configuration:

  - Application Security Group: This security group allows incoming TCP traffic on ports 22 (SSH), 80 (HTTP), 443 (HTTPS), and a specified port for your application.
- **EC2 Instance**: The EC2 instance will be launched using the specified custom AMI and will be associated with the application security group.

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