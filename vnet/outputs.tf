output "vnet_id" {
  description = "The ID of the Virtual Network."
  value       = azurerm_virtual_network.this.id
}

output "vnet_name" {
  description = "The name of the Virtual Network."
  value       = azurerm_virtual_network.this.name
}

output "vnet_address_space" {
  description = "The address space of the Virtual Network."
  value       = azurerm_virtual_network.this.address_space
}

output "vnet_location" {
  description = "The location/region of the Virtual Network."
  value       = azurerm_virtual_network.this.location
}

output "subnet_ids" {
  description = "Map of subnet names to their IDs."
  value       = { for k, v in azurerm_subnet.this : k => v.id }
}

output "subnet_address_prefixes" {
  description = "Map of subnet names to their address prefixes."
  value       = { for k, v in azurerm_subnet.this : k => v.address_prefixes }
}

output "nsg_ids" {
  description = "Map of NSG names (by subnet) to their IDs."
  value       = { for k, v in azurerm_network_security_group.this : k => v.id }
}

output "route_table_ids" {
  description = "Map of route table names (by subnet) to their IDs."
  value       = { for k, v in azurerm_route_table.this : k => v.id }
}

output "ddos_protection_plan_id" {
  description = "The ID of the DDoS Protection Plan, if created."
  value       = var.enable_ddos_protection && var.create_ddos_protection_plan ? azurerm_network_ddos_protection_plan.this[0].id : null
}
