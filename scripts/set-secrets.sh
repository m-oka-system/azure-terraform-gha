#!/usr/bin/env bash
set -euo pipefail

# Get Terraform outputs
KEY_VAULT_NAME=$(terraform output -raw KEY_VAULT_NAME)
STORAGE_ACCOUNT_PRIMARY_KEY=$(terraform output -raw STORAGE_ACCOUNT_PRIMARY_KEY)

# Define secrets to register (key:value pairs)
SECRETS=(
    "STORAGE-ACCOUNT-PRIMARY-KEY:$STORAGE_ACCOUNT_PRIMARY_KEY"
    "TEST-SECRET:my-test-value"
)

echo "Registering secrets to Key Vault: $KEY_VAULT_NAME"

# Register each secret to Key Vault
for secret in "${SECRETS[@]}"; do
    secret_name="${secret%%:*}"
    secret_value="${secret##*:}"

    # Check if secret already exists
    if az keyvault secret show --vault-name "$KEY_VAULT_NAME" --name "$secret_name" --output none 2>/dev/null; then
        echo "✓ Secret $secret_name already exists, skipping"
    else
        az keyvault secret set --vault-name "$KEY_VAULT_NAME" --name "$secret_name" --value "$secret_value" --output none
        echo "✓ Secret $secret_name registered"
    fi
done

echo "Secrets registered to Key Vault successfully"
