# Module Usage Guide

## VNet Module

```hcl
module "vnet" {
  source = "../modules/vnet"

  name                = "vnet-myproject-dev"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  address_space       = ["10.0.0.0/16"]

  subnets = {
    "snet-app" = {
      address_prefixes  = ["10.0.1.0/24"]
      service_endpoints = ["Microsoft.Storage"]
    }
  }

  nsg_rules = {
    "snet-app" = [
      {
        name                       = "AllowHTTPS"
        priority                   = 100
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        destination_port_range     = "443"
        source_address_prefix      = "VirtualNetwork"
        destination_address_prefix = "VirtualNetwork"
      }
    ]
  }

  tags = { environment = "dev" }
}
```

## VM Module

```hcl
module "vm" {
  source = "../modules/vm"

  name                = "vm-myapp-dev"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  subnet_id           = module.vnet.subnet_ids["snet-app"]
  vm_size             = "Standard_D2s_v3"
  availability_zone   = "1"

  data_disks = {
    "data" = {
      disk_size_gb         = 64
      storage_account_type = "Premium_LRS"
      lun                  = 0
      caching              = "ReadOnly"
    }
  }

  disk_encryption_set_id = azurerm_disk_encryption_set.main.id
  enable_backup          = true
  backup_policy_id       = azurerm_backup_policy_vm.daily.id
  recovery_vault_name    = azurerm_recovery_services_vault.main.name

  tags = { environment = "dev" }
}
```

## Storage Module

```hcl
module "storage" {
  source = "../modules/storage"

  name                = "stmyappdev"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  replication_type    = "ZRS"

  containers = {
    "data" = { access_type = "private" }
    "logs" = { access_type = "private" }
  }

  allowed_subnet_ids = [module.vnet.subnet_ids["snet-app"]]

  lifecycle_rules = [
    {
      name                       = "archive-logs"
      prefix_match               = ["logs/"]
      tier_to_cool_after_days    = 30
      tier_to_archive_after_days = 90
      delete_after_days          = 365
    }
  ]

  encryption_key_vault_key_id = azurerm_key_vault_key.storage.id

  tags = { environment = "dev" }
}
```

## Running Module Tests

```bash
cd modules/vnet
terraform init -backend=false
terraform test

cd ../vm
terraform init -backend=false
terraform test

cd ../storage
terraform init -backend=false
terraform test
```
