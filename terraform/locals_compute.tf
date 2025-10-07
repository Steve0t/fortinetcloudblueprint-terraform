#####################################################################
# Compute Resources - Central Merge Point
#
# This file merges all component-specific locals into final collections
# that are consumed by resource files.
#
# Components:
# - FortiGate (always deployed)
# - FortiWeb (conditional: var.deploy_fortiweb)
# - Workload (conditional: var.deploy_dvwa)
#####################################################################

locals {
  #####################################################################
  # Network Interfaces - Merged Collection
  #####################################################################

  network_interfaces = merge(
    local.network_interfaces_fortigate,
    local.network_interfaces_fortiweb,
    local.network_interfaces_workload
  )

  #####################################################################
  # Virtual Machines - Merged Collection
  #####################################################################

  virtual_machines = merge(
    local.virtual_machines_fortigate,
    local.virtual_machines_fortiweb,
    local.virtual_machines_workload
  )
}
