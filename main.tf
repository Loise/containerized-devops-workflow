/**
/¡\ if project already exist : terraform import render_project.containerized_devops_workflow prj-xxxx
**/

/**
TODO pipeline dedicated

Steps :
Creer la clé d'API
Creer le render.tfvars
Recuperer le owner_id

how to get owner_id : 
curl --request GET \
  --url https://api.render.com/v1/owners \
  --header 'accept: application/json' \
  --header 'authorization: Bearer xxxx-api_key-xxxx'

bien ajouter le render.tfvars dans le gitignore

Puis creer le fichier ci-dessous

Si le projet existe deja : recuperer l'id du projet depuis l'url
terraform import render_project.containerized_devops_workflow prj-xxx
**/

/**
should be necessary to add payment method 
**/

terraform {
  required_providers {
    render = {
      source  = "render-oss/render"
      version = "1.7.5"
    }
  }
}

variable "api_key" {
  type = string
}

variable "owner_id" {
  type = string
}

variable "environment" {
  type = string
}

provider "render" {
  api_key  = var.api_key
  owner_id = var.owner_id
}

resource "render_project" "containerized_devops_workflow" {
  name = "containerized_devops_workflow"
  environments = {
    "production" : {
      name = "production"
      protected_status = "unprotected"
    },
    "development" : {
      name = "development"
      protected_status = "unprotected"
    }
  }
}

resource "render_web_service" "containerized_devops_workflow" {
  name         = "monapp"
  plan         = "starter"
  region       = "frankfurt"
  environment_id = render_project.containerized_devops_workflow.environments[var.environment].id

  runtime_source = {
    image = {
      image_url = "ghcr.io/loise/containerized-devops-workflow/monapp"
      tag       = "latest"
    }
  }
  # start_command, healthcheck, ports, etc. selon ton besoin
}

