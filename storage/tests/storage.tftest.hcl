provider "azurerm" {
  features {}
}

variables {
  name                = "sttest001abc"
  resource_group_name = "rg-test-eastus-001"
  location            = "eastus"
  account_tier        = "Standard"
  replication_type    = "ZRS"
  public_network_access = false

  containers = {
    "data" = {
      access_type = "private"
    }
    "logs" = {
      access_type = "private"
    }
  }

  lifecycle_rules = [
    {
      name                       = "archive-logs"
      prefix_match               = ["logs/"]
      tier_to_cool_after_days    = 30
      tier_to_archive_after_days = 90
      delete_after_days          = 365
    }
  ]

  tags = {
    Environment = "test"
    ManagedBy   = "terraform"
  }
}

run "storage_account_name" {
  command = plan

  assert {
    condition     = azurerm_storage_account.this.name == "sttest001abc"
    error_message = "Storage account name does not match."
  }
}

run "storage_replication" {
  command = plan

  assert {
    condition     = azurerm_storage_account.this.account_replication_type == "ZRS"
    error_message = "Replication type should be ZRS for high availability."
  }
}

run "storage_security_tls" {
  command = plan

  assert {
    condition     = azurerm_storage_account.this.min_tls_version == "TLS1_2"
    error_message = "TLS version must be 1.2 minimum."
  }
}

run "storage_security_no_public_blobs" {
  command = plan

  assert {
    condition     = azurerm_storage_account.this.allow_nested_items_to_be_public == false
    error_message = "Public blob access must be disabled."
  }
}

run "storage_security_no_shared_key" {
  command = plan

  assert {
    condition     = azurerm_storage_account.this.shared_access_key_enabled == false
    error_message = "Shared access key should be disabled for security."
  }
}

run "storage_https_only" {
  command = plan

  assert {
    condition     = azurerm_storage_account.this.https_traffic_only_enabled == true
    error_message = "HTTPS traffic only must be enabled."
  }
}

run "storage_network_deny_default" {
  command = plan

  assert {
    condition     = azurerm_storage_account.this.network_rules[0].default_action == "Deny"
    error_message = "Network default action must be Deny."
  }
}

run "containers_are_created" {
  command = plan

  assert {
    condition     = azurerm_storage_container.this["data"].name == "data"
    error_message = "Data container not created."
  }

  assert {
    condition     = azurerm_storage_container.this["logs"].name == "logs"
    error_message = "Logs container not created."
  }
}

run "tags_are_applied" {
  command = plan

  assert {
    condition     = azurerm_storage_account.this.tags["Environment"] == "test"
    error_message = "Tags not applied."
  }
}
