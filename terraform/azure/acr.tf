resource "azurerm_resource_group" "rg" {
  name     = "${var.prefix}-${var.env}-rg"
  location = var.location
}

locals {
  container_registry_name = "${var.prefix}${var.env}acr"
}

resource "azurerm_container_registry" "acr" {
  name                          = local.container_registry_name
  resource_group_name           = azurerm_resource_group.rg.name
  location                      = azurerm_resource_group.rg.location
  sku                           = var.container_registry_sku_name
  admin_enabled                 = false
  public_network_access_enabled = true

  network_rule_set {
    default_action = "Deny"

    ip_rule = [
      # list を for でループ処理
      for ip in var.allowed_cidr : {
        action   = "Allow"
        ip_range = "${ip}/32"
      }
    ]
    virtual_network = []
  }
}
