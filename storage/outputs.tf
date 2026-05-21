output "storage_account_id" {
  description = "The ID of the Storage Account."
  value       = azurerm_storage_account.this.id
}

output "storage_account_name" {
  description = "The name of the Storage Account."
  value       = azurerm_storage_account.this.name
}

output "primary_blob_endpoint" {
  description = "Primary blob service endpoint URL."
  value       = azurerm_storage_account.this.primary_blob_endpoint
}

output "identity_principal_id" {
  description = "Principal ID of the Storage Account's managed identity."
  value       = azurerm_storage_account.this.identity[0].principal_id
}

output "container_ids" {
  description = "Map of container names to their resource IDs."
  value       = { for k, v in azurerm_storage_container.this : k => v.id }
}
