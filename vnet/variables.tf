variable "name" {
  description = "The name of the Virtual Network."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9-_.]{0,62}[a-zA-Z0-9]$", var.name))
    error_message = "VNet name must be 2-64 characters, start and end with alphanumeric, and contain only alphanumeric, hyphens, underscores, or periods."
  }
}

variable "resource_group_name" {
  description = "The name of the resource group in which the VNet will be created."
  type        = string

  validation {
    condition     = length(var.resource_group_name) > 0 && length(var.resource_group_name) <= 90
    error_message = "Resource group name must be between 1 and 90 characters."
  }
}

variable "location" {
  description = "The Azure region where the VNet will be deployed."
  type        = string

  validation {
    condition     = length(var.location) > 0
    error_message = "Location must not be empty."
  }
}

variable "address_space" {
  description = "List of address spaces (CIDR blocks) for the VNet."
  type        = list(string)

  validation {
    condition     = length(var.address_space) > 0
    error_message = "At least one address space must be specified."
  }

  validation {
    condition     = alltrue([for cidr in var.address_space : can(cidrhost(cidr, 0))])
    error_message = "All address spaces must be valid CIDR blocks."
  }
}

variable "dns_servers" {
  description = "List of custom DNS server IP addresses. If empty, Azure-provided DNS will be used."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for ip in var.dns_servers : can(regex("^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$", ip))])
    error_message = "All DNS server entries must be valid IPv4 addresses."
  }
}

variable "subnets" {
  description = <<-EOT
    Map of subnet configurations. Each subnet can have:
    - address_prefixes: List of CIDR blocks for the subnet
    - service_endpoints: Optional list of service endpoints (e.g., Microsoft.Storage)
    - delegation: Optional service delegation configuration
    - private_endpoint_network_policies_enabled: Enable/disable network policies for private endpoints
    - private_link_service_network_policies_enabled: Enable/disable network policies for private link services
  EOT
  type = map(object({
    address_prefixes  = list(string)
    service_endpoints = optional(list(string), [])
    delegation = optional(object({
      name = string
      service_delegation = object({
        name    = string
        actions = optional(list(string), [])
      })
    }), null)
    private_endpoint_network_policies_enabled     = optional(bool, true)
    private_link_service_network_policies_enabled = optional(bool, true)
  }))
  default = {}

  validation {
    condition     = alltrue([for k, v in var.subnets : length(v.address_prefixes) > 0])
    error_message = "Each subnet must have at least one address prefix."
  }
}

variable "nsg_rules" {
  description = <<-EOT
    Map of Network Security Group rules to apply to subnets.
    Key is the subnet name, value is a list of NSG rules.
  EOT
  type = map(list(object({
    name                       = string
    priority                   = number
    direction                  = string
    access                     = string
    protocol                   = string
    source_port_range          = optional(string, "*")
    destination_port_range     = optional(string, "*")
    source_address_prefix      = optional(string, "*")
    destination_address_prefix = optional(string, "*")
  })))
  default = {}

  validation {
    condition = alltrue(flatten([
      for subnet, rules in var.nsg_rules : [
        for rule in rules : rule.priority >= 100 && rule.priority <= 4096
      ]
    ]))
    error_message = "NSG rule priorities must be between 100 and 4096."
  }

  validation {
    condition = alltrue(flatten([
      for subnet, rules in var.nsg_rules : [
        for rule in rules : contains(["Inbound", "Outbound"], rule.direction)
      ]
    ]))
    error_message = "NSG rule direction must be either 'Inbound' or 'Outbound'."
  }

  validation {
    condition = alltrue(flatten([
      for subnet, rules in var.nsg_rules : [
        for rule in rules : contains(["Allow", "Deny"], rule.access)
      ]
    ]))
    error_message = "NSG rule access must be either 'Allow' or 'Deny'."
  }
}

variable "route_tables" {
  description = <<-EOT
    Map of route table configurations per subnet.
    Key is the subnet name, value contains routes and settings.
  EOT
  type = map(object({
    disable_bgp_route_propagation = optional(bool, false)
    routes = list(object({
      name                   = string
      address_prefix         = string
      next_hop_type          = string
      next_hop_in_ip_address = optional(string, null)
    }))
  }))
  default = {}

  validation {
    condition = alltrue(flatten([
      for subnet, rt in var.route_tables : [
        for route in rt.routes : contains(
          ["VirtualNetworkGateway", "VnetLocal", "Internet", "VirtualAppliance", "None"],
          route.next_hop_type
        )
      ]
    ]))
    error_message = "Route next_hop_type must be one of: VirtualNetworkGateway, VnetLocal, Internet, VirtualAppliance, None."
  }
}

variable "enable_ddos_protection" {
  description = "Enable DDoS Protection Plan for the VNet. Note: This incurs additional cost."
  type        = bool
  default     = false
}

variable "ddos_protection_plan_id" {
  description = "ID of an existing DDoS Protection Plan. Required if enable_ddos_protection is true and create_ddos_protection_plan is false."
  type        = string
  default     = null
}

variable "create_ddos_protection_plan" {
  description = "Create a new DDoS Protection Plan. Only used if enable_ddos_protection is true."
  type        = bool
  default     = false
}

variable "enable_flow_logs" {
  description = "Enable NSG Flow Logs for network traffic analysis."
  type        = bool
  default     = false
}

variable "flow_log_storage_account_id" {
  description = "Storage Account ID for NSG Flow Logs. Required if enable_flow_logs is true."
  type        = string
  default     = null
}

variable "flow_log_retention_days" {
  description = "Number of days to retain flow log data."
  type        = number
  default     = 7

  validation {
    condition     = var.flow_log_retention_days >= 1 && var.flow_log_retention_days <= 365
    error_message = "Flow log retention days must be between 1 and 365."
  }
}

variable "tags" {
  description = "A map of tags to apply to all resources created by this module."
  type        = map(string)
  default     = {}

  validation {
    condition     = alltrue([for k, v in var.tags : length(k) <= 512 && length(v) <= 256])
    error_message = "Tag keys must be <= 512 characters and values <= 256 characters."
  }
}
