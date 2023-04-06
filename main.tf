terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"

}
variable "vpc_cidr_block" {

}
variable "subnet_cidr_block" {

}
variable "env_prefix" {

}
variable "avail_zone" {

}
variable "ami_type" {

}
variable "public_key_location" {

}
resource "aws_vpc" "myapp-vpc" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name = "${var.env_prefix}-vpc"
  }

}

resource "aws_subnet" "myapp-subnet-1" {
  vpc_id            = aws_vpc.myapp-vpc.id
  cidr_block        = var.subnet_cidr_block
  availability_zone = var.avail_zone
  tags = {
    "Name" = "${var.env_prefix}-subnet-1"
  }
}

/*resource "aws_route_table" "myapp_route_table" {
  vpc_id = aws_vpc.myapp-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myapp_igw.id
  }
  tags = {
    Name = "${var.env_prefix}-rtb"
  }
}*/
resource "aws_internet_gateway" "myapp_igw" {
  vpc_id = aws_vpc.myapp-vpc.id
  tags = {
    Name = "${var.env_prefix}-igw"
  }
}

/*resource "aws_route_table_association" "a-rtb-subnet" {
  subnet_id = aws_subnet.myapp-subnet-1.id
  route_table_id = aws_route_table.myapp_route_table.id
  
}*/

resource "aws_default_route_table" "default-rtb" {
  default_route_table_id = aws_vpc.myapp-vpc.default_route_table_id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myapp_igw.id
  }
  tags = {
    Name = "${var.env_prefix}-rtb"
  }

}

resource "aws_security_group" "myapp-sg" {
  name   = "myapp-sg"
  vpc_id = aws_vpc.myapp-vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
    prefix_list_ids = []
  }
  tags = {
    Name = "${var.env_prefix}-myapp-sg"
  }

}


data "aws_ami" "latest_amzon_linux_ami" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

output "aws_ami_id" {
  value = data.aws_ami.latest_amzon_linux_ami.id
}

resource "aws_instance" "myapp-server" {
  ami                         = data.aws_ami.latest_amzon_linux_ami.id
  instance_type               = var.ami_type
  subnet_id                   = aws_subnet.myapp-subnet-1.id
  vpc_security_group_ids      = [aws_security_group.myapp-sg.id]
  availability_zone           = var.avail_zone
  associate_public_ip_address = true
  key_name                    = aws_key_pair.ssh-key.key_name
  user_data = <<EOF
    #!/bin/bash
    sudo yum update -y && sudo yum install -y docker
    sudo systemctl start docker
    sudo usermod -aG docker ec2-user
    docker run -p 8080-80 nginx
    EOF

  tags = {
    Name = "${var.env_prefix}-server"
  }
}

resource "aws_key_pair" "ssh-key" {
  key_name   = "server-key"
  public_key = file(var.public_key_location)
}
output "aws_publib_ip" {
  value = aws_instance.myapp-server.public_ip
}

