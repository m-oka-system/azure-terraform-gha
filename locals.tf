data "azurerm_client_config" "current" {}

locals {
  # 共通の変数
  common = {
    tags = {
      project = var.common.project
      env     = var.common.env
    }
  }
}
