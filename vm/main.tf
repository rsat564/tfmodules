#--------------------------------------------------------------
# Azure Linux Virtual Machine Module
# Provisions a VM with NIC, data disks, monitoring, and backup
# Designed for: High Availability, Scalability, High Security
#--------------------------------------------------------------

#--------------------------------------------------------------
# SSH Key Generation
#--------------------------------------------------------------

resource "tls_private_key" "this" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

#--------------------------------------------------------------
# Network Interface
#--------------------------------------------------------------

resource "azurerm_network_interface" "this" {
  name                           = "nic-${var.name}"
  location                       = var.location
  resource_group_name            = var.resource_group_name
  accelerated_networking_enabled = var.enable_accelerated_networking

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
  }

  tags = var.tags
}

#--------------------------------------------------------------
# Linux Virtual Machine
#--------------------------------------------------------------

resource "azurerm_linux_virtual_machine" "this" {
  name                            = var.name
  resource_group_name             = var.resource_group_name
  location                        = var.location
  size                            = var.vm_size
  admin_username                  = var.admin_username
  disable_password_authentication = true

  # High Availability
  zone = var.availability_zone

  # Security: Trusted Launch
  secure_boot_enabled = var.enable_secure_boot
  vtpm_enabled        = var.enable_vtpm

  network_interface_ids = [
    azurerm_network_interface.this.id
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = tls_private_key.this.public_key_openssh
  }

  os_disk {
    name                   = "osdisk-${var.name}"
    caching                = "ReadWrite"
    storage_account_type   = var.os_disk_type
    disk_size_gb           = var.os_disk_size_gb
    disk_encryption_set_id = var.disk_encryption_set_id
  }

  source_image_reference {
    publisher = var.source_image.publisher
    offer     = var.source_image.offer
    sku       = var.source_image.sku
    version   = var.source_image.version
  }

  identity {
    type = "SystemAssigned"
  }

  # Security: Auto-patching
  patch_assessment_mode = var.patch_mode
  patch_mode            = var.patch_mode

  tags = var.tags
}

#--------------------------------------------------------------
# Data Disks
#--------------------------------------------------------------

resource "azurerm_managed_disk" "this" {
  for_each = var.data_disks

  name                   = "disk-${each.key}-${var.name}"
  location               = var.location
  resource_group_name    = var.resource_group_name
  storage_account_type   = each.value.storage_account_type
  create_option          = "Empty"
  disk_size_gb           = each.value.disk_size_gb
  disk_encryption_set_id = var.disk_encryption_set_id
  zone                   = var.availability_zone

  tags = var.tags
}

resource "azurerm_virtual_machine_data_disk_attachment" "this" {
  for_each = var.data_disks

  managed_disk_id    = azurerm_managed_disk.this[each.key].id
  virtual_machine_id = azurerm_linux_virtual_machine.this.id
  lun                = each.value.lun
  caching            = each.value.caching
}

#--------------------------------------------------------------
# Azure Monitor Agent (Observability)
#--------------------------------------------------------------

resource "azurerm_virtual_machine_extension" "azure_monitor" {
  count = var.enable_monitoring ? 1 : 0

  name                       = "AzureMonitorLinuxAgent"
  virtual_machine_id         = azurerm_linux_virtual_machine.this.id
  publisher                  = "Microsoft.Azure.Monitor"
  type                       = "AzureMonitorLinuxAgent"
  type_handler_version       = "1.0"
  automatic_upgrade_enabled  = true
  auto_upgrade_minor_version = true

  tags = var.tags
}

#--------------------------------------------------------------
# VM Backup
#--------------------------------------------------------------

resource "azurerm_backup_protected_vm" "this" {
  count = var.enable_backup ? 1 : 0

  resource_group_name = var.resource_group_name
  recovery_vault_name = var.recovery_vault_name
  source_vm_id        = azurerm_linux_virtual_machine.this.id
  backup_policy_id    = var.backup_policy_id
}
