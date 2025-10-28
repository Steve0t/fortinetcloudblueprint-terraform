#####################################################################
# Required Variables (prompted during deployment)
#####################################################################

variable "admin_username" {
  description = "Username for the FortiGate VM"
  type        = string
}

variable "admin_password" {
  description = "Password for the FortiGate VM"
  type        = string
  sensitive   = true
}

variable "deployment_prefix" {
  description = "Naming prefix for all deployed resources"
  type        = string
}

#####################################################################
# Deployment Control Variables
#####################################################################

variable "deploy_fortiweb" {
  description = "Deploy FortiWeb WAF cluster"
  type        = bool
  default     = true
}

variable "deploy_dvwa" {
  description = "Deploy DVWA workload instance as part of this template"
  type        = bool
  default     = true
}

#####################################################################
# Location and Tagging
#####################################################################

variable "location" {
  description = "Azure region for deployment"
  type        = string
  default     = ""
}

variable "fortinet_tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    publisher = "Fortinet"
    template  = "Canadian Fortinet Architecture Blueprint"
  }
}

#####################################################################
# Network Configuration
#####################################################################

variable "vnet_name" {
  description = "Name of the Azure virtual network (leave empty to use deployment_prefix-vnet)"
  type        = string
  default     = ""
}

variable "vnet_address_prefix" {
  description = "Virtual Network Address prefix"
  type        = string
  default     = "10.0.0.0/16"
}

#####################################################################
# Structured Subnet Configuration (Recommended)
#####################################################################

variable "subnets" {
  description = "Subnet configurations for the Azure deployment. Each subnet requires name, address_prefix, start_address, required_ip_count, and purpose."
  type = map(object({
    name              = string
    address_prefix    = string
    start_address     = string
    required_ip_count = number
    purpose           = string
  }))

  default = {
    fortigate_external = {
      name              = "FGExternal"
      address_prefix    = "10.0.1.0/24"
      start_address     = "10.0.1.4"
      required_ip_count = 2 # FortiGate A + B
      purpose           = "FortiGate external-facing interfaces (port1)"
    }

    fortigate_internal = {
      name              = "FGInternal"
      address_prefix    = "10.0.2.0/24"
      start_address     = "10.0.2.4"
      required_ip_count = 3 # Internal LB + FortiGate A + B
      purpose           = "FortiGate internal-facing interfaces (port2)"
    }

    fortigate_ha = {
      name              = "FGHA"
      address_prefix    = "10.0.3.0/24"
      start_address     = "10.0.3.4"
      required_ip_count = 2 # FortiGate A + B
      purpose           = "FortiGate HA synchronization (port3)"
    }

    fortigate_management = {
      name              = "FGMgmt"
      address_prefix    = "10.0.4.0/24"
      start_address     = "10.0.4.4"
      required_ip_count = 2 # FortiGate A + B
      purpose           = "FortiGate management interfaces (port4)"
    }

    fortiweb_external = {
      name              = "FWBExternal"
      address_prefix    = "10.0.5.0/24"
      start_address     = "10.0.5.4"
      required_ip_count = 3 # Internal LB + FortiWeb A + B
      purpose           = "FortiWeb external-facing interfaces (port1)"
    }

    fortiweb_internal = {
      name              = "FWBInternal"
      address_prefix    = "10.0.6.0/24"
      start_address     = "10.0.6.4"
      required_ip_count = 2 # FortiWeb A + B
      purpose           = "FortiWeb internal-facing interfaces (port2)"
    }

    workload = {
      name              = "DMZProtectedA"
      address_prefix    = "10.0.10.0/24"
      start_address     = "10.0.10.4"
      required_ip_count = 1 # Workload VM
      purpose           = "Protected workload subnet"
    }
  }

  validation {
    condition = alltrue([
      for k, v in var.subnets :
      can(cidrnetmask(v.address_prefix))
    ])
    error_message = "All address_prefix values must be valid CIDR blocks"
  }

  validation {
    condition = alltrue([
      for k, v in var.subnets :
      can(regex("^\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}$", v.start_address))
    ])
    error_message = "All start_address values must be valid IPv4 addresses"
  }

  validation {
    condition = alltrue([
      for k, v in var.subnets :
      v.required_ip_count > 0 && v.required_ip_count < 256
    ])
    error_message = "required_ip_count must be between 1 and 255"
  }
}

variable "on_prem_range" {
  description = "Define the IP address range of your on-premise network (leave empty to skip on-prem route)"
  type        = string
  default     = ""
}

