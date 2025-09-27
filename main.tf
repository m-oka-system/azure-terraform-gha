resource "random_integer" "num" {
  min = 10000
  max = 99999
}

# ------------------------------------------------------------------------------------------------------
# Resource Group
# ------------------------------------------------------------------------------------------------------
resource "azurerm_resource_group" "rg" {
  name     = "rg-${var.common.project}-${var.common.env}"
  location = var.common.location

  tags = local.common.tags
}

# ------------------------------------------------------------------------------------------------------
# Azure Key Vault
# ------------------------------------------------------------------------------------------------------
resource "azurerm_key_vault" "this" {
  name                          = "kv-${var.common.project}-${var.common.env}-${random_integer.num.result}"
  location                      = azurerm_resource_group.rg.location
  resource_group_name           = azurerm_resource_group.rg.name
  sku_name                      = var.key_vault.sku_name
  tenant_id                     = data.azurerm_client_config.current.tenant_id
  rbac_authorization_enabled    = var.key_vault.rbac_authorization_enabled
  purge_protection_enabled      = var.key_vault.purge_protection_enabled
  soft_delete_retention_days    = var.key_vault.soft_delete_retention_days
  public_network_access_enabled = var.key_vault.public_network_access_enabled
  access_policy                 = []

  network_acls {
    default_action = var.key_vault.network_acls.default_action
    bypass         = var.key_vault.network_acls.bypass
    ip_rules       = var.allowed_cidr
  }

  tags = local.common.tags
}

# ------------------------------------------------------------------------------------------------------
# Storage Account
# ------------------------------------------------------------------------------------------------------
resource "azurerm_storage_account" "this" {
  name                          = replace("st-${var.storage.name}-${var.common.project}-${var.common.env}-${random_integer.num.result}", "-", "")
  resource_group_name           = azurerm_resource_group.rg.name
  location                      = azurerm_resource_group.rg.location
  account_tier                  = var.storage.account_tier
  account_kind                  = var.storage.account_kind
  account_replication_type      = var.storage.account_replication_type
  access_tier                   = var.storage.access_tier
  https_traffic_only_enabled    = var.storage.https_traffic_only_enabled
  public_network_access_enabled = var.storage.public_network_access_enabled
  is_hns_enabled                = var.storage.is_hns_enabled

  blob_properties {
    versioning_enabled       = var.storage.blob_properties.versioning_enabled
    change_feed_enabled      = var.storage.blob_properties.change_feed_enabled
    last_access_time_enabled = var.storage.blob_properties.last_access_time_enabled

    delete_retention_policy {
      days = var.storage.blob_properties.delete_retention_policy
    }

    container_delete_retention_policy {
      days = var.storage.blob_properties.container_delete_retention_policy
    }
  }

  dynamic "network_rules" {
    for_each = var.storage.network_rules != null ? [true] : []

    content {
      default_action             = var.storage.network_rules.default_action
      bypass                     = var.storage.network_rules.bypass
      ip_rules                   = join(",", lookup(var.storage.network_rules, "ip_rules", null)) == "MyIP" ? var.allowed_cidr : lookup(var.storage.network_rules, "ip_rules", null)
      virtual_network_subnet_ids = var.storage.network_rules.virtual_network_subnet_ids
    }
  }

  tags = local.common.tags
}

# ------------------------------------------------------------------------------------------------------
# User Assigned Managed ID
# ------------------------------------------------------------------------------------------------------
resource "azurerm_user_assigned_identity" "this" {
  for_each            = var.user_assigned_identity
  name                = "id-${each.value.name}-${var.common.project}-${var.common.env}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  tags = local.common.tags
}

resource "azurerm_role_assignment" "this" {
  for_each             = var.role_assignment
  scope                = "/subscriptions/${data.azurerm_client_config.current.subscription_id}"
  role_definition_name = each.value.role_definition_name
  principal_id         = azurerm_user_assigned_identity.this[each.value.target_identity].principal_id
}

resource "azurerm_federated_identity_credential" "this" {
  name                = var.federated_identity_credential.name
  resource_group_name = azurerm_resource_group.rg.name
  audience            = var.federated_identity_credential.audience
  issuer              = var.federated_identity_credential.issuer
  parent_id           = azurerm_user_assigned_identity.this[var.federated_identity_credential.target_identity].id
  subject             = var.federated_identity_credential.subject
}
