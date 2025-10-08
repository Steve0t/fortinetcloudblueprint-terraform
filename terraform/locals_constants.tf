#####################################################################
# Local Values (Computed/Derived Constants)
#
# This file contains local values that are derived or computed from other
# inputs, or represent true infrastructure constants that should never
# be customized by users.
#
# NOTE: User-customizable values (ports, IPs, etc.) have been moved to
# variables.tf as proper input variables with validation.
#####################################################################

locals {
  #############################################################################
  # Azure Availability Zones
  #############################################################################

  # Azure Availability Zones for high availability
  # Zone 1 is used for primary instances (FortiGate-A, FortiWeb-A)
  # Zone 2 is used for secondary instances (FortiGate-B, FortiWeb-B)
  availability_zone_1 = "1"
  availability_zone_2 = "2"
  availability_zone_3 = "3" # Reserved for future use

  #############################################################################
  # Storage Configuration
  #############################################################################

  # Standard Locally Redundant Storage
  # Provides local redundancy within a single data center
  # Suitable for:
  # - Non-critical workloads
  # - Development/testing environments
  # - VM OS disks
  # - Temporary data storage
  standard_lrs = "Standard_LRS"

  # Alternative storage types (uncomment if needed):
  # premium_lrs  = "Premium_LRS"   # Premium SSD with local redundancy
  # standard_grs = "Standard_GRS"  # Standard with geo-redundancy
  # premium_zrs  = "Premium_ZRS"   # Premium with zone redundancy

  #############################################################################
  # Fortinet Azure Marketplace Configuration
  #############################################################################

  # Publisher name in Azure Marketplace
  # All Fortinet products use this publisher identifier
  fortinet_publisher = "fortinet"

  # FortiGate VM marketplace identifiers
  # offer and product are typically the same for Azure marketplace
  fortigate_offer   = "fortinet_fortigate-vm_v5"
  fortigate_product = "fortinet_fortigate-vm_v5"

  # FortiWeb VM marketplace identifiers
  fortiweb_offer   = "fortinet_fortiweb-vm_v5"
  fortiweb_product = "fortinet_fortiweb-vm_v5"
}
