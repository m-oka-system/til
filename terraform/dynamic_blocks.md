## ダイナミックブロック

Resource ブロックの中の特定のブロックに対してループ処理をして複数のブロックを動的に作成したり、条件に応じてブロックを作成することができる。

## for_each でループする例

- サブネット委任を動的に作成

```terraform
# subnet.tf
resource "azurerm_subnet" "this" {
  for_each                                  = var.subnet
  name                                      = "${each.value.name}-subnet"
  resource_group_name                       = var.resource_group_name
  virtual_network_name                      = azurerm_virtual_network.this[each.value.target_vnet].name
  address_prefixes                          = each.value.address_prefixes
  private_endpoint_network_policies_enabled = each.value.private_endpoint_network_policies_enabled

  dynamic "delegation" {
    for_each = lookup(each.value, "service_delegation", null) != null ? [each.value.service_delegation] : []
    content {
      name = "delegation"
      service_delegation {
        name    = delegation.value.name
        actions = delegation.value.actions
      }
    }
  }
}
```

```terraform
# variables.tf
variable "subnet" {
  default = {
    app = {
      name                                      = "app"
      target_vnet                               = "spoke1"
      address_prefixes                          = ["10.10.1.0/24"]
      private_endpoint_network_policies_enabled = false
      service_delegation = {
        name    = "Microsoft.Web/serverFarms"
        actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
      }
    }
    pe = {
      name                                      = "pe"
      target_vnet                               = "spoke1"
      address_prefixes                          = ["10.10.2.0/24"]
      private_endpoint_network_policies_enabled = true
      service_delegation                        = null
    }
    db = {
      name                                      = "db"
      target_vnet                               = "spoke1"
      address_prefixes                          = ["10.10.3.0/24"]
      private_endpoint_network_policies_enabled = false
      service_delegation = {
        name    = "Microsoft.DBforMySQL/flexibleServers"
        actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
      }
    }
    vm = {
      name                                      = "vm"
      target_vnet                               = "spoke1"
      address_prefixes                          = ["10.10.4.0/24"]
      private_endpoint_network_policies_enabled = false
      service_delegation                        = null
    }
  }
}
```

`for_each = lookup(each.value, "service_delegation", null) != null ? [each.value.service_delegation] : []` の箇所では、三項演算子を使って条件分岐をしている。

`service_delegation = null` であればサブネット委任の設定は行われない。

`for_each = lookup(each.value, "service_delegation", null) != null ? each.value.service_delegation : {}` と書くと true/false の場合で型が一致せずにエラーになるのでリストに変換している。

`each.value.service_delegation` は service_delegation ブロックの定義（つまり、特定の属性を持つマップ）を表し、{}は空のマップを表す。これらは両方ともマップ型であるにもかかわらず、Terraform はマップの中の属性も考慮に入れて型を比較する。よって、リストに変換してマップの属性を隠蔽して回避している。
