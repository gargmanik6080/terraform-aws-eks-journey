# Terraform Journey for Beginners

My evolving Terraform practice repository — from basics to real-world infrastructure. Open for all to learn and contribute.

## Project Structure

1. **Basic EC2 Provisioning** (`1. Provision an EC2/`)
   - Simple EC2 instance creation in an existing subnet
   - Basic AWS provider configuration

2. **VPC with EC2** (`2. Provision VPC,Subnet and SGs with EC2/`)
   - Complete VPC setup with custom subnet
   - Security Group configuration
   - EC2 instance in the custom VPC

## Prerequisites

1. Install [Terraform](https://developer.hashicorp.com/terraform/downloads)
2. Configure [AWS CLI](https://aws.amazon.com/cli/) with your credentials
3. Basic understanding of AWS services (VPC, EC2, Security Groups)

## Usage Instructions

### Initialize Terraform (for each project directory)
```bash
cd "directory_name"
terraform init
```

### Plan Your Infrastructure
```bash
terraform plan
```

### Apply Changes
```bash
terraform apply
```
When prompted, type `yes` to confirm the changes.

### Destroy Infrastructure
```bash
terraform destroy
```
When prompted, type `yes` to confirm the destruction of resources.

## Important Notes

- Always review the plan before applying changes
- Remember to destroy resources when done to avoid unnecessary charges
- The configurations use `us-west-2` (Oregon) region by default
- All instances are `t2.micro` (Free tier eligible)

## Security Considerations

- The security group in the VPC example needs to be configured with proper ingress/egress rules
- Always follow the principle of least privilege when configuring security groups
- Keep your AWS credentials secure and never commit them to the repository

## Contributing

Feel free to contribute by:
1. Forking the repository
2. Creating your feature branch
3. Committing your changes
4. Opening a pull request
