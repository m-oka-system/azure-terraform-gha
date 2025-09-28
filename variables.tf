variable "common" {
  type = map(string)
  default = {
    project  = "tfgha"
    env      = "dev"
    location = "japaneast"
  }
}

variable "allowed_cidr" {
  type = list(string)
  default = [
    "203.0.113.10",
    "203.0.113.11"
  ]
}

variable "key_vault" {
  type = object({
    name                          = string
    sku_name                      = string
    rbac_authorization_enabled    = bool
    purge_protection_enabled      = bool
    soft_delete_retention_days    = number
    public_network_access_enabled = bool
    network_acls = object({
      default_action             = string
      bypass                     = string
      ip_rules                   = list(string)
      virtual_network_subnet_ids = list(string)
    })
  })
  default = {
    name                          = "app"
    sku_name                      = "standard"
    rbac_authorization_enabled    = true
    purge_protection_enabled      = false
    soft_delete_retention_days    = 7
    public_network_access_enabled = true
    network_acls = {
      default_action             = "Allow"
      bypass                     = "AzureServices"
      ip_rules                   = ["MyIP"]
      virtual_network_subnet_ids = []
    }
  }
}

variable "storage" {
  type = object({
    name                          = string
    account_tier                  = string
    account_kind                  = string
    account_replication_type      = string
    access_tier                   = string
    https_traffic_only_enabled    = bool
    public_network_access_enabled = bool
    is_hns_enabled                = bool
    blob_properties = object({
      versioning_enabled                = bool
      change_feed_enabled               = bool
      last_access_time_enabled          = bool
      delete_retention_policy           = number
      container_delete_retention_policy = number
    })
    network_rules = object({
      default_action             = string
      bypass                     = list(string)
      ip_rules                   = list(string)
      virtual_network_subnet_ids = list(string)
    })
  })
  default = {
    name                          = "app"
    account_tier                  = "Standard"
    account_kind                  = "StorageV2"
    account_replication_type      = "LRS"
    access_tier                   = "Hot"
    https_traffic_only_enabled    = true
    public_network_access_enabled = true
    is_hns_enabled                = false
    blob_properties = {
      versioning_enabled                = false
      change_feed_enabled               = false
      last_access_time_enabled          = false
      delete_retention_policy           = 7
      container_delete_retention_policy = 7
    }
    network_rules = null
  }
}

variable "user_assigned_identity" {
  type = map(object({
    name = string
  }))
  default = {
    gha = {
      name = "gha"
    }
  }
}

variable "role_assignment" {
  type = map(object({
    target_identity      = string
    role_definition_name = string
  }))
  default = {
    gha_owner = {
      target_identity      = "gha"
      role_definition_name = "Owner"
    }
    gha_storage_blob_data_contributor = {
      target_identity      = "gha"
      role_definition_name = "Storage Blob Data Contributor"
    }
    gha_key_vault_secrets_officer = {
      target_identity      = "gha"
      role_definition_name = "Key Vault Secrets Officer"
    }
  }
}

variable "federated_identity_credential" {
  type = object({
    name            = string
    target_identity = string
    audience        = list(string)
    issuer          = string
    subject         = string
  })
  default = {
    name            = "azure-terraform-gha"
    target_identity = "gha"
    audience        = ["api://AzureADTokenExchange"]
    issuer          = "https://token.actions.githubusercontent.com"
    subject         = "repo:m-oka-system/azure-terraform-gha:environment:dev"
  }
}
