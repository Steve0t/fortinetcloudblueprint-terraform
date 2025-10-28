terraform {
  required_version = ">= 1.9.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  # (Recommended) — uncomment and configure if you use remote state in Azure Storage
  # backend "azurerm" {
  #   resource_group_name  = "<your-tfstate-rg>"
  #   storage_account_name = "<your-tfstate-storage>"
  #   container_name       = "tfstate"
  #   key                  = "fortinetcloudblueprint.terraform.tfstate"
  # }
}

# ---------------------------------------------------------------------------
# AzureRM Provider Configuration
# ---------------------------------------------------------------------------
provider "azurerm" {
  features {}

  # Explicit IDs make runs reproducible and CI-safe
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
}

# ---------------------------------------------------------------------------
# Variables
# ---------------------------------------------------------------------------
variable "subscription_id" {
  description = "Azure subscription ID to deploy into"
  type        = string
}

variable "tenant_id" {
  description = "Azure Active Directory (Entra ID) tenant ID"
  type        = string
}