#####################################################################
# FortiGate Configuration
#####################################################################

variable "fortigate_image_sku" {
  description = "FortiGate license model (BYOL or PAYG)"
  type        = string
  default     = "fortinet_fg-vm_payg_2023_g2"
  validation {
    condition     = contains(["fortinet_fg-vm_g2", "fortinet_fg-vm_payg_2023_g2"], var.fortigate_image_sku)
    error_message = "fortigate_image_sku must be either 'fortinet_fg-vm_g2' or 'fortinet_fg-vm_payg_2023_g2'"
  }
}

variable "fortigate_image_version" {
  description = "FortiGate image version"
  type        = string
  default     = "latest"
  validation {
    condition     = contains(["6.4.12", "7.0.12", "7.2.5", "latest"], var.fortigate_image_version)
    error_message = "fortigate_image_version must be one of: 6.4.12, 7.0.12, 7.2.5, latest"
  }
}

variable "fortigate_additional_custom_data" {
  description = "Additional FortiGate configuration"
  type        = string
  default     = ""
}

variable "instance_type" {
  description = "Virtual Machine size selection"
  type        = string
  default     = "Standard_F4s"
}

variable "availability_options" {
  description = "Availability Set or Availability Zones"
  type        = string
  default     = "Availability Set"
  validation {
    condition     = contains(["Availability Set", "Availability Zones"], var.availability_options)
    error_message = "availability_options must be either 'Availability Set' or 'Availability Zones'"
  }
}

variable "accelerated_networking" {
  description = "Enable accelerated networking"
  type        = bool
  default     = true
}

variable "fortigate_lb_public_ip_name" {
  description = "Name of FortiGate Load Balancer Public IP (leave empty to use deployment_prefix-fgt-pip)"
  type        = string
  default     = ""
}

variable "fortigate_a_mgmt_public_ip_name" {
  description = "Name of FortiGate A Management Public IP (leave empty to use deployment_prefix-fgt-a-mgmt-pip)"
  type        = string
  default     = ""
}

variable "fortigate_b_mgmt_public_ip_name" {
  description = "Name of FortiGate B Management Public IP (leave empty to use deployment_prefix-fgt-b-mgmt-pip)"
  type        = string
  default     = ""
}

variable "enable_fortigate_mgmt_public_ips" {
  description = "Create public IPs for FortiGate management interfaces"
  type        = bool
  default     = true
}

variable "my_public_ip" {
  description = "Your public IP address for NSG rules (CIDR format, e.g., 1.2.3.4/32). Leave empty to auto-detect."
  type        = string
  default     = ""
}

variable "fortigate_serial_console_enabled" {
  description = "Enable Serial Console on FortiGates"
  type        = bool
  default     = true
}

variable "fortimanager" {
  description = "Connect to FortiManager"
  type        = bool
  default     = false
}

variable "fortimanager_ip" {
  description = "FortiManager IP or DNS name"
  type        = string
  default     = ""
}

variable "fortimanager_serial" {
  description = "FortiManager serial number"
  type        = string
  default     = ""
}

variable "fortigate_license_byol_a" {
  description = "Primary FortiGate BYOL license content"
  type        = string
  default     = ""
  sensitive   = true
}

variable "fortigate_license_byol_b" {
  description = "Secondary FortiGate BYOL license content"
  type        = string
  default     = ""
  sensitive   = true
}

variable "fortigate_license_flexvm_a" {
  description = "Primary FortiGate BYOL Flex-VM license token"
  type        = string
  default     = ""
  sensitive   = true
}

variable "fortigate_license_flexvm_b" {
  description = "Secondary FortiGate BYOL Flex-VM license token"
  type        = string
  default     = ""
  sensitive   = true
}

#####################################################################
# FortiWeb Configuration
#####################################################################

variable "fortiweb_image_sku" {
  description = "FortiWeb license model (PAYG only for now)"
  type        = string
  default     = "fortinet_fw-vm_payg_v2"
  validation {
    condition     = contains(["fortinet_fw-vm_payg_v2"], var.fortiweb_image_sku)
    error_message = "fortiweb_image_sku must be 'fortinet_fw-vm_payg_v2'"
  }
}

variable "fortiweb_image_version" {
  description = "FortiWeb image version"
  type        = string
  default     = "latest"
  validation {
    condition     = contains(["6.3.17", "7.0.0", "7.0.3", "7.2.0", "latest"], var.fortiweb_image_version)
    error_message = "fortiweb_image_version must be one of: 6.3.17, 7.0.0, 7.0.3, 7.2.0, latest"
  }
}

variable "fortiweb_ha_group_id" {
  description = "FortiWeb HA group ID (0-63)"
  type        = number
  default     = 1
  validation {
    condition     = var.fortiweb_ha_group_id >= 0 && var.fortiweb_ha_group_id <= 63
    error_message = "fortiweb_ha_group_id must be between 0 and 63"
  }
}

variable "fortiweb_a_additional_custom_data" {
  description = "Additional FortiWeb A configuration"
  type        = string
  default     = ""
}

variable "fortiweb_b_additional_custom_data" {
  description = "Additional FortiWeb B configuration"
  type        = string
  default     = ""
}

variable "fortiweb_a_license_fortiflex" {
  description = "FortiFlex Token for FortiWeb-A"
  type        = string
  default     = ""
  sensitive   = true
}

variable "fortiweb_b_license_fortiflex" {
  description = "FortiFlex Token for FortiWeb-B"
  type        = string
  default     = ""
  sensitive   = true
}

variable "fortiweb_public_ip_name" {
  description = "Name of FortiWeb Load Balancer Public IP"
  type        = string
  default     = "FWBAPClusterPublicIP"
}

variable "fortiweb_serial_console_enabled" {
  description = "Enable Serial Console on FortiWeb"
  type        = bool
  default     = true
}

#####################################################################
# Workload Configuration
#####################################################################

variable "workload_serial_console_enabled" {
  description = "Enable Serial Console on workload VM"
  type        = bool
  default     = true
}

#####################################################################
# Output Control
#####################################################################

variable "debug_outputs" {
  description = "Enable verbose debug outputs showing full resource details (subnets, NICs, NSGs, etc.). User-friendly connection information is always displayed regardless of this setting."
  type        = bool
  default     = false
}

#####################################################################
# Network Service Ports
#####################################################################

variable "port_ssh" {
  description = "SSH port for remote access"
  type        = number
  default     = 22

  validation {
    condition     = var.port_ssh > 0 && var.port_ssh <= 65535
    error_message = "SSH port must be between 1 and 65535"
  }
}

variable "port_http" {
  description = "HTTP port for web traffic"
  type        = number
  default     = 80

  validation {
    condition     = var.port_http > 0 && var.port_http <= 65535
    error_message = "HTTP port must be between 1 and 65535"
  }
}

variable "port_https" {
  description = "HTTPS port for secure web traffic"
  type        = number
  default     = 443

  validation {
    condition     = var.port_https > 0 && var.port_https <= 65535
    error_message = "HTTPS port must be between 1 and 65535"
  }
}

variable "port_syslog" {
  description = "Syslog port for FortiManager device registration"
  type        = number
  default     = 514

  validation {
    condition     = var.port_syslog > 0 && var.port_syslog <= 65535
    error_message = "Syslog port must be between 1 and 65535"
  }
}

#####################################################################
# Health Probe Ports
#####################################################################

variable "fortigate_probe_port" {
  description = "FortiGate health probe port for Azure Load Balancer"
  type        = number
  default     = 8008

  validation {
    condition     = var.fortigate_probe_port > 0 && var.fortigate_probe_port <= 65535
    error_message = "FortiGate probe port must be between 1 and 65535"
  }
}

variable "fortiweb_http_probe_port" {
  description = "FortiWeb HTTP management interface port for health probes"
  type        = number
  default     = 8080

  validation {
    condition     = var.fortiweb_http_probe_port > 0 && var.fortiweb_http_probe_port <= 65535
    error_message = "FortiWeb HTTP probe port must be between 1 and 65535"
  }
}

variable "fortiweb_https_probe_port" {
  description = "FortiWeb HTTPS management interface port for health probes"
  type        = number
  default     = 8443

  validation {
    condition     = var.fortiweb_https_probe_port > 0 && var.fortiweb_https_probe_port <= 65535
    error_message = "FortiWeb HTTPS probe port must be between 1 and 65535"
  }
}

#####################################################################
# Azure Infrastructure Constants
#####################################################################

variable "azure_metadata_ip" {
  description = "Azure Wire Server / Metadata Service IP for health probes and instance metadata (well-known Azure address)"
  type        = string
  default     = "168.63.129.16"

  validation {
    condition     = can(regex("^\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}$", var.azure_metadata_ip))
    error_message = "Azure metadata IP must be a valid IPv4 address"
  }
}
