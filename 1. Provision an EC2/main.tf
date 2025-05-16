terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "us-west-2"
}

resource "aws_instance" "app_server" {
  ami           = "ami-04999cd8f2624f834"
  instance_type = "t2.micro"
  subnet_id     = "subnet-029c12d43eea92a83"

  tags = {
    Name = "My First Provisioned EC2 Instance"
  }

}