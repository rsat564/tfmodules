variable "name" {
  description = "Name of the Virtual Machine."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9-]{0,62}[a-zA-Z0-9]$", var.name))
    error_message = "VM name must be 2-64 characters, start/end with alphanumeric."
  }
}

variable "resource_group_name" {
  description = "Name of the resource group."
  type        = string
}

variable "location" {
  description = "Azure region for the VM."
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID where the VM NIC will be placed."
  type        = string
}

variable "vm_size" {
  description = "Size/SKU of the Virtual Machine."
  type        = string
  default     = "Standard_D2s_v3"

  validation {
    condition     = can(regex("^Standard_", var.vm_size))
    error_message = "VM size must start with 'Standard_'."
  }
}

variable "admin_username" {
  description = "Admin username for SSH access."
  type        = string
  default     = "azureadmin"

  validation {
    condition     = !contains(["admin", "administrator", "root", "user"], lower(var.admin_username))
    error_message = "Admin username cannot be a commonly used name."
  }

  validation {
    condition     = length(var.admin_username) >= 4 && length(var.admin_username) <= 20
    error_message = "Admin username must be between 4 and 20 characters."
  }
}

variable "os_disk_size_gb" {
  description = "Size of the OS disk in GB."
  type        = number
  default     = 30

  validation {
    condition     = var.os_disk_size_gb >= 30 && var.os_disk_size_gb <= 1024
    error_message = "OS disk size must be between 30 and 1024 GB."
  }
}

variable "os_disk_type" {
  description = "Storage account type for OS disk."
  type        = string
  default     = "Premium_LRS"

  validation {
    condition     = contains(["Premium_LRS", "Premium_ZRS", "Standard_LRS", "StandardSSD_LRS", "StandardSSD_ZRS"], var.os_disk_type)
    error_message = "Invalid OS disk type."
  }
}

variable "availability_zone" {
  description = "Availability Zone for high availability (1, 2, or 3)."
  type        = string
  default     = "1"

  validation {
    condition     = contains(["1", "2", "3"], var.availability_zone)
    error_message = "Availability zone must be 1, 2, or 3."
  }
}

variable "enable_accelerated_networking" {
  description = "Enable accelerated networking on NIC."
  type        = bool
  default     = true
}

variable "data_disks" {
  description = "Map of data disks to attach."
  type = map(object({
    disk_size_gb         = number
    storage_account_type = string
    lun                  = number
    caching              = optional(string, "ReadOnly")
  }))
  default = {}

  validation {
    condition = alltrue([for k, v in var.data_disks : v.lun >= 0 && v.lun <= 63])
    error_message = "LUN must be between 0 and 63."
  }

  validation {
    condition = alltrue([for k, v in var.data_disks : v.disk_size_gb >= 1 && v.disk_size_gb <= 32767])
    error_message = "Disk size must be between 1 and 32767 GB."
  }
}

variable "disk_encryption_set_id" {
  description = "Disk Encryption Set ID for customer-managed key encryption. Optional."
  type        = string
  default     = null
}

variable "enable_backup" {
  description = "Enable Azure Backup for the VM."
  type        = bool
  default     = true
}

variable "backup_policy_id" {
  description = "Backup policy ID. Required if enable_backup is true."
  type        = string
  default     = null
}

variable "recovery_vault_name" {
  description = "Recovery Services Vault name. Required if enable_backup is true."
  type        = string
  default     = null
}

variable "enable_monitoring" {
  description = "Install Azure Monitor Agent on the VM."
  type        = bool
  default     = true
}

variable "source_image" {
  description = "Source image reference for the VM."
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })
  default = {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
}

variable "enable_secure_boot" {
  description = "Enable Secure Boot (Trusted Launch)."
  type        = bool
  default     = true
}

variable "enable_vtpm" {
  description = "Enable vTPM (Trusted Launch)."
  type        = bool
  default     = true
}

variable "patch_mode" {
  description = "Patch mode for the VM."
  type        = string
  default     = "AutomaticByPlatform"

  validation {
    condition     = contains(["AutomaticByPlatform", "ImageDefault"], var.patch_mode)
    error_message = "Patch mode must be AutomaticByPlatform or ImageDefault."
  }
}

variable "tags" {
  description = "Tags to apply to all VM resources."
  type        = map(string)
  default     = {}
}
