###############################################################################
# Terraform Outputs
#
# Centralized output definitions for all resources.
# Outputs are conditionally displayed based on var.enable_output flag.
#
# Organization:
# 1. Resource Groups
# 2. Networking (VNets, Subnets, NSGs, Routes)
# 3. Public IPs
# 4. Load Balancers
# 5. Network Interfaces
# 6. Virtual Machines (via linux_virtual_machine resource)
# 7. User-Friendly Connection Information
###############################################################################

###############################################################################
# Resource Groups
###############################################################################

output "resource_groups" {
  description = "Resource group details"
  value       = var.enable_output ? azurerm_resource_group.resource_group[*] : null
}

###############################################################################
# Networking Resources
###############################################################################

output "virtual_networks" {
  description = "Virtual network details"
  value       = var.enable_output ? azurerm_virtual_network.virtual_network[*] : null
}

output "subnets" {
  description = "Subnet details"
  value       = var.enable_output ? azurerm_subnet.subnet[*] : null
}

output "network_security_groups" {
  description = "Network security group details"
  value       = var.enable_output ? azurerm_network_security_group.network_security_group[*] : null
}

output "route_tables" {
  description = "Route table details"
  value       = var.enable_output ? azurerm_route_table.route_table[*] : null
}

output "routes" {
  description = "Route details"
  value       = var.enable_output ? azurerm_route.route[*] : null
}

output "subnet_route_table_associations" {
  description = "Subnet to route table association details"
  value       = var.enable_output ? azurerm_subnet_route_table_association.subnet_route_table_association[*] : null
}

###############################################################################
# Public IPs
###############################################################################

output "public_ips" {
  description = "All public IP details"
  value       = var.enable_output ? azurerm_public_ip.public_ip[*] : null
}

output "fortigate_public_ip" {
  description = "FortiGate cluster public IP address"
  value       = azurerm_public_ip.public_ip["${var.deployment_prefix}-fgt-pip"].ip_address
}

output "fortigate_management_ips" {
  description = "FortiGate management public IP addresses (if enabled)"
  value = var.enable_fortigate_mgmt_public_ips ? {
    fortigate_a = azurerm_public_ip.public_ip["${var.deployment_prefix}-fgt-a-mgmt-pip"].ip_address
    fortigate_b = azurerm_public_ip.public_ip["${var.deployment_prefix}-fgt-b-mgmt-pip"].ip_address
  } : null
}

output "fortiweb_public_ip" {
  description = "FortiWeb cluster public IP address (if deployed)"
  value       = var.deploy_fortiweb ? azurerm_public_ip.public_ip["${var.deployment_prefix}-fwb-pip"].ip_address : null
}

###############################################################################
# Load Balancers
###############################################################################

output "load_balancers" {
  description = "Load balancer details"
  value       = var.enable_output ? azurerm_lb.load_balancer[*] : null
}

output "fortigate_internal_lb_ip" {
  description = "FortiGate internal load balancer frontend IP"
  value       = azurerm_lb.load_balancer["${var.deployment_prefix}-internal-lb"].frontend_ip_configuration[0].private_ip_address
}

output "fortiweb_external_lb_ip" {
  description = "FortiWeb external load balancer public IP (if deployed)"
  value       = var.deploy_fortiweb ? azurerm_public_ip.public_ip["${var.deployment_prefix}-fwb-pip"].ip_address : null
}

###############################################################################
# Network Interfaces
###############################################################################

output "network_interfaces" {
  description = "Network interface details"
  value       = var.enable_output ? azurerm_network_interface.network_interface[*] : null
}

###############################################################################
# User-Friendly Connection Information
###############################################################################

output "connection_information" {
  description = "URLs and connection details for accessing deployed services"
  value = {
    fortigate = {
      public_ip    = azurerm_public_ip.public_ip["${var.deployment_prefix}-fgt-pip"].ip_address
      admin_user   = var.admin_username
      mgmt_a_ip    = var.enable_fortigate_mgmt_public_ips ? azurerm_public_ip.public_ip["${var.deployment_prefix}-fgt-a-mgmt-pip"].ip_address : "Not enabled"
      mgmt_b_ip    = var.enable_fortigate_mgmt_public_ips ? azurerm_public_ip.public_ip["${var.deployment_prefix}-fgt-b-mgmt-pip"].ip_address : "Not enabled"
      internal_lb  = azurerm_lb.load_balancer["${var.deployment_prefix}-internal-lb"].frontend_ip_configuration[0].private_ip_address
    }

    fortiweb = var.deploy_fortiweb ? {
      public_ip = azurerm_public_ip.public_ip["${var.deployment_prefix}-fwb-pip"].ip_address
      mgmt_fwb_a  = "https://${azurerm_public_ip.public_ip["${var.deployment_prefix}-fwb-pip"].ip_address}:40030"
      mgmt_fwb_b  = "https://${azurerm_public_ip.public_ip["${var.deployment_prefix}-fwb-pip"].ip_address}:40031"
      admin_user = var.admin_username
    } : null

    workload = var.deploy_dvwa ? {
      note = "Workload VM accessible through FortiWeb or FortiGate (no direct public IP)"
    } : null
  }
}

output "deployment_summary" {
  description = "Summary of deployed resources"
  value = {
    deployment_prefix    = var.deployment_prefix
    location             = local.location
    fortigate_deployed   = true
    fortiweb_deployed    = var.deploy_fortiweb
    workload_deployed    = var.deploy_dvwa
    fortigate_mgmt_ips   = var.enable_fortigate_mgmt_public_ips
    availability_option  = var.availability_options
  }
}
