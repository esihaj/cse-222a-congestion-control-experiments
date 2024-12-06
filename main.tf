#########################
# Variables and Config
#########################

variable "instance_type" {
  type        = string
  default     = "t3.micro"
  description = "AWS EC2 instance type"
}

variable "ami_id" {
  type        = string
  default     = "ami-0cd202468248306f2" # Ubuntu 20.04 ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-20241112
  description = "The AMI ID to use for instances"
}

terraform {
  required_version = ">=1.5.0"
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "local" {
    path = "./state/terraform.tfstate"
  }
}

provider "aws" {
  # region is taken from AWS_DEFAULT_REGION in environment
}

resource "aws_key_pair" "default" {
  key_name   = "experiment_key"
  public_key = file("./keys/id_rsa.pub")
}

resource "aws_security_group" "sg" {
  name        = "benchmark_sg"
  description = "Allow SSH and iperf3"
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 5201
    to_port     = 5201
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "server" {
  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = aws_key_pair.default.key_name
  security_groups = [aws_security_group.sg.id]
  tags = {
    Name = "Experiment-Server"
  }
}

resource "aws_instance" "client" {
  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = aws_key_pair.default.key_name
  security_groups = [aws_security_group.sg.id]
  tags = {
    Name = "Experiment-Client"
  }
}

output "server_public_ip" {
  value = aws_instance.server.public_ip
}

output "client_public_ip" {
  value = aws_instance.client.public_ip
}
