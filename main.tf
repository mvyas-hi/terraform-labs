#Configure the Azure Provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.23.0"
    }
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }
  required_version = ">= 1.1.0"
}
# Configure the Azure Provider
provider "azurerm" {
  features {  
  }
  subscription_id = "c8165f0d-91bd-4d1e-87b5-fbfb0a581041"
  
}

resource "azurerm_resource_group" "rg" {
  name     = "mv-terraform-dev"
  location = "westus"

  tags = {
    Environment = "Terraform Getting Started"
    Team = "DevOps"
  }

}

## Create a vertual netork
#resource "azurerm_virtual_network" "vnet" {
#  name = "myTFVnet"
#  address_space = [ "10.0.0.0/24" ]
#  location = "westus2"
#  resource_group_name = azurerm_resource_group.rg.name
#
#  tags = azurerm_resource_group.rg.tags
#  
#}
resource "azurerm_log_analytics_workspace" "rg" {
  name                = "mv-terraform"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_container_app_environment" "rg" {
  name                       = "my-environment-dev"
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  ##logs_destination           = "log-analytics"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.rg.id
  workload_profile {
    name = "Consumption"
    workload_profile_type = "Consumption"
    minimum_count = "0"
    maximum_count = "1"
  } 
}
resource "azurerm_container_app" "mycongainer" {
  name = "mv-env-dev"
  container_app_environment_id = azurerm_container_app_environment.rg.id
  resource_group_name = azurerm_resource_group.rg.name
  revision_mode = "Single"
  template {
    container{
    name = "hello-world"
    image = "mcr.microsoft.com/k8se/quickstart:latest"
    cpu = "0.25"
    memory = "0.5Gi"
  }    
 }
 ingress {
      external_enabled = true         # Set to false for internal-only
      target_port      = 80
      transport        = "auto"       # Can also be "http" or "http2"
      traffic_weight {
        latest_revision = true
        percentage = 100
      }
    }
}
resource "azurerm_container_registry" "acr" {
  name = "mvterraformacr"
  resource_group_name = azurerm_resource_group.rg.name
  location = azurerm_resource_group.rg.location
  sku = "Premium"
  admin_enabled = true
  
}
output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "container_app_environment_id" {
  value = azurerm_container_app_environment.rg.id
}

output "azurerm_container_fqdn" {
  value = azurerm_container_app.mycongainer.latest_revision_fqdn
}