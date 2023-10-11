terraform {
  backend "s3" {
    bucket = "mybucket"
    key    = "path/to/my/key/state.tfstate"
    region = "eu-central-1"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = var.region
}

resource "aws_vpc" "myapp_vpc" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name = "${var.env_prefix}-vpc"
  }
}

resource "aws_subnet" "myapp_subnet_1" {
  vpc_id            = aws_vpc.myapp_vpc.id
  cidr_block        = var.subnet_cidr_block
  availability_zone = var.avail_zone

  tags = {
    Name = "${var.env_prefix}-subnet-1"
  }
}

resource "aws_internet_gateway" "myapp_igw" {
  vpc_id = aws_vpc.myapp_vpc.id

  tags = {
    Name = "${var.env_prefix}-igw"
  }
}

resource "aws_route_table" "myapp_rtb" {
  vpc_id = aws_vpc.myapp_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myapp_igw.id
  }

  tags = {
    Name = "${var.env_prefix}-rtb"
  }
}

resource "aws_route_table_association" "rtb_subnet_association" {
  route_table_id = aws_route_table.myapp_rtb.id
  subnet_id      = aws_subnet.myapp_subnet_1.id
}

# this will be jenkins ip when running from pipeline
data "http" "myip" {
  url = "http://ipv4.icanhazip.com"
}

resource "aws_security_group" "myapp_sg" {
  name   = "myapp_sg"
  vpc_id = aws_vpc.myapp_vpc.id

  ingress {
    description = "ssh on port 22"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.myip.body)}/32", "188.24.28.5/32"]
  }

  # javaapp container will listen on port 8080
  ingress {
    description = "http on port 8080"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.env_prefix}-sg"
  }
}

data "aws_ami" "amzn_linux_2023_ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023*-x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "myapp_server" {
  ami                    = data.aws_ami.amzn_linux_2023_ami.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.myapp_subnet_1.id
  vpc_security_group_ids = [aws_security_group.myapp_sg.id]
  availability_zone = var.avail_zone

  associate_public_ip_address = true
  key_name = "jenkins-aws-key"

  user_data = <<-EOF
                #!/bin/bash
                sudo yum update -y && sudo yum install -y docker
                sudo systemctl start docker
                sudo usermod -aG docker ec2-user
                sudo curl -L https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
                sudo chmod +x /usr/local/bin/docker-compose
                EOF

user_data_replace_on_change = true

  tags = {
    Name = "${var.env_prefix}-server"
  }
}

output "ec2_public_ip" {
    value = aws_instance.myapp_server.public_ip
}