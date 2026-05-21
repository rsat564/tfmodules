variable "name" {
  description = "Name of the Storage Account. Must be globally unique, 3-24 lowercase alphanumeric."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.name))
    error_message = "Storage account name must be 3-24 lowercase letters and numbers only."
  }
}

variable "resource_group_name" {
  description = "Name of the resource group."
  type        = string
}

variable "location" {
  description = "Azure region for the Storage Account."
  type        = string
}

variable "account_tier" {
  description = "Performance tier (Standard or Premium)."
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Standard", "Premium"], var.account_tier)
    error_message = "Account tier must be Standard or Premium."
  }
}

variable "replication_type" {
  description = "Replication type for high availability."
  type        = string
  default     = "ZRS"

  validation {
    condition     = contains(["LRS", "GRS", "RAGRS", "ZRS", "GZRS", "RAGZRS"], var.replication_type)
    error_message = "Must be one of: LRS, GRS, RAGRS, ZRS, GZRS, RAGZRS."
  }
}

variable "containers" {
  description = "Map of blob containers to create."
  type = map(object({
    access_type = optional(string, "private")
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.containers : contains(["private", "blob", "container"], v.access_type)
    ])
    error_message = "Container access_type must be private, blob, or container."
  }
}

variable "allowed_subnet_ids" {
  description = "List of subnet IDs allowed to access the storage account."
  type        = list(string)
  default     = []
}

variable "public_network_access" {
  description = "Enable public network access."
  type        = bool
  default     = false
}

variable "enable_infrastructure_encryption" {
  description = "Enable double encryption at the infrastructure layer."
  type        = bool
  default     = true
}

variable "enable_versioning" {
  description = "Enable blob versioning for data protection."
  type        = bool
  default     = true
}

variable "enable_change_feed" {
  description = "Enable change feed for blob change tracking."
  type        = bool
  default     = true
}

variable "soft_delete_retention_days" {
  description = "Days to retain soft-deleted blobs."
  type        = number
  default     = 7

  validation {
    condition     = var.soft_delete_retention_days >= 1 && var.soft_delete_retention_days <= 365
    error_message = "Retention must be between 1 and 365 days."
  }
}

variable "container_soft_delete_retention_days" {
  description = "Days to retain soft-deleted containers."
  type        = number
  default     = 7

  validation {
    condition     = var.container_soft_delete_retention_days >= 1 && var.container_soft_delete_retention_days <= 365
    error_message = "Retention must be between 1 and 365 days."
  }
}

variable "lifecycle_rules" {
  description = "Lifecycle management rules for cost optimization at scale."
  type = list(object({
    name                       = string
    enabled                    = optional(bool, true)
    prefix_match               = optional(list(string), [])
    blob_types                 = optional(list(string), ["blockBlob"])
    tier_to_cool_after_days    = optional(number, null)
    tier_to_archive_after_days = optional(number, null)
    delete_after_days          = optional(number, null)
    snapshot_delete_after_days = optional(number, null)
    version_delete_after_days  = optional(number, null)
  }))
  default = []
}

variable "encryption_key_vault_key_id" {
  description = "Key Vault Key ID for customer-managed key encryption. If null, Microsoft-managed keys are used."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default     = {}
}
