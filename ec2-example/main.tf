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
  region  = "us-west-2"
}

resource "aws_instance" "app_server" {
  # Some ubuntu image
  ami           = "ami-058168290d30b9c52"
  instance_type = "t2.micro"

  # My aws key-pair
  key_name = "1pass-key-pair-us-west-2"

  security_groups = [
    "launch-wizard-1"
  ]

  tags = {
    Name = "TestTerraformInstance"
  }
}
