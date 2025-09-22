terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.92"
    }
  }

  required_version = ">= 1.2"
}

provider "aws" {
  region = "eu-west-3"
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  owners = ["099720109477"] # Canonical
}

data "aws_vpc" "default" {
  default = true
}

resource "aws_security_group" "app_server_sg" {
  name        = "app-server-sg"
  description = "Allow inbound traffic on ports 5000 and 5432, allow all outbound"
  vpc_id = data.aws_vpc.default.id
  
  ingress {
    description = "Allow SSH (port 22) from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow API Python port 5000"
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow Postgres port 5432"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "app-server-sg"
  }
}

resource "aws_instance" "app_server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  key_name = "ci-cd-deploy"
  vpc_security_group_ids = [aws_security_group.app_server_sg.id]
  user_data = <<-EOF
                #!/bin/bash
                sudo apt update
                sudo apt install -y docker.io

                # Télécharger docker-compose.yml depuis GitHub
                curl -L -o /home/ubuntu/docker-compose.yml https://raw.githubusercontent.com/Loise/containerized-devops-workflow/refs/heads/main/docker-compose-aws.yml

                # install docker compose
                DOCKER_CONFIG=/home/ubuntu/.docker
                mkdir -p $DOCKER_CONFIG/cli-plugins
                curl -SL https://github.com/docker/compose/releases/download/v2.39.3/docker-compose-linux-x86_64 -o $DOCKER_CONFIG/cli-plugins/docker-compose
                
                # access to docker compose from current user
                chmod +x $DOCKER_CONFIG/cli-plugins/docker-compose
                sudo usermod -aG docker ubuntu
                newgrp docker

                # Démarrer le compose
                sudo -u ubuntu docker compose -f /home/ubuntu/docker-compose.yml up -d >> error.log
              EOF
  tags = {
    Name = "learn-terraform"
  }
}

# Provisionning
# export AWS_ACCESS_KEY_ID=
# export AWS_SECRET_ACCESS_KEY=
# terraform init
# terraform plan
# terraform apply