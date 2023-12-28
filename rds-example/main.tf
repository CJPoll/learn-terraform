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

resource "aws_vpc" "very-open-vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
}

resource "aws_internet_gateway" "very-open-gateway" {
  vpc_id = aws_vpc.very-open-vpc.id
}

resource "aws_route" "internet-route" {
  route_table_id = aws_vpc.very-open-vpc.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.very-open-gateway.id
}

data "aws_availability_zones" "available" {
  state = "available"
}

# For each available zone, create a subnet.
resource "aws_subnet" "very-open-subnets" {
  count = length(data.aws_availability_zones.available.names)
  vpc_id = aws_vpc.very-open-vpc.id
  cidr_block = "10.0.${count.index}.0/24"
  map_public_ip_on_launch = true
  availability_zone = element(data.aws_availability_zones.available.names, count.index)
}

resource "aws_db_subnet_group" "postgresql_subnet_group" {
  name = "very-opensubgroup"
  description = "Postgres database open to the world"
  subnet_ids = aws_subnet.very-open-subnets.*.id
}

resource "aws_security_group" "very-open-sg" {
  name = "very-open-sg"
  description = "very-open security group"
  vpc_id = aws_vpc.very-open-vpc.id

  # Allow all inbound traffic
  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic.
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_instance" "postgres" {
  depends_on = [aws_internet_gateway.very-open-gateway]
  vpc_security_group_ids = [aws_security_group.very-open-sg.id]
  db_subnet_group_name = aws_db_subnet_group.postgresql_subnet_group.name
  instance_class = "db.t4g.micro"
  allocated_storage = 10
  db_name = "gen_saas_prod"
  engine = "postgres"
  engine_version = "16"
  username = "application_user"
  password = "temp-password"
  skip_final_snapshot = true
  publicly_accessible = true
  multi_az = false
}
