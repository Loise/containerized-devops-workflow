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
    cidr_blocks = ["85.169.87.98/32"]  # Remplacez par votre IP publique
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
  key_name = "macbook-air"
  vpc_security_group_ids = [aws_security_group.app_server_sg.id]
  user_data = <<-EOF
                #!/bin/bash
                sudo apt-get update -y
                sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common

                # Ajout du dépôt Docker
                curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
                sudo add-apt-repository \
                "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

                sudo apt-get update -y
                sudo apt-get install -y docker-ce docker-ce-cli containerd.io

                # Ajoute l'utilisateur ubuntu au groupe docker (optionnel)
                sudo usermod -aG docker ubuntu

                # Lancer le démon Docker
                sudo systemctl enable docker
                sudo systemctl start docker

                # Télécharger docker-compose.yml depuis GitHub
                curl -L -o /home/ubuntu/docker-compose.yml https://raw.githubusercontent.com/Loise/containerized-devops-workflow/refs/heads/main/docker-compose-aws.yml

                # Démarrer le compose
                cd /home/ubuntu
                sudo docker-compose up -d
              EOF
  tags = {
    Name = "learn-terraform"
  }
}
