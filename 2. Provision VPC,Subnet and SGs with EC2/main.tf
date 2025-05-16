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

# Create a VPC for our infrastructure
resource "aws_vpc" "main" {
    cidr_block = "10.0.0.0/16"    # CIDR block for the VPC (65,536 IP addresses)
    tags = {
      Name = "Main VPC"
    }
}

# Create a public subnet within the VPC
resource "aws_subnet" "main" {
  vpc_id                  = aws_vpc.main.id    # Reference to the VPC created above
  cidr_block              = "10.0.0.0/24"      # CIDR block for the subnet (256 IP addresses)
  availability_zone       = "us-west-2a"       # AZ in US West (Oregon)
  map_public_ip_on_launch = true              # Auto-assign public IPs to instances in this subnet
}

# Create a security group for the EC2 instance
resource "aws_security_group" "main" {
    name   = "main_sg"
    vpc_id = aws_vpc.main.id     # Reference to the VPC created above
}

# Create an EC2 instance in the new VPC and subnet
resource "aws_instance" "app_server" {
  ami           = "ami-04999cd8f2624f834"  # Official Amazon Linux 2023 AMI ID
  instance_type = "t2.micro"               # Free tier eligible instance type
  subnet_id     = aws_subnet.main.id       # Place the instance in our custom subnet

  tags = {
    Name = "My First Provisioned EC2 Instance"
  }
}
