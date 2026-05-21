provider "azurerm" {
  features {}
}

variables {
  name                = "vnet-test-eastus-001"
  resource_group_name = "rg-test-eastus-001"
  location            = "eastus"
  address_space       = ["10.0.0.0/16"]

  subnets = {
    "snet-app" = {
      address_prefixes  = ["10.0.1.0/24"]
      service_endpoints = ["Microsoft.Storage"]
    }
    "snet-db" = {
      address_prefixes  = ["10.0.2.0/24"]
      service_endpoints = []
    }
  }

  nsg_rules = {
    "snet-app" = [
      {
        name                   = "AllowHTTPS"
        priority               = 100
        direction              = "Inbound"
        access                 = "Allow"
        protocol               = "Tcp"
        destination_port_range = "443"
        source_address_prefix  = "Internet"
      }
    ]
  }

  tags = {
    Environment = "test"
    ManagedBy   = "terraform"
  }
}

run "vnet_name_is_correct" {
  command = plan

  assert {
    condition     = azurerm_virtual_network.this.name == "vnet-test-eastus-001"
    error_message = "VNet name does not match expected value."
  }
}

run "vnet_address_space_is_correct" {
  command = plan

  assert {
    condition     = tolist(azurerm_virtual_network.this.address_space) == tolist(["10.0.0.0/16"])
    error_message = "VNet address space does not match."
  }
}

run "subnets_are_created" {
  command = plan

  assert {
    condition     = azurerm_subnet.this["snet-app"].name == "snet-app"
    error_message = "App subnet not created correctly."
  }

  assert {
    condition     = azurerm_subnet.this["snet-db"].name == "snet-db"
    error_message = "DB subnet not created correctly."
  }
}

run "nsg_is_created_for_subnet" {
  command = plan

  assert {
    condition     = azurerm_network_security_group.this["snet-app"].name == "vnet-test-eastus-001-snet-app-nsg"
    error_message = "NSG naming does not match convention."
  }
}

run "tags_are_applied" {
  command = plan

  assert {
    condition     = azurerm_virtual_network.this.tags["Environment"] == "test"
    error_message = "Environment tag missing or incorrect."
  }

  assert {
    condition     = azurerm_virtual_network.this.tags["ManagedBy"] == "terraform"
    error_message = "ManagedBy tag missing or incorrect."
  }
}
