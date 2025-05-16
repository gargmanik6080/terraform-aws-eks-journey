# Configuration for the minimum required Terraform version and AWS provider
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"    # Official AWS provider
      version = "~> 4.16"          # Using version 4.16.x
    }
  }

  required_version = ">= 1.2.0"    # Minimum Terraform version required
}

# Configure the AWS Provider for US West (Oregon) region
provider "aws" {
  region = "us-west-2"
}

# Create an EC2 instance
resource "aws_instance" "app_server" {
  ami           = "ami-04999cd8f2624f834"  # Public Amazon Linux 2023 AMI ID (AMI IDs are region specific)
  instance_type = "t2.micro"               # Free tier eligible instance type
  subnet_id     = "subnet-029c12d43eea92a83"  # Existing subnet ID

  tags = {
    Name = "My First Provisioned EC2 Instance"  # Name tag for the instance
  }
}