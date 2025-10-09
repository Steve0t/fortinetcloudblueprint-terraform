#####################################################################
# Load Balancer Locals
# FortiGate External and Internal Load Balancers
#####################################################################

locals {
  #####################################################################
  # Load Balancers
  #####################################################################

  load_balancers = merge(
    # FortiGate Load Balancers (always deployed)
    {
      # FortiGate Internal Load Balancer (Private)
      "${var.deployment_prefix}-internal-lb" = {
        name                = "${var.deployment_prefix}-FGT-ILB"
        location            = azurerm_resource_group.resource_group[local.resource_group_name].location
        resource_group_name = azurerm_resource_group.resource_group[local.resource_group_name].name
        sku                 = "Standard"
        tags                = var.fortinet_tags

        frontend_ip_configurations = [{
          name                          = "${var.deployment_prefix}-ILB-${var.subnets["fortigate_internal"].name}-FrontEnd"
          public_ip_address_id          = null
          subnet_id                     = azurerm_subnet.subnet["${var.deployment_prefix}-${var.subnets["fortigate_internal"].name}"].id
          private_ip_address            = var.subnets["fortigate_internal"].start_address
          private_ip_address_allocation = "Static"
        }]
      }

      # FortiGate External Load Balancer (Public)
      "${var.deployment_prefix}-external-lb" = {
        name                = "${var.deployment_prefix}-FGT-ELB"
        location            = azurerm_resource_group.resource_group[local.resource_group_name].location
        resource_group_name = azurerm_resource_group.resource_group[local.resource_group_name].name
        sku                 = "Standard"
        tags                = var.fortinet_tags

        frontend_ip_configurations = [{
          name                          = "${var.deployment_prefix}-ELB-${var.subnets["fortigate_external"].name}-FrontEnd"
          public_ip_address_id          = azurerm_public_ip.public_ip["${var.deployment_prefix}-fgt-pip"].id
          subnet_id                     = null
          private_ip_address            = null
          private_ip_address_allocation = "Dynamic"
        }]
      }
    },
    # FortiWeb Load Balancers (conditional)
    var.deploy_fortiweb ? {
      # FortiWeb Internal Load Balancer (Private)
      "${var.deployment_prefix}-fortiweb-internal-lb" = {
        name                = "${var.deployment_prefix}-FWB-ILB"
        location            = azurerm_resource_group.resource_group[local.resource_group_name].location
        resource_group_name = azurerm_resource_group.resource_group[local.resource_group_name].name
        sku                 = "Standard"
        tags                = var.fortinet_tags

        frontend_ip_configurations = [{
          name                          = "${var.deployment_prefix}-ILB-${var.subnets["fortiweb_external"].name}-FrontEnd"
          public_ip_address_id          = null
          subnet_id                     = azurerm_subnet.subnet["${var.deployment_prefix}-${var.subnets["fortiweb_external"].name}"].id
          private_ip_address            = var.subnets["fortiweb_external"].start_address
          private_ip_address_allocation = "Static"
        }]
      }

      # FortiWeb External Load Balancer (Public)
      "${var.deployment_prefix}-fortiweb-external-lb" = {
        name                = "${var.deployment_prefix}-FWB-ELB"
        location            = azurerm_resource_group.resource_group[local.resource_group_name].location
        resource_group_name = azurerm_resource_group.resource_group[local.resource_group_name].name
        sku                 = "Standard"
        tags                = var.fortinet_tags

        frontend_ip_configurations = [{
          name                          = "${var.deployment_prefix}-FWB-ELB-FrontEnd"
          public_ip_address_id          = azurerm_public_ip.public_ip["${var.deployment_prefix}-fwb-pip"].id
          subnet_id                     = null
          private_ip_address            = null
          private_ip_address_allocation = "Dynamic"
        }]
      }
    } : {}
  )

  #####################################################################
  # Load Balancer Backend Address Pools
  #####################################################################

  lb_backend_address_pools = merge(
    {
      "${var.deployment_prefix}-internal-lb-backend" = {
        name            = "${var.deployment_prefix}-ILB-${var.subnets["fortigate_internal"].name}-BackEnd"
        loadbalancer_id = azurerm_lb.load_balancer["${var.deployment_prefix}-internal-lb"].id
      }
      "${var.deployment_prefix}-external-lb-backend" = {
        name            = "${var.deployment_prefix}-ELB-${var.subnets["fortigate_external"].name}-BackEnd"
        loadbalancer_id = azurerm_lb.load_balancer["${var.deployment_prefix}-external-lb"].id
      }
    },
    var.deploy_fortiweb ? {
      "${var.deployment_prefix}-fortiweb-internal-lb-backend" = {
        name            = "${var.deployment_prefix}-ILB-${var.subnets["fortiweb_external"].name}-BackEnd"
        loadbalancer_id = azurerm_lb.load_balancer["${var.deployment_prefix}-fortiweb-internal-lb"].id
      }
      "${var.deployment_prefix}-fortiweb-external-lb-backend" = {
        name            = "${var.deployment_prefix}-FWB-ELB-BackEnd"
        loadbalancer_id = azurerm_lb.load_balancer["${var.deployment_prefix}-fortiweb-external-lb"].id
      }
    } : {}
  )

  #####################################################################
  # Load Balancer Probes
  #####################################################################

  lb_probes = merge(
    {
      "${var.deployment_prefix}-internal-lb-probe" = {
        name            = "lbprobe"
        loadbalancer_id = azurerm_lb.load_balancer["${var.deployment_prefix}-internal-lb"].id
        protocol        = "Tcp"
        port            = var.fortigate_probe_port
        interval        = 5
        probe_threshold = 2
      }
      "${var.deployment_prefix}-external-lb-probe" = {
        name            = "lbprobe"
        loadbalancer_id = azurerm_lb.load_balancer["${var.deployment_prefix}-external-lb"].id
        protocol        = "Tcp"
        port            = var.fortigate_probe_port
        interval        = 5
        probe_threshold = 2
      }
    },
    var.deploy_fortiweb ? {
      "${var.deployment_prefix}-fortiweb-internal-lb-probe" = {
        name            = "lbprobe"
        loadbalancer_id = azurerm_lb.load_balancer["${var.deployment_prefix}-fortiweb-internal-lb"].id
        protocol        = "Tcp"
        port            = var.fortiweb_http_probe_port
        interval        = 15
        probe_threshold = 2
      }
      "${var.deployment_prefix}-fortiweb-external-lb-probe-http" = {
        name            = "lbprobe-http"
        loadbalancer_id = azurerm_lb.load_balancer["${var.deployment_prefix}-fortiweb-external-lb"].id
        protocol        = "Tcp"
        port            = var.fortiweb_http_probe_port
        interval        = 15
        probe_threshold = 2
      }
      "${var.deployment_prefix}-fortiweb-external-lb-probe-https" = {
        name            = "lbprobe-https"
        loadbalancer_id = azurerm_lb.load_balancer["${var.deployment_prefix}-fortiweb-external-lb"].id
        protocol        = "Tcp"
        port            = var.fortiweb_https_probe_port
        interval        = 15
        probe_threshold = 2
      }
    } : {}
  )

  #####################################################################
  # Load Balancer Rules
  #####################################################################

  lb_rules = merge(
    # Internal LB Rule - HA All Ports
    {
      "${var.deployment_prefix}-internal-lb-rule-ha" = {
        name                           = "lbruleFEall"
        loadbalancer_id                = azurerm_lb.load_balancer["${var.deployment_prefix}-internal-lb"].id
        frontend_ip_configuration_name = "${var.deployment_prefix}-ILB-${var.subnets["fortigate_internal"].name}-FrontEnd"
        backend_address_pool_ids       = [azurerm_lb_backend_address_pool.lb_backend_address_pool["${var.deployment_prefix}-internal-lb-backend"].id]
        probe_id                       = azurerm_lb_probe.lb_probe["${var.deployment_prefix}-internal-lb-probe"].id
        protocol                       = "All"
        frontend_port                  = 0
        backend_port                   = 0
        enable_floating_ip             = true
        idle_timeout_in_minutes        = 5
      }
    },
    # External LB Rules - Workload Container Ports
    var.deploy_dvwa ? {
      "${var.deployment_prefix}-external-lb-rule-ssh" = {
        name                           = "ExternalLBRule-FE-ssh"
        loadbalancer_id                = azurerm_lb.load_balancer["${var.deployment_prefix}-external-lb"].id
        frontend_ip_configuration_name = "${var.deployment_prefix}-ELB-${var.subnets["fortigate_external"].name}-FrontEnd"
        backend_address_pool_ids       = [azurerm_lb_backend_address_pool.lb_backend_address_pool["${var.deployment_prefix}-external-lb-backend"].id]
        probe_id                       = azurerm_lb_probe.lb_probe["${var.deployment_prefix}-external-lb-probe"].id
        protocol                       = "Tcp"
        frontend_port                  = 2222
        backend_port                   = 2222
        enable_floating_ip             = true
        idle_timeout_in_minutes        = 5
      }
      "${var.deployment_prefix}-external-lb-rule-dvwa" = {
        name                           = "ExternalLBRule-FE-dvwa"
        loadbalancer_id                = azurerm_lb.load_balancer["${var.deployment_prefix}-external-lb"].id
        frontend_ip_configuration_name = "${var.deployment_prefix}-ELB-${var.subnets["fortigate_external"].name}-FrontEnd"
        backend_address_pool_ids       = [azurerm_lb_backend_address_pool.lb_backend_address_pool["${var.deployment_prefix}-external-lb-backend"].id]
        probe_id                       = azurerm_lb_probe.lb_probe["${var.deployment_prefix}-external-lb-probe"].id
        protocol                       = "Tcp"
        frontend_port                  = 8001
        backend_port                   = 8001
        enable_floating_ip             = true
        idle_timeout_in_minutes        = 5
      }
      "${var.deployment_prefix}-external-lb-rule-bank" = {
        name                           = "ExternalLBRule-FE-bank"
        loadbalancer_id                = azurerm_lb.load_balancer["${var.deployment_prefix}-external-lb"].id
        frontend_ip_configuration_name = "${var.deployment_prefix}-ELB-${var.subnets["fortigate_external"].name}-FrontEnd"
        backend_address_pool_ids       = [azurerm_lb_backend_address_pool.lb_backend_address_pool["${var.deployment_prefix}-external-lb-backend"].id]
        probe_id                       = azurerm_lb_probe.lb_probe["${var.deployment_prefix}-external-lb-probe"].id
        protocol                       = "Tcp"
        frontend_port                  = 8002
        backend_port                   = 8002
        enable_floating_ip             = true
        idle_timeout_in_minutes        = 5
      }
      "${var.deployment_prefix}-external-lb-rule-juice" = {
        name                           = "ExternalLBRule-FE-juice"
        loadbalancer_id                = azurerm_lb.load_balancer["${var.deployment_prefix}-external-lb"].id
        frontend_ip_configuration_name = "${var.deployment_prefix}-ELB-${var.subnets["fortigate_external"].name}-FrontEnd"
        backend_address_pool_ids       = [azurerm_lb_backend_address_pool.lb_backend_address_pool["${var.deployment_prefix}-external-lb-backend"].id]
        probe_id                       = azurerm_lb_probe.lb_probe["${var.deployment_prefix}-external-lb-probe"].id
        protocol                       = "Tcp"
        frontend_port                  = 8003
        backend_port                   = 8003
        enable_floating_ip             = true
        idle_timeout_in_minutes        = 5
      }
      "${var.deployment_prefix}-external-lb-rule-petstore" = {
        name                           = "ExternalLBRule-FE-petstore"
        loadbalancer_id                = azurerm_lb.load_balancer["${var.deployment_prefix}-external-lb"].id
        frontend_ip_configuration_name = "${var.deployment_prefix}-ELB-${var.subnets["fortigate_external"].name}-FrontEnd"
        backend_address_pool_ids       = [azurerm_lb_backend_address_pool.lb_backend_address_pool["${var.deployment_prefix}-external-lb-backend"].id]
        probe_id                       = azurerm_lb_probe.lb_probe["${var.deployment_prefix}-external-lb-probe"].id
        protocol                       = "Tcp"
        frontend_port                  = 8004
        backend_port                   = 8004
        enable_floating_ip             = true
        idle_timeout_in_minutes        = 5
      }
      "${var.deployment_prefix}-external-lb-rule-udp10551" = {
        name                           = "ExternalLBRule-FE-udp10551"
        loadbalancer_id                = azurerm_lb.load_balancer["${var.deployment_prefix}-external-lb"].id
        frontend_ip_configuration_name = "${var.deployment_prefix}-ELB-${var.subnets["fortigate_external"].name}-FrontEnd"
        backend_address_pool_ids       = [azurerm_lb_backend_address_pool.lb_backend_address_pool["${var.deployment_prefix}-external-lb-backend"].id]
        probe_id                       = azurerm_lb_probe.lb_probe["${var.deployment_prefix}-external-lb-probe"].id
        protocol                       = "Udp"
        frontend_port                  = 10551
        backend_port                   = 10551
        enable_floating_ip             = true
        idle_timeout_in_minutes        = 5
      }
    } : {},
    # FortiWeb Internal LB Rule - HA All Ports
    var.deploy_fortiweb ? {
      "${var.deployment_prefix}-fortiweb-internal-lb-rule-ha" = {
        name                           = "lbruleFEall"
        loadbalancer_id                = azurerm_lb.load_balancer["${var.deployment_prefix}-fortiweb-internal-lb"].id
        frontend_ip_configuration_name = "${var.deployment_prefix}-ILB-${var.subnets["fortiweb_external"].name}-FrontEnd"
        backend_address_pool_ids       = [azurerm_lb_backend_address_pool.lb_backend_address_pool["${var.deployment_prefix}-fortiweb-internal-lb-backend"].id]
        probe_id                       = azurerm_lb_probe.lb_probe["${var.deployment_prefix}-fortiweb-internal-lb-probe"].id
        protocol                       = "All"
        frontend_port                  = 0
        backend_port                   = 0
        enable_floating_ip             = true
        idle_timeout_in_minutes        = 5
      }
    } : {},
    # FortiWeb External LB Rules
    var.deploy_fortiweb ? {
      "${var.deployment_prefix}-fortiweb-external-lb-rule-http" = {
        name                           = "PublicLBRule-FE1-http"
        loadbalancer_id                = azurerm_lb.load_balancer["${var.deployment_prefix}-fortiweb-external-lb"].id
        frontend_ip_configuration_name = "${var.deployment_prefix}-FWB-ELB-FrontEnd"
        backend_address_pool_ids       = [azurerm_lb_backend_address_pool.lb_backend_address_pool["${var.deployment_prefix}-fortiweb-external-lb-backend"].id]
        probe_id                       = azurerm_lb_probe.lb_probe["${var.deployment_prefix}-fortiweb-external-lb-probe-http"].id
        protocol                       = "Tcp"
        frontend_port                  = 80
        backend_port                   = 80
        enable_floating_ip             = true
        idle_timeout_in_minutes        = 5
      }
      "${var.deployment_prefix}-fortiweb-external-lb-rule-https" = {
        name                           = "PublicLBRule-FE1-https"
        loadbalancer_id                = azurerm_lb.load_balancer["${var.deployment_prefix}-fortiweb-external-lb"].id
        frontend_ip_configuration_name = "${var.deployment_prefix}-FWB-ELB-FrontEnd"
        backend_address_pool_ids       = [azurerm_lb_backend_address_pool.lb_backend_address_pool["${var.deployment_prefix}-fortiweb-external-lb-backend"].id]
        probe_id                       = azurerm_lb_probe.lb_probe["${var.deployment_prefix}-fortiweb-external-lb-probe-https"].id
        protocol                       = "Tcp"
        frontend_port                  = 443
        backend_port                   = 443
        enable_floating_ip             = true
        idle_timeout_in_minutes        = 5
      }
    } : {}
  )

  #####################################################################
  # Load Balancer NAT Rules (Management Access)
  #####################################################################

  lb_nat_rules = merge(
    # FortiGate NAT Rules (only when no mgmt public IPs)
    var.enable_fortigate_mgmt_public_ips ? {} : {
      "${var.deployment_prefix}-nat-fgt-a-ssh" = {
        name                           = "${var.deployment_prefix}-fgt-a-SSH"
        loadbalancer_id                = azurerm_lb.load_balancer["${var.deployment_prefix}-external-lb"].id
        frontend_ip_configuration_name = "${var.deployment_prefix}-ELB-${var.subnets["fortigate_external"].name}-FrontEnd"
        protocol                       = "Tcp"
        frontend_port                  = 50030
        backend_port                   = 22
        enable_floating_ip             = false
      }
      "${var.deployment_prefix}-nat-fgt-a-https" = {
        name                           = "${var.deployment_prefix}-fgt-a-FGAdminPerm"
        loadbalancer_id                = azurerm_lb.load_balancer["${var.deployment_prefix}-external-lb"].id
        frontend_ip_configuration_name = "${var.deployment_prefix}-ELB-${var.subnets["fortigate_external"].name}-FrontEnd"
        protocol                       = "Tcp"
        frontend_port                  = 40030
        backend_port                   = 443
        enable_floating_ip             = false
      }
      "${var.deployment_prefix}-nat-fgt-b-ssh" = {
        name                           = "${var.deployment_prefix}-fgt-b-SSH"
        loadbalancer_id                = azurerm_lb.load_balancer["${var.deployment_prefix}-external-lb"].id
        frontend_ip_configuration_name = "${var.deployment_prefix}-ELB-${var.subnets["fortigate_external"].name}-FrontEnd"
        protocol                       = "Tcp"
        frontend_port                  = 50031
        backend_port                   = 22
        enable_floating_ip             = false
      }
      "${var.deployment_prefix}-nat-fgt-b-https" = {
        name                           = "${var.deployment_prefix}-fgt-b-FGAdminPerm"
        loadbalancer_id                = azurerm_lb.load_balancer["${var.deployment_prefix}-external-lb"].id
        frontend_ip_configuration_name = "${var.deployment_prefix}-ELB-${var.subnets["fortigate_external"].name}-FrontEnd"
        protocol                       = "Tcp"
        frontend_port                  = 40031
        backend_port                   = 443
        enable_floating_ip             = false
      }
    },
    # FortiWeb NAT Rules (always when FortiWeb deployed)
    var.deploy_fortiweb ? {
      "${var.deployment_prefix}-nat-fwb-a-ssh" = {
        name                           = "${var.deployment_prefix}-fwb-a-SSH"
        loadbalancer_id                = azurerm_lb.load_balancer["${var.deployment_prefix}-fortiweb-external-lb"].id
        frontend_ip_configuration_name = "${var.deployment_prefix}-FWB-ELB-FrontEnd"
        protocol                       = "Tcp"
        frontend_port                  = 50030
        backend_port                   = 22
        enable_floating_ip             = false
      }
      "${var.deployment_prefix}-nat-fwb-a-https" = {
        name                           = "${var.deployment_prefix}-fwb-a-FWBAdminPerm"
        loadbalancer_id                = azurerm_lb.load_balancer["${var.deployment_prefix}-fortiweb-external-lb"].id
        frontend_ip_configuration_name = "${var.deployment_prefix}-FWB-ELB-FrontEnd"
        protocol                       = "Tcp"
        frontend_port                  = 40030
        backend_port                   = var.fortiweb_https_probe_port
        enable_floating_ip             = false
      }
      "${var.deployment_prefix}-nat-fwb-b-ssh" = {
        name                           = "${var.deployment_prefix}-fwb-b-SSH"
        loadbalancer_id                = azurerm_lb.load_balancer["${var.deployment_prefix}-fortiweb-external-lb"].id
        frontend_ip_configuration_name = "${var.deployment_prefix}-FWB-ELB-FrontEnd"
        protocol                       = "Tcp"
        frontend_port                  = 50031
        backend_port                   = 22
        enable_floating_ip             = false
      }
      "${var.deployment_prefix}-nat-fwb-b-https" = {
        name                           = "${var.deployment_prefix}-fwb-b-FWBAdminPerm"
        loadbalancer_id                = azurerm_lb.load_balancer["${var.deployment_prefix}-fortiweb-external-lb"].id
        frontend_ip_configuration_name = "${var.deployment_prefix}-FWB-ELB-FrontEnd"
        protocol                       = "Tcp"
        frontend_port                  = 40031
        backend_port                   = var.fortiweb_https_probe_port
        enable_floating_ip             = false
      }
    } : {}
  )

  #####################################################################
  # Network Interface Backend Pool Associations
  #####################################################################

  network_interface_backend_address_pool_associations = merge(
    {
      # FortiGate A - External NIC to External LB
      "${var.deployment_prefix}-fgt-a-nic1-external-lb" = {
        network_interface_id    = azurerm_network_interface.network_interface["${var.deployment_prefix}-fgt-a-nic1"].id
        ip_configuration_name   = "ipconfig1"
        backend_address_pool_id = azurerm_lb_backend_address_pool.lb_backend_address_pool["${var.deployment_prefix}-external-lb-backend"].id
      }
      # FortiGate A - Internal NIC to Internal LB
      "${var.deployment_prefix}-fgt-a-nic2-internal-lb" = {
        network_interface_id    = azurerm_network_interface.network_interface["${var.deployment_prefix}-fgt-a-nic2"].id
        ip_configuration_name   = "ipconfig1"
        backend_address_pool_id = azurerm_lb_backend_address_pool.lb_backend_address_pool["${var.deployment_prefix}-internal-lb-backend"].id
      }
      # FortiGate B - External NIC to External LB
      "${var.deployment_prefix}-fgt-b-nic1-external-lb" = {
        network_interface_id    = azurerm_network_interface.network_interface["${var.deployment_prefix}-fgt-b-nic1"].id
        ip_configuration_name   = "ipconfig1"
        backend_address_pool_id = azurerm_lb_backend_address_pool.lb_backend_address_pool["${var.deployment_prefix}-external-lb-backend"].id
      }
      # FortiGate B - Internal NIC to Internal LB
      "${var.deployment_prefix}-fgt-b-nic2-internal-lb" = {
        network_interface_id    = azurerm_network_interface.network_interface["${var.deployment_prefix}-fgt-b-nic2"].id
        ip_configuration_name   = "ipconfig1"
        backend_address_pool_id = azurerm_lb_backend_address_pool.lb_backend_address_pool["${var.deployment_prefix}-internal-lb-backend"].id
      }
    },
    # FortiWeb Backend Pool Associations
    var.deploy_fortiweb ? {
      # FortiWeb A - Port 1 to Internal LB
      "${var.deployment_prefix}-fwb-a-nic1-internal-lb" = {
        network_interface_id    = azurerm_network_interface.network_interface["${var.deployment_prefix}-fwb-a-nic1"].id
        ip_configuration_name   = "ipconfig1"
        backend_address_pool_id = azurerm_lb_backend_address_pool.lb_backend_address_pool["${var.deployment_prefix}-fortiweb-internal-lb-backend"].id
      }
      # FortiWeb A - Port 1 to External LB
      "${var.deployment_prefix}-fwb-a-nic1-external-lb" = {
        network_interface_id    = azurerm_network_interface.network_interface["${var.deployment_prefix}-fwb-a-nic1"].id
        ip_configuration_name   = "ipconfig1"
        backend_address_pool_id = azurerm_lb_backend_address_pool.lb_backend_address_pool["${var.deployment_prefix}-fortiweb-external-lb-backend"].id
      }
      # FortiWeb B - Port 1 to Internal LB
      "${var.deployment_prefix}-fwb-b-nic1-internal-lb" = {
        network_interface_id    = azurerm_network_interface.network_interface["${var.deployment_prefix}-fwb-b-nic1"].id
        ip_configuration_name   = "ipconfig1"
        backend_address_pool_id = azurerm_lb_backend_address_pool.lb_backend_address_pool["${var.deployment_prefix}-fortiweb-internal-lb-backend"].id
      }
      # FortiWeb B - Port 1 to External LB
      "${var.deployment_prefix}-fwb-b-nic1-external-lb" = {
        network_interface_id    = azurerm_network_interface.network_interface["${var.deployment_prefix}-fwb-b-nic1"].id
        ip_configuration_name   = "ipconfig1"
        backend_address_pool_id = azurerm_lb_backend_address_pool.lb_backend_address_pool["${var.deployment_prefix}-fortiweb-external-lb-backend"].id
      }
    } : {}
  )

  #####################################################################
  # Network Interface NAT Rule Associations
  #####################################################################

  network_interface_nat_rule_associations = merge(
    # FortiGate NAT associations (only when no mgmt public IPs)
    var.enable_fortigate_mgmt_public_ips ? {} : {
      "${var.deployment_prefix}-fgt-a-nic1-nat-ssh" = {
        network_interface_id  = azurerm_network_interface.network_interface["${var.deployment_prefix}-fgt-a-nic1"].id
        ip_configuration_name = "ipconfig1"
        nat_rule_id           = azurerm_lb_nat_rule.lb_nat_rule["${var.deployment_prefix}-nat-fgt-a-ssh"].id
      }
      "${var.deployment_prefix}-fgt-a-nic1-nat-https" = {
        network_interface_id  = azurerm_network_interface.network_interface["${var.deployment_prefix}-fgt-a-nic1"].id
        ip_configuration_name = "ipconfig1"
        nat_rule_id           = azurerm_lb_nat_rule.lb_nat_rule["${var.deployment_prefix}-nat-fgt-a-https"].id
      }
      "${var.deployment_prefix}-fgt-b-nic1-nat-ssh" = {
        network_interface_id  = azurerm_network_interface.network_interface["${var.deployment_prefix}-fgt-b-nic1"].id
        ip_configuration_name = "ipconfig1"
        nat_rule_id           = azurerm_lb_nat_rule.lb_nat_rule["${var.deployment_prefix}-nat-fgt-b-ssh"].id
      }
      "${var.deployment_prefix}-fgt-b-nic1-nat-https" = {
        network_interface_id  = azurerm_network_interface.network_interface["${var.deployment_prefix}-fgt-b-nic1"].id
        ip_configuration_name = "ipconfig1"
        nat_rule_id           = azurerm_lb_nat_rule.lb_nat_rule["${var.deployment_prefix}-nat-fgt-b-https"].id
      }
    },
    # FortiWeb NAT associations (always when FortiWeb deployed)
    var.deploy_fortiweb ? {
      "${var.deployment_prefix}-fwb-a-nic1-nat-ssh" = {
        network_interface_id  = azurerm_network_interface.network_interface["${var.deployment_prefix}-fwb-a-nic1"].id
        ip_configuration_name = "ipconfig1"
        nat_rule_id           = azurerm_lb_nat_rule.lb_nat_rule["${var.deployment_prefix}-nat-fwb-a-ssh"].id
      }
      "${var.deployment_prefix}-fwb-a-nic1-nat-https" = {
        network_interface_id  = azurerm_network_interface.network_interface["${var.deployment_prefix}-fwb-a-nic1"].id
        ip_configuration_name = "ipconfig1"
        nat_rule_id           = azurerm_lb_nat_rule.lb_nat_rule["${var.deployment_prefix}-nat-fwb-a-https"].id
      }
      "${var.deployment_prefix}-fwb-b-nic1-nat-ssh" = {
        network_interface_id  = azurerm_network_interface.network_interface["${var.deployment_prefix}-fwb-b-nic1"].id
        ip_configuration_name = "ipconfig1"
        nat_rule_id           = azurerm_lb_nat_rule.lb_nat_rule["${var.deployment_prefix}-nat-fwb-b-ssh"].id
      }
      "${var.deployment_prefix}-fwb-b-nic1-nat-https" = {
        network_interface_id  = azurerm_network_interface.network_interface["${var.deployment_prefix}-fwb-b-nic1"].id
        ip_configuration_name = "ipconfig1"
        nat_rule_id           = azurerm_lb_nat_rule.lb_nat_rule["${var.deployment_prefix}-nat-fwb-b-https"].id
      }
    } : {}
  )
}
