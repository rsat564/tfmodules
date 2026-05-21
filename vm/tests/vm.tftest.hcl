provider "azurerm" {
  features {}
}

variables {
  name                = "vm-test-eastus-001"
  resource_group_name = "rg-test-eastus-001"
  location            = "eastus"
  subnet_id           = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet-test/subnets/snet-app"
  vm_size             = "Standard_D2s_v3"
  admin_username      = "azureadmin"
  os_disk_size_gb     = 30
  os_disk_type        = "Premium_LRS"
  availability_zone   = "1"
  enable_backup       = false
  enable_monitoring   = false

  data_disks = {
    "data" = {
      disk_size_gb         = 64
      storage_account_type = "Premium_LRS"
      lun                  = 0
      caching              = "ReadOnly"
    }
  }

  tags = {
    Environment = "test"
    ManagedBy   = "terraform"
  }
}

run "vm_name_is_correct" {
  command = plan

  assert {
    condition     = azurerm_linux_virtual_machine.this.name == "vm-test-eastus-001"
    error_message = "VM name does not match."
  }
}

run "vm_size_is_correct" {
  command = plan

  assert {
    condition     = azurerm_linux_virtual_machine.this.size == "Standard_D2s_v3"
    error_message = "VM size does not match."
  }
}

run "vm_zone_is_set" {
  command = plan

  assert {
    condition     = azurerm_linux_virtual_machine.this.zone == "1"
    error_message = "VM availability zone not set correctly."
  }
}

run "vm_secure_boot_enabled" {
  command = plan

  assert {
    condition     = azurerm_linux_virtual_machine.this.secure_boot_enabled == true
    error_message = "Secure boot should be enabled."
  }
}

run "vm_password_auth_disabled" {
  command = plan

  assert {
    condition     = azurerm_linux_virtual_machine.this.disable_password_authentication == true
    error_message = "Password authentication must be disabled."
  }
}

run "nic_accelerated_networking" {
  command = plan

  assert {
    condition     = azurerm_network_interface.this.accelerated_networking_enabled == true
    error_message = "Accelerated networking should be enabled."
  }
}

run "data_disk_is_created" {
  command = plan

  assert {
    condition     = azurerm_managed_disk.this["data"].disk_size_gb == 64
    error_message = "Data disk size does not match."
  }

  assert {
    condition     = azurerm_managed_disk.this["data"].zone == "1"
    error_message = "Data disk should be zone-aligned with VM."
  }
}

run "tags_are_applied" {
  command = plan

  assert {
    condition     = azurerm_linux_virtual_machine.this.tags["Environment"] == "test"
    error_message = "Tags not applied to VM."
  }
}
