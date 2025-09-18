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

resource "aws_instance" "app_server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"

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
