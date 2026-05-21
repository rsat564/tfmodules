#--------------------------------------------------------------
# Azure Virtual Network Module
# Provisions a VNet with subnets, NSGs, route tables, and
# optional DDoS protection.
#--------------------------------------------------------------

resource "azurerm_virtual_network" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.address_space
  dns_servers         = length(var.dns_servers) > 0 ? var.dns_servers : null

  dynamic "ddos_protection_plan" {
    for_each = var.enable_ddos_protection ? [1] : []
    content {
      id     = var.create_ddos_protection_plan ? azurerm_network_ddos_protection_plan.this[0].id : var.ddos_protection_plan_id
      enable = true
    }
  }

  tags = var.tags
}

#--------------------------------------------------------------
# DDoS Protection Plan (Optional)
#--------------------------------------------------------------

resource "azurerm_network_ddos_protection_plan" "this" {
  count = var.enable_ddos_protection && var.create_ddos_protection_plan ? 1 : 0

  name                = "${var.name}-ddos-plan"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

#--------------------------------------------------------------
# Subnets
#--------------------------------------------------------------

resource "azurerm_subnet" "this" {
  for_each = var.subnets

  name                                           = each.key
  resource_group_name                            = var.resource_group_name
  virtual_network_name                           = azurerm_virtual_network.this.name
  address_prefixes                               = each.value.address_prefixes
  service_endpoints                              = each.value.service_endpoints
  private_endpoint_network_policies              = each.value.private_endpoint_network_policies_enabled ? "Enabled" : "Disabled"
  private_link_service_network_policies_enabled  = each.value.private_link_service_network_policies_enabled

  dynamic "delegation" {
    for_each = each.value.delegation != null ? [each.value.delegation] : []
    content {
      name = delegation.value.name
      service_delegation {
        name    = delegation.value.service_delegation.name
        actions = delegation.value.service_delegation.actions
      }
    }
  }
}

#--------------------------------------------------------------
# Network Security Groups
#--------------------------------------------------------------

resource "azurerm_network_security_group" "this" {
  for_each = var.nsg_rules

  name                = "${var.name}-${each.key}-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_network_security_rule" "this" {
  for_each = { for item in flatten([
    for subnet_name, rules in var.nsg_rules : [
      for rule in rules : {
        key                        = "${subnet_name}-${rule.name}"
        subnet_name                = subnet_name
        name                       = rule.name
        priority                   = rule.priority
        direction                  = rule.direction
        access                     = rule.access
        protocol                   = rule.protocol
        source_port_range          = rule.source_port_range
        destination_port_range     = rule.destination_port_range
        source_address_prefix      = rule.source_address_prefix
        destination_address_prefix = rule.destination_address_prefix
      }
    ]
  ]) : item.key => item }

  name                        = each.value.name
  priority                    = each.value.priority
  direction                   = each.value.direction
  access                      = each.value.access
  protocol                    = each.value.protocol
  source_port_range           = each.value.source_port_range
  destination_port_range      = each.value.destination_port_range
  source_address_prefix       = each.value.source_address_prefix
  destination_address_prefix  = each.value.destination_address_prefix
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.this[each.value.subnet_name].name
}

#--------------------------------------------------------------
# NSG to Subnet Association
#--------------------------------------------------------------

resource "azurerm_subnet_network_security_group_association" "this" {
  for_each = var.nsg_rules

  subnet_id                 = azurerm_subnet.this[each.key].id
  network_security_group_id = azurerm_network_security_group.this[each.key].id
}

#--------------------------------------------------------------
# Route Tables
#--------------------------------------------------------------

resource "azurerm_route_table" "this" {
  for_each = var.route_tables

  name                          = "${var.name}-${each.key}-rt"
  location                      = var.location
  resource_group_name           = var.resource_group_name
  bgp_route_propagation_enabled = !each.value.disable_bgp_route_propagation
  tags                          = var.tags
}

resource "azurerm_route" "this" {
  for_each = { for item in flatten([
    for subnet_name, rt in var.route_tables : [
      for route in rt.routes : {
        key                    = "${subnet_name}-${route.name}"
        subnet_name            = subnet_name
        name                   = route.name
        address_prefix         = route.address_prefix
        next_hop_type          = route.next_hop_type
        next_hop_in_ip_address = route.next_hop_in_ip_address
      }
    ]
  ]) : item.key => item }

  name                   = each.value.name
  resource_group_name    = var.resource_group_name
  route_table_name       = azurerm_route_table.this[each.value.subnet_name].name
  address_prefix         = each.value.address_prefix
  next_hop_type          = each.value.next_hop_type
  next_hop_in_ip_address = each.value.next_hop_in_ip_address
}

#--------------------------------------------------------------
# Route Table to Subnet Association
#--------------------------------------------------------------

resource "azurerm_subnet_route_table_association" "this" {
  for_each = var.route_tables

  subnet_id      = azurerm_subnet.this[each.key].id
  route_table_id = azurerm_route_table.this[each.key].id
}
