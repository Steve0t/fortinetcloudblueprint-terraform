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

variable "deploy_dvwa" {
  description = "Deploy DVWA Instance as part of this template (yes/no)"
  type        = string
  default     = "yes"
  validation {
    condition     = contains(["yes", "no"], var.deploy_dvwa)
    error_message = "deploy_dvwa must be either 'yes' or 'no'"
  }
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

variable "subnet1_name" {
  description = "Subnet 1 Name (FortiGate External)"
  type        = string
  default     = "FGExternal"
}

variable "subnet1_prefix" {
  description = "Subnet 1 Prefix"
  type        = string
  default     = "10.0.1.0/24"
}

variable "subnet1_start_address" {
  description = "Subnet 1 start address, 2 consecutive private IPs are required"
  type        = string
  default     = "10.0.1.5"
}

variable "subnet2_name" {
  description = "Subnet 2 Name (FortiGate Internal)"
  type        = string
  default     = "FGInternal"
}

variable "subnet2_prefix" {
  description = "Subnet 2 Prefix"
  type        = string
  default     = "10.0.2.0/24"
}

variable "subnet2_start_address" {
  description = "Subnet 2 start address, 3 consecutive private IPs are required"
  type        = string
  default     = "10.0.2.4"
}

variable "subnet3_name" {
  description = "Subnet 3 Name (FortiGate HA)"
  type        = string
  default     = "FGHA"
}

variable "subnet3_prefix" {
  description = "Subnet 3 Prefix"
  type        = string
  default     = "10.0.3.0/24"
}

variable "subnet3_start_address" {
  description = "Subnet 3 start address, 2 consecutive private IPs are required"
  type        = string
  default     = "10.0.3.5"
}

variable "subnet4_name" {
  description = "Subnet 4 Name (FortiGate Management)"
  type        = string
  default     = "FGMgmt"
}

variable "subnet4_prefix" {
  description = "Subnet 4 Prefix"
  type        = string
  default     = "10.0.4.0/24"
}

variable "subnet4_start_address" {
  description = "Subnet 4 start address, 2 consecutive private IPs are required"
  type        = string
  default     = "10.0.4.5"
}

variable "subnet5_name" {
  description = "Subnet 5 Name (FortiWeb External)"
  type        = string
  default     = "FWBExternal"
}

variable "subnet5_prefix" {
  description = "Subnet 5 Prefix"
  type        = string
  default     = "10.0.5.0/24"
}

variable "subnet5_start_address" {
  description = "Subnet 5 start address, 3 consecutive private IPs are required"
  type        = string
  default     = "10.0.5.5"
}

variable "subnet6_name" {
  description = "Subnet 6 Name (FortiWeb Internal)"
  type        = string
  default     = "FWBInternal"
}

variable "subnet6_prefix" {
  description = "Subnet 6 Prefix"
  type        = string
  default     = "10.0.6.0/24"
}

variable "subnet6_start_address" {
  description = "Subnet 6 start address, 2 consecutive private IPs are required"
  type        = string
  default     = "10.0.6.4"
}

variable "subnet7_name" {
  description = "Subnet 7 Name (DMZ Protected)"
  type        = string
  default     = "DMZProtectedA"
}

variable "subnet7_prefix" {
  description = "Subnet 7 Prefix"
  type        = string
  default     = "10.0.10.0/24"
}

variable "subnet7_start_address" {
  description = "Subnet 7 start address, 1 consecutive private IP is required"
  type        = string
  default     = "10.0.10.7"
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
  default     = "fortinet_fg-vm_payg_2022"
  validation {
    condition     = contains(["fortinet_fg-vm", "fortinet_fg-vm_payg_2022"], var.fortigate_image_sku)
    error_message = "fortigate_image_sku must be either 'fortinet_fg-vm' or 'fortinet_fg-vm_payg_2022'"
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

variable "public_ip1_name" {
  description = "Name of FortiGate Load Balancer Public IP (leave empty to use deployment_prefix-fgt-pip)"
  type        = string
  default     = ""
}

variable "public_ip2_name" {
  description = "Name of FortiGate A Management Public IP (leave empty to use deployment_prefix-fgt-a-mgmt-pip)"
  type        = string
  default     = ""
}

variable "public_ip3_name" {
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

variable "fgt_serial_console" {
  description = "Enable Serial Console on FortiGates"
  type        = string
  default     = "yes"
  validation {
    condition     = contains(["yes", "no"], var.fgt_serial_console)
    error_message = "fgt_serial_console must be either 'yes' or 'no'"
  }
}

variable "fortimanager" {
  description = "Connect to FortiManager"
  type        = string
  default     = "no"
  validation {
    condition     = contains(["yes", "no"], var.fortimanager)
    error_message = "fortimanager must be either 'yes' or 'no'"
  }
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
  description = "FortiWeb license model (BYOL or PAYG)"
  type        = string
  default     = "fortinet_fw-vm_payg_v2"
  validation {
    condition     = contains(["fortinet_fw-vm", "fortinet_fw-vm_payg_v2"], var.fortiweb_image_sku)
    error_message = "fortiweb_image_sku must be either 'fortinet_fw-vm' or 'fortinet_fw-vm_payg_v2'"
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

variable "fwb_serial_console" {
  description = "Enable Serial Console on FortiWeb"
  type        = string
  default     = "yes"
  validation {
    condition     = contains(["yes", "no"], var.fwb_serial_console)
    error_message = "fwb_serial_console must be either 'yes' or 'no'"
  }
}

#####################################################################
# DVWA Configuration
#####################################################################

variable "dvwa_serial_console" {
  description = "Enable Serial Console on DVWA"
  type        = string
  default     = "yes"
  validation {
    condition     = contains(["yes", "no"], var.dvwa_serial_console)
    error_message = "dvwa_serial_console must be either 'yes' or 'no'"
  }
}

#####################################################################
# Output Control
#####################################################################

variable "enable_output" {
  description = "Enable/Disable detailed outputs"
  type        = bool
  default     = false
}
