output "KEY_VAULT_NAME" {
  value = azurerm_key_vault.this.name
}

output "STORAGE_ACCOUNT_PRIMARY_KEY" {
  value     = azurerm_storage_account.this.primary_access_key
  sensitive = true
}
