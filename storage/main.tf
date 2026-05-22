#--------------------------------------------------------------
# Azure Storage Account Module
# Provisions a Storage Account with blob containers, lifecycle
# policies, encryption, and network security.
# Designed for: High Availability, Scalability.
#--------------------------------------------------------------

resource "azurerm_storage_account" "this" {
  name                     = var.name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = var.account_tier
  account_replication_type = var.replication_type

  # High Availability
  infrastructure_encryption_enabled = var.enable_infrastructure_encryption

  # Security
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = false
  public_network_access_enabled   = var.public_network_access
  https_traffic_only_enabled      = true

  blob_properties {
    versioning_enabled       = var.enable_versioning
    last_access_time_enabled = true
    change_feed_enabled      = var.enable_change_feed

    delete_retention_policy {
      days = var.soft_delete_retention_days
    }
    container_delete_retention_policy {
      days = var.container_soft_delete_retention_days
    }
  }

  network_rules {
    default_action             = "Deny"
    virtual_network_subnet_ids = var.allowed_subnet_ids
    bypass                     = ["AzureServices", "Logging", "Metrics"]
  }

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

#--------------------------------------------------------------
# Blob Containers
#--------------------------------------------------------------

resource "azurerm_storage_container" "this" {
  for_each = var.containers

  name                  = each.key
  storage_account_id    = azurerm_storage_account.this.id
  container_access_type = each.value.access_type
}

#--------------------------------------------------------------
# Lifecycle Management Policy (Scalability: auto-tiering)
#--------------------------------------------------------------

resource "azurerm_storage_management_policy" "this" {
  count = length(var.lifecycle_rules) > 0 ? 1 : 0

  storage_account_id = azurerm_storage_account.this.id

  dynamic "rule" {
    for_each = var.lifecycle_rules
    content {
      name    = rule.value.name
      enabled = rule.value.enabled

      filters {
        blob_types   = rule.value.blob_types
        prefix_match = length(rule.value.prefix_match) > 0 ? rule.value.prefix_match : null
      }

      actions {
        dynamic "base_blob" {
          for_each = (
            rule.value.tier_to_cool_after_days != null ||
            rule.value.tier_to_archive_after_days != null ||
            rule.value.delete_after_days != null
          ) ? [1] : []
          content {
            tier_to_cool_after_days_since_modification_greater_than    = rule.value.tier_to_cool_after_days
            tier_to_archive_after_days_since_modification_greater_than = rule.value.tier_to_archive_after_days
            delete_after_days_since_modification_greater_than          = rule.value.delete_after_days
          }
        }
        dynamic "snapshot" {
          for_each = rule.value.snapshot_delete_after_days != null ? [1] : []
          content {
            delete_after_days_since_creation_greater_than = rule.value.snapshot_delete_after_days
          }
        }
        dynamic "version" {
          for_each = rule.value.version_delete_after_days != null ? [1] : []
          content {
            delete_after_days_since_creation = rule.value.version_delete_after_days
          }
        }
      }
    }
  }
}


