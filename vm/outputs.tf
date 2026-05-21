output "vm_id" {
  description = "The ID of the Virtual Machine."
  value       = azurerm_linux_virtual_machine.this.id
}

output "vm_name" {
  description = "The name of the Virtual Machine."
  value       = azurerm_linux_virtual_machine.this.name
}

output "vm_private_ip" {
  description = "Private IP address of the VM."
  value       = azurerm_network_interface.this.private_ip_address
  sensitive   = true
}

output "vm_identity_principal_id" {
  description = "Principal ID of the VM's system-assigned managed identity."
  value       = azurerm_linux_virtual_machine.this.identity[0].principal_id
}

output "vm_availability_zone" {
  description = "Availability zone the VM is deployed in."
  value       = azurerm_linux_virtual_machine.this.zone
}

output "nic_id" {
  description = "The ID of the Network Interface."
  value       = azurerm_network_interface.this.id
}

output "data_disk_ids" {
  description = "Map of data disk names to their IDs."
  value       = { for k, v in azurerm_managed_disk.this : k => v.id }
}

output "ssh_private_key" {
  description = "SSH private key for Key Vault storage only. Never expose in logs."
  value       = tls_private_key.this.private_key_pem
  sensitive   = true
}
