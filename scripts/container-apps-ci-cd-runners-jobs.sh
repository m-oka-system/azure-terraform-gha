RESOURCE_GROUP="rg-tfgha-dev"
LOCATION="japaneast"
ENVIRONMENT="cae-tfgha-dev"
CONTAINER_REGISTRY_NAME="acrghatfghadev"
CONTAINER_IMAGE_NAME="gha-runner:1.0"
KEY_VAULT_NAME="kv-tfgha-dev-45044"
KEY_NAME="github-app-private-key"
KEY_VAULT_SECRET_URI="https://$KEY_VAULT_NAME.vault.azure.net/secrets/$KEY_NAME"
MANAGED_IDENTITY_NAME="id-runner-tfgha-dev"
JOB_NAME="job-gha-tfgha-dev"
REP_URL="https://github.com/m-oka-system/container-apps-ci-cd-runner-tutorial"
GITHUB_APP_ID="your_github_app_id"
GITHUB_APP_INSTALL_ID="your_github_app_installation_id"
REPO_OWNER="m-oka-system"
REPO_NAME="azure-terraform-gha"

# GitHub Apps の作成とインストール
# GitHub Apps の秘密鍵を containerappjobs.private-key.pem で保存
# チュートリアルの GitHub リポジトリを Fork して entrypoint.sh を修正
# https://azure.github.io/jpazpaas/2024/07/30/How-to-use-GithubApp-for-self-hosted-runner-on-ContainerApps-Job.html
https://github.com/Azure-Samples/container-apps-ci-cd-runner-tutorial


# Container App 環境の作成
az containerapp env create --name "$ENVIRONMENT" --resource-group "$RESOURCE_GROUP" --location "$LOCATION"

# Azure Container Registry の作成
az acr create --name "$CONTAINER_REGISTRY_NAME" --resource-group "$RESOURCE_GROUP" --location "$LOCATION" --sku Basic --admin-enabled false

# Azure KeyVault の作成
az keyvault create --name "$KEY_VAULT_NAME" --resource-group "$RESOURCE_GROUP" --location "$LOCATION"

# マネージドID の作成
az identity create --name $MANAGED_IDENTITY_NAME --resource-group "$RESOURCE_GROUP" --location "$LOCATION"
MANAGED_IDENTITY_ID=$(az identity show --name "$MANAGED_IDENTITY_NAME" --resource-group "$RESOURCE_GROUP" --query id --output tsv)

# マネージドIDにロールを割り当て
MANAGED_IDENTITY_OBJECT_ID=$(az identity show --name "$MANAGED_IDENTITY_NAME" --resource-group "$RESOURCE_GROUP" --query principalId --output tsv)
KEY_VAULT_ID=$(az keyvault show --name "$KEY_VAULT_NAME" --resource-group "$RESOURCE_GROUP" --query id --output tsv)
ACR_ID=$(az acr show --name "$CONTAINER_REGISTRY_NAME" --resource-group "$RESOURCE_GROUP" --query id --output tsv)
az role assignment create --assignee "$MANAGED_IDENTITY_OBJECT_ID" --role "Key Vault Secrets User" --scope "$KEY_VAULT_ID"
az role assignment create --assignee "$MANAGED_IDENTITY_OBJECT_ID" --role "AcrPull" --scope "$ACR_ID"

# runner イメージをビルドして ACR にプッシュ
az acr login -n "$CONTAINER_REGISTRY_NAME"
az acr build --registry "$CONTAINER_REGISTRY_NAME" --image "$CONTAINER_IMAGE_NAME" --file "Dockerfile.github" "$REP_URL"

# GitHub Apps の秘密鍵を Key Vault シークレットに登録
az keyvault secret set --vault-name "$KEY_VAULT_NAME" --name "$KEY_NAME" --file "containerappjobs.private-key.pem"

# Container Apps Job の作成
az containerapp job create -n "$JOB_NAME" -g "$RESOURCE_GROUP" --environment "$ENVIRONMENT" \
    --trigger-type Event \
    --replica-timeout 1800 \
    --replica-retry-limit 0 \
    --replica-completion-count 1 \
    --parallelism 1 \
    --image "$CONTAINER_REGISTRY_NAME.azurecr.io/$CONTAINER_IMAGE_NAME" \
    --min-executions 0 \
    --max-executions 10 \
    --polling-interval 30 \
    --scale-rule-name "github-runner" \
    --scale-rule-type "github-runner" \
    --scale-rule-metadata "githubAPIURL=https://api.github.com" "owner=$REPO_OWNER" "runnerScope=repo" "repos=$REPO_NAME" "targetWorkflowQueueLength=1" "applicationID=$GITHUB_APP_ID" "installationID=$GITHUB_APP_INSTALL_ID" \
    --scale-rule-auth "appKey=$KEY_NAME" \
    --cpu "2.0" \
    --memory "4Gi" \
    --mi-user-assigned "$MANAGED_IDENTITY_ID" \
    --secrets "$KEY_NAME=keyvaultref:$KEY_VAULT_SECRET_URI,identityref:$MANAGED_IDENTITY_ID" \
    --env-vars "PEM_KEY=secretref:$KEY_NAME" "GITHUB_APP_ID=$GITHUB_APP_ID" "GITHUB_OWNER=$REPO_OWNER" "GITHUB_REPO=$REPO_NAME" \
    --registry-server "$CONTAINER_REGISTRY_NAME.azurecr.io" \
    --registry-identity "$MANAGED_IDENTITY_ID"

# 参考URL
# https://learn.microsoft.com/ja-jp/azure/container-apps/tutorial-ci-cd-runners-jobs
# https://azure.github.io/jpazpaas/2024/07/30/How-to-use-GithubApp-for-self-hosted-runner-on-ContainerApps-Job.html
# https://zenn.dev/yutakaosada/articles/6ce1577a84db2d
