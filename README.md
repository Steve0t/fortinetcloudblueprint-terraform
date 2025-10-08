# Canadian Fortinet Architecture Blueprint - Terraform

Azure infrastructure-as-code deployment for a high-availability Fortinet security stack with FortiGate firewall cluster, FortiWeb WAF, and demonstration workloads.

## 📋 Table of Contents

- [Architecture Overview](#architecture-overview)
- [What Gets Deployed](#what-gets-deployed)
- [File Organization](#file-organization)
- [Quick Start](#quick-start)
- [Configuration](#configuration)
- [Understanding the Code Structure](#understanding-the-code-structure)
- [Development Workflow](#development-workflow)
- [Common Operations](#common-operations)
- [Troubleshooting](#troubleshooting)

---

## 🏗️ Architecture Overview

This Terraform project deploys a complete Azure network security architecture:

```
Internet
   ↓
FortiGate External LB (Public IP)
   ↓
FortiGate HA Cluster (Active-Active)
├── Port 1: External (FGExternal subnet)
├── Port 2: Internal (FGInternal subnet)
├── Port 3: HA Sync (FGHA subnet)
└── Port 4: Management (FGMgmt subnet)
   ↓
FortiGate Internal LB (Private IP)
   ↓
FortiWeb HA Cluster (Active-Active) [Optional]
├── Port 1: External (FWBExternal subnet)
└── Port 2: Internal (FWBInternal subnet)
   ↓
FortiWeb External LB (Public IP) [Optional]
   ↓
Workload VM (DMZProtectedA subnet) [Optional]
└── Docker containers: DVWA, Juice Shop, Petstore, Demo sites
```

**Key Components:**
- **FortiGate**: Next-generation firewall with HA clustering
- **FortiWeb**: Web application firewall for HTTP/HTTPS protection
- **Load Balancers**: Azure LBs for traffic distribution and HA
- **Workload VM**: Ubuntu with vulnerable web apps for testing

---

## 📦 What Gets Deployed

### Always Deployed (Core Infrastructure)

| Resource | Count | Purpose |
|----------|-------|---------|
| Resource Group | 1 | Container for all resources |
| Virtual Network | 1 | Azure VNet (default: 10.0.0.0/16) |
| Subnets | 7 | Network segmentation |
| Network Security Groups | 3 | Traffic filtering rules |
| Route Tables | 5 | Traffic routing configuration |
| Public IPs | 1-3 | External access (FortiGate cluster + optional mgmt IPs) |
| Load Balancers | 2 | FortiGate external + internal LBs |
| FortiGate VMs | 2 | Active-Active HA cluster |
| Network Interfaces | 8 | 4 NICs per FortiGate |

**Total Core Resources:** ~30-35 Azure resources

### Optional Components

#### FortiWeb WAF (`deploy_fortiweb = true`)
- 2x FortiWeb VMs (Active-Active HA)
- 1x External Load Balancer
- 4x Network Interfaces (2 per FortiWeb)
- 1x Public IP (cluster IP)

**Additional Resources:** ~8 Azure resources

#### Workload VM (`deploy_dvwa = true`)
- 1x Ubuntu VM with Docker
- 1x Network Interface
- Vulnerable web applications for testing

**Additional Resources:** ~2 Azure resources

**Total Possible Resources:** Up to 45 Azure resources (full deployment)

---

## 📁 File Organization

### Overview: Data-Driven Architecture Pattern

This project uses a **locals-based configuration pattern** where:
1. **Variables** define user inputs (`variables.tf`)
2. **Locals** define resource configurations as data structures (`locals_*.tf`)
3. **Resources** iterate over locals using `for_each` (`resource_*.tf`)

This creates a clean separation between configuration and implementation.

---

### File Categories

#### 1️⃣ Configuration Layer (Input)

| File | Purpose | User Action |
|------|---------|-------------|
| `variables.tf` | Variable declarations (49 variables) | Read to understand options |
| `terraform.tfvars` | Your custom values | **CREATE & EDIT THIS** |
| `terraform.tfvars.example` | Example configuration with documentation | Copy to terraform.tfvars |

#### 2️⃣ Data Sources

| File | Purpose | When Evaluated |
|------|---------|----------------|
| `data.tf` | External data lookups (your public IP) | During plan |

#### 3️⃣ Local Values (Configuration as Data)

These files define **what** to create, not **how** to create it.

##### **locals_network.tf** - Foundation & Network Resources
```
Purpose: Foundational infrastructure + network resource definitions
Contains:
  ├── Computed project values
  │   ├── resource_group_name (from deployment_prefix)
  │   ├── location (with fallback to canadacentral)
  │   ├── vnet_name (with auto-generation)
  │   └── detected_public_ip (auto-detect or manual)
  │
  └── Resource definitions
      ├── resource_groups (1 RG)
      ├── virtual_networks (1 VNet)
      ├── subnets (7 subnets)
      ├── network_security_groups (3 NSGs)
      ├── routes (multiple routes)
      └── public_ips (1-3 public IPs)

Lines: ~280
Used by: All other locals files + network resource files
```

**Why these are together:**
- Resource Group is foundational (created first, used everywhere)
- Computed values are project-wide constants
- Network resources are the first infrastructure layer
- All other resources depend on these definitions

##### **locals_constants.tf** - Infrastructure Constants
```
Purpose: True constants that never change
Contains:
  ├── Azure availability zones (1, 2, 3)
  ├── Storage SKUs (Standard_LRS)
  └── Fortinet marketplace identifiers
      ├── Publisher: "fortinet"
      ├── FortiGate offer/product IDs
      └── FortiWeb offer/product IDs

Lines: ~60
Used by: VM creation, marketplace agreement
```

**Why separate:**
- These values are truly constant (not computed)
- Rarely (if ever) need modification
- Clear separation: constants vs computed values

##### **locals_fortigate.tf** - FortiGate Configuration
```
Purpose: FortiGate VM and network interface definitions
Contains:
  ├── network_interfaces_fortigate (8 NICs: 4 per FortiGate)
  │   ├── FortiGate A: port1, port2, port3, port4
  │   └── FortiGate B: port1, port2, port3, port4
  │
  └── virtual_machines_fortigate (2 VMs)
      ├── FortiGate A (priority 255)
      └── FortiGate B (priority 1)

Lines: ~260
Used by: locals_compute.tf (merged)
Depends on: locals_network.tf (subnets, NSGs)
```

**Key features:**
- Uses `cidrhost()` for sequential IP allocation
- Cloud-init from `cloud-init/fortigate.tpl`
- Conditional management public IPs

##### **locals_fortiweb.tf** - FortiWeb Configuration
```
Purpose: FortiWeb VM and network interface definitions (conditional)
Contains:
  ├── network_interfaces_fortiweb (4 NICs: 2 per FortiWeb)
  │   ├── FortiWeb A: port1, port2
  │   └── FortiWeb B: port1, port2
  │
  └── virtual_machines_fortiweb (2 VMs)
      ├── FortiWeb A (priority 1)
      └── FortiWeb B (priority 2)

Lines: ~150
Conditional: Only if var.deploy_fortiweb = true
Used by: locals_compute.tf (merged)
Depends on: locals_network.tf (subnets)
```

**Key features:**
- Uses `merge()` for conditional deployment
- Cloud-init from `cloud-init/fortiweb.tpl`
- HA group ID configuration

##### **locals_workload.tf** - Workload VM Configuration
```
Purpose: Test workload VM definition (conditional)
Contains:
  ├── network_interfaces_workload (1 NIC)
  └── virtual_machines_workload (1 VM)
      └── Ubuntu with Docker containers

Lines: ~60
Conditional: Only if var.deploy_dvwa = true
Used by: locals_compute.tf (merged)
Depends on: locals_network.tf (subnet)
```

**Key features:**
- Single Ubuntu VM with Docker
- Cloud-init from `cloud-init/workload.tpl`
- Runs DVWA, Juice Shop, Petstore apps

##### **locals_load_balancer.tf** - Load Balancer Configuration
```
Purpose: Azure Load Balancer definitions (external + internal)
Contains:
  ├── load_balancers (2-3 LBs)
  │   ├── FortiGate Internal LB (private IP)
  │   ├── FortiGate External LB (public IP)
  │   └── FortiWeb External LB (public IP, conditional)
  │
  ├── lb_backend_pools (backend address pools)
  ├── lb_probes (health checks)
  ├── lb_rules (load balancing rules)
  └── lb_nat_rules (port forwarding for management)

Lines: ~450
Used by: Load balancer resource files
Depends on: locals_network.tf (subnets, public IPs)
```

**Key features:**
- FortiGate HA port configuration
- Health probe ports (8008 for FGT, 8080/8443 for FWB)
- NAT rules for SSH/HTTPS management access

##### **locals_marketplace_agreements.tf** - Azure Marketplace Terms
```
Purpose: Define Azure Marketplace agreement acceptance configurations
Contains:
  └── marketplace_agreements (conditional merge)
      ├── FortiGate agreement (always required)
      └── FortiWeb agreement (conditional: deploy_fortiweb)

Lines: ~35
Used by: resource_marketplace_agreement.tf
Depends on: locals_constants.tf (publisher/offer IDs), variables.tf (SKUs)
```

**Key features:**
- Conditional FortiWeb agreement using `merge()` pattern
- References Fortinet marketplace constants
- Ubuntu workload VM doesn't need marketplace agreement (free Canonical image)

**Why separate:**
- Marketplace agreements are foundational (must be accepted before VM creation)
- Clean separation of marketplace configuration from VM configuration
- Enables easy addition of future Fortinet products (FortiManager, FortiAnalyzer)

##### **locals_compute.tf** - Resource Aggregator
```
Purpose: Merge component-specific locals into final collections
Contains:
  ├── network_interfaces (merged from all components)
  └── virtual_machines (merged from all components)

Lines: ~35
Special role: Aggregates conditional resources
Pattern: merge(fortigate, fortiweb, workload)
```

**Why this exists:**
- Single source for `resource_network_interface.tf`
- Single source for `resource_linux_virtual_machine.tf`
- Handles conditional merging (FortiWeb/Workload may not exist)
- Clean separation of concerns

**Architecture Pattern:**
```
locals_fortigate.tf → network_interfaces_fortigate ↘
locals_fortiweb.tf  → network_interfaces_fortiweb  → locals_compute.tf → network_interfaces → resource_network_interface.tf
locals_workload.tf  → network_interfaces_workload ↗
```

---

#### 4️⃣ Resource Implementation Layer

These files define **how** to create resources from locals.

**Pattern:** `resource_<type>.tf` iterates over `local.<type>s` using `for_each`

##### Generic Resource Files (Iterate over locals)

| File | Iterates Over | Creates | Count |
|------|---------------|---------|-------|
| `resource_resource_group.tf` | `local.resource_groups` | Resource Groups | 1 |
| `resource_virtual_network.tf` | `local.virtual_networks` | VNets | 1 |
| `resource_subnet.tf` | `local.subnets` | Subnets | 7 |
| `resource_network_security_group.tf` | `local.network_security_groups` | NSGs | 3 |
| `resource_route_table.tf` | `local.route_tables` | Route Tables | 5 |
| `resource_route.tf` | `local.routes` | Routes | Multiple |
| `resource_public_ip.tf` | `local.public_ips` | Public IPs | 1-3 |
| `resource_network_interface.tf` | `local.network_interfaces` | NICs | 8-13 |
| `resource_linux_virtual_machine.tf` | `local.virtual_machines` | VMs | 2-5 |
| `resource_load_balancer.tf` | `local.load_balancers` | Load Balancers | 2-3 |

##### Association/Link Resource Files

| File | Purpose |
|------|---------|
| `resource_subnet_route_table_association.tf` | Link subnets to route tables |
| `resource_network_interface_security_group_association.tf` | Link NICs to NSGs |
| `resource_network_interface_backend_address_pool_association.tf` | Link NICs to LB backend pools |
| `resource_network_interface_nat_rule_association.tf` | Link NICs to LB NAT rules |

##### Load Balancer Component Files

| File | Purpose |
|------|---------|
| `resource_lb_backend_address_pool.tf` | LB backend pools |
| `resource_lb_probe.tf` | Health probes |
| `resource_lb_rule.tf` | Load balancing rules |
| `resource_lb_nat_rule.tf` | NAT rules for management |

##### Special Resource Files

| File | Purpose |
|------|---------|
| `resource_marketplace_agreement.tf` | Accept Azure Marketplace terms (native azurerm resource) |

**Marketplace Agreement Details:**
- Uses native `azurerm_marketplace_agreement` resource (not Azure CLI)
- Iterates over `local.marketplace_agreements` using `for_each`
- Automatically handles FortiGate (always) and FortiWeb (conditional)
- VMs depend on marketplace agreements via `depends_on`
- Ubuntu workload VM doesn't require marketplace agreement (free Canonical image)

---

#### 5️⃣ Configuration Templates

| File | Purpose | Used By |
|------|---------|---------|
| `cloud-init/fortigate.tpl` | FortiGate OS configuration | FortiGate VMs |
| `cloud-init/fortiweb.tpl` | FortiWeb configuration | FortiWeb VMs |
| `cloud-init/workload.tpl` | Ubuntu + Docker setup | Workload VM |

**Template Features:**
- Terraform `templatefile()` function
- Variables passed with `var_` prefix
- FortiOS CLI commands for FortiGate/FortiWeb
- Bash script for workload VM

---

#### 6️⃣ Output Layer

| File | Purpose | Conditionally Displayed |
|------|---------|------------------------|
| `outputs.tf` | Terraform outputs (17 outputs) | Debug vs user-friendly |

**Output Categories:**
1. **Debug Outputs** (controlled by `var.debug_outputs`):
   - Full resource details (subnets, NICs, NSGs, routes, etc.)
   - For troubleshooting and development

2. **User-Friendly Outputs** (always displayed):
   - Connection information (IPs, URLs, admin usernames)
   - Deployment summary
   - FortiGate/FortiWeb access details

---

#### 7️⃣ Provider Configuration

| File | Purpose |
|------|---------|
| `provider.tf` | Terraform and AzureRM provider configuration |

---

## 🎯 Understanding the Code Structure

### The Locals Pattern Explained

#### Traditional Terraform (Avoid This)
```hcl
# ❌ Resource definition with inline configuration
resource "azurerm_subnet" "subnet1" {
  name                 = "FGExternal"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "subnet2" {
  name                 = "FGInternal"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}
# ... repeat 5 more times
```

**Problems:**
- Repetitive code (DRY violation)
- Hard to see all subnets at once
- Difficult to add conditional subnets
- Configuration mixed with implementation

#### This Project's Pattern (Data-Driven)

**Step 1: Define configuration as data** (`locals_network.tf`)
```hcl
locals {
  subnets = {
    "${var.deployment_prefix}-FGExternal" = {
      name                 = "FGExternal"
      resource_group_name  = azurerm_resource_group.resource_group[local.resource_group_name].name
      virtual_network_name = azurerm_virtual_network.virtual_network[local.vnet_name].name
      address_prefixes     = ["10.0.1.0/24"]
    }
    "${var.deployment_prefix}-FGInternal" = {
      name                 = "FGInternal"
      resource_group_name  = azurerm_resource_group.resource_group[local.resource_group_name].name
      virtual_network_name = azurerm_virtual_network.virtual_network[local.vnet_name].name
      address_prefixes     = ["10.0.2.0/24"]
    }
    # ... all 7 subnets in one data structure
  }
}
```

**Step 2: Iterate over data** (`resource_subnet.tf`)
```hcl
resource "azurerm_subnet" "subnet" {
  for_each = local.subnets

  name                 = each.value.name
  resource_group_name  = each.value.resource_group_name
  virtual_network_name = each.value.virtual_network_name
  address_prefixes     = each.value.address_prefixes
}
```

**Benefits:**
- ✅ Single resource block handles all subnets
- ✅ Configuration in one place (locals)
- ✅ Easy to add/remove subnets
- ✅ Conditional subnets via `merge()`
- ✅ Clear separation: what vs how

### Conditional Deployment Pattern

**Example: FortiWeb (optional component)**

**In `locals_fortiweb.tf`:**
```hcl
locals {
  network_interfaces_fortiweb = var.deploy_fortiweb ? {
    # FortiWeb NICs defined here
  } : {}

  virtual_machines_fortiweb = var.deploy_fortiweb ? {
    # FortiWeb VMs defined here
  } : {}
}
```

**In `locals_compute.tf`:**
```hcl
locals {
  network_interfaces = merge(
    local.network_interfaces_fortigate,
    local.network_interfaces_fortiweb,  # Empty map if deploy_fortiweb = false
    local.network_interfaces_workload
  )
}
```

**Result:**
- When `deploy_fortiweb = false`: FortiWeb locals are empty maps
- Merge includes them but they add nothing
- Resource files create only what's in the merged map
- No FortiWeb resources created

---

## 🚀 Quick Start

### Prerequisites

1. **Azure Subscription** with sufficient permissions
2. **Terraform** v1.0+ installed ([download](https://www.terraform.io/downloads))
3. **Azure authentication** configured (via Azure CLI, Service Principal, or Managed Identity)
   - Easiest: Azure CLI ([install](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)) and run `az login`
   - Production: Service Principal or Managed Identity ([guide](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/service_principal_client_secret))

**Note:** Azure CLI is optional (only needed for `az login`). All operations use native Terraform resources.

### Basic Deployment (5 minutes)

```bash
# 1. Navigate to terraform directory
cd terraform/

# 2. Create your configuration file
cp terraform.tfvars.example terraform.tfvars

# 3. Edit with your values (minimum: 3 required variables)
vim terraform.tfvars
# Set: deployment_prefix, admin_username, admin_password

# 4. Initialize Terraform
terraform init

# 5. Preview changes
terraform plan

# 6. Deploy infrastructure
terraform apply

# 7. Access your deployment
# Check outputs for connection information
terraform output connection_information
```

### Minimal Configuration Example

**terraform.tfvars:**
```hcl
# Required
deployment_prefix = "myfortinet"
admin_username    = "azureadmin"
admin_password    = "SecurePassword123!"

# Optional - use defaults for everything else
location        = "canadacentral"
deploy_fortiweb = false  # FortiGate only
deploy_dvwa     = false  # No test workloads
```

This deploys:
- FortiGate HA cluster
- 2 Load Balancers
- Network infrastructure
- ~30 Azure resources

---

## ⚙️ Configuration

### Configuration Files

1. **terraform.tfvars** (your custom values)
   - Copy from `terraform.tfvars.example`
   - Set required variables (deployment_prefix, admin_username, admin_password)
   - Customize optional variables as needed
   - **NEVER commit this file** (contains secrets)

2. **variables.tf** (reference only)
   - Read to understand available options
   - See descriptions, defaults, validation rules
   - Do not edit unless adding new functionality

3. **terraform.tfvars.example** (documentation)
   - Comprehensive examples for all variables
   - Variable relationships explained
   - Example configurations for common scenarios

### Key Configuration Decisions

#### 1. What to Deploy

```hcl
deploy_fortiweb = true   # Deploy FortiWeb WAF cluster?
deploy_dvwa     = true   # Deploy test workload VM?
```

**Scenarios:**
- **Production firewall only**: Both false (~30 resources)
- **Full security stack**: fortiweb true, dvwa false (~38 resources)
- **Dev/test environment**: Both true (~40 resources)

#### 2. VM Sizing

```hcl
instance_type = "Standard_F4s"  # Development/Testing
# instance_type = "Standard_F8s"   # Production
# instance_type = "Standard_F16s"  # High Performance
```

**Guidelines:**
- F4s: Dev/test, low traffic
- F8s: Production, moderate traffic
- F16s: High traffic, enterprise

#### 3. High Availability Options

```hcl
availability_options = "Availability Set"      # Single datacenter
# availability_options = "Availability Zones"  # Multi-datacenter
```

**Trade-offs:**
- **Availability Set**: Lower latency, 99.95% SLA
- **Availability Zones**: Higher resilience, 99.99% SLA, cross-datacenter

#### 4. Management Access

```hcl
enable_fortigate_mgmt_public_ips = true  # Dedicated public IPs per FortiGate
# enable_fortigate_mgmt_public_ips = false  # Access via NAT rules only
```

#### 5. Network Addressing

```hcl
vnet_address_prefix = "10.0.0.0/16"  # Change if conflicts with existing networks

subnets = {
  fortigate_external = {
    address_prefix = "10.0.1.0/24"
    start_address  = "10.0.1.5"
    # ...
  }
  # ... customize all 7 subnets if needed
}
```

### Variable Reference

See `terraform.tfvars.example` for comprehensive documentation of all 49 variables.

**Categories:**
- Required Variables (3)
- Location & Tagging (2)
- Deployment Control (2)
- Network Configuration (4)
- FortiGate Configuration (22)
- FortiWeb Configuration (8)
- Workload Configuration (1)
- Output Control (1)
- Advanced Ports (8)

---

## 🔧 Development Workflow

### Making Changes

#### Adding a New Subnet

1. **Update `variables.tf`**: Add to `subnets` variable default
2. **Update `locals_network.tf`**: Add subnet definition to `local.subnets`
3. **Add route table** (if needed): Update `local.route_tables` and `local.routes`
4. **Add NSG rules** (if needed): Update `local.network_security_groups`
5. **Test**: `terraform plan` to verify
6. **Update docs**: Add to `terraform.tfvars.example`

#### Adding a New VM Type

1. **Create `locals_<component>.tf`**: Define NICs and VMs
2. **Update `locals_compute.tf`**: Add to merge() statements
3. **Create cloud-init template**: Add to `cloud-init/<component>.tpl`
4. **Add variable**: For conditional deployment (if optional)
5. **Test**: `terraform plan` to verify
6. **Update docs**: Document in this README

#### Modifying Load Balancer Rules

1. **Edit `locals_load_balancer.tf`**: Update lb_rules section
2. **Verify probe**: Ensure corresponding health probe exists
3. **Test**: `terraform plan` to verify
4. **Apply**: `terraform apply`

### Testing Changes

```bash
# 1. Validate syntax
terraform validate

# 2. Format code
terraform fmt -recursive

# 3. Plan with detailed output
terraform plan -out=tfplan

# 4. Review plan
terraform show tfplan

# 5. Apply changes
terraform apply tfplan

# 6. Verify outputs
terraform output
```

### Code Quality Checks

```bash
# Format all files
terraform fmt -recursive

# Validate configuration
terraform validate

# Check for security issues (requires tfsec)
tfsec .

# Generate dependency graph
terraform graph | dot -Tpng > graph.png
```

---

## 📚 Common Operations

### View Connection Information

```bash
# All connection details
terraform output connection_information

# Specific outputs
terraform output fortigate_public_ip
terraform output fortigate_management_ips
terraform output fortiweb_public_ip
```

### Enable Debug Outputs

**In terraform.tfvars:**
```hcl
debug_outputs = true
```

Then run:
```bash
terraform apply
terraform output  # Shows verbose resource details
```

### Scale VM Size

**In terraform.tfvars:**
```hcl
instance_type = "Standard_F8s"  # Change from F4s to F8s
```

```bash
terraform apply  # VMs will be recreated with new size
```

### Add FortiWeb to Existing Deployment

**In terraform.tfvars:**
```hcl
deploy_fortiweb = true  # Change from false
```

```bash
terraform plan   # Review new resources
terraform apply  # Add FortiWeb components
```

### Change Admin Password

**In terraform.tfvars:**
```hcl
admin_password = "NewSecurePassword123!"
```

```bash
terraform apply  # Updates VM configuration
```

**Note**: VMs may need recreation depending on Azure VM agent capabilities.

### Destroy Infrastructure

```bash
# Preview what will be destroyed
terraform plan -destroy

# Destroy all resources
terraform destroy

# Destroy specific resource
terraform destroy -target=azurerm_linux_virtual_machine.virtual_machine[\"workload-vm\"]
```

---

## 🔍 Troubleshooting

### Common Issues

#### Issue: Marketplace Agreement Not Accepted

**Error:**
```
Error: creating Linux Virtual Machine: MarketplacePurchaseEligibilityFailed
```

**Solution:**

Terraform **automatically handles** marketplace agreement acceptance via `resource_marketplace_agreement.tf`. This error typically only occurs if:

1. **Initial deployment with connectivity issues** - Terraform couldn't reach Azure Marketplace API
2. **Manual state manipulation** - Marketplace agreement resource was removed from state
3. **Terms revoked externally** - Someone manually revoked the terms in Azure Portal

**Fix:**
```bash
# Let Terraform handle it automatically (recommended)
terraform apply

# The native azurerm_marketplace_agreement resource will:
# - Accept FortiGate terms (always)
# - Accept FortiWeb terms (if deploy_fortiweb = true)
# - Track acceptance in Terraform state
```

**Manual acceptance (only if Terraform method fails):**
```bash
# Accept FortiGate terms manually
az vm image terms accept --publisher fortinet --offer fortinet_fortigate-vm_v5 --plan fortinet_fg-vm_payg_2022

# Accept FortiWeb terms (if deploying FortiWeb)
az vm image terms accept --publisher fortinet --offer fortinet_fortiweb-vm_v5 --plan fortinet_fw-vm_payg_v2
```

**Note:** Ubuntu workload VM doesn't require marketplace agreement acceptance (free Canonical image).

#### Issue: IP Address Conflicts

**Error:**
```
Error: subnet address prefix overlaps with existing resource
```

**Solution:**
Update `vnet_address_prefix` in terraform.tfvars to avoid conflicts:
```hcl
vnet_address_prefix = "172.16.0.0/16"  # Different from existing 10.x networks
```

#### Issue: Insufficient IP Addresses

**Error:**
```
Error: subnet does not have enough available IP addresses
```

**Solution:**
Check `start_address` and `required_ip_count` in subnet configuration:
```hcl
subnets = {
  fortigate_external = {
    start_address     = "10.0.1.5"   # Ensure this + required_ip_count fits in subnet
    required_ip_count = 2            # FortiGate A + B
    address_prefix    = "10.0.1.0/24"
  }
}
```

#### Issue: Public IP Auto-Detection Fails

**Error:**
```
Error: error retrieving public IP from ipify.org
```

**Solution:**
Manually specify your public IP:
```hcl
my_public_ip = "203.0.113.42/32"  # Your actual public IP in CIDR format
```

#### Issue: VM Size Not Available

**Error:**
```
Error: The requested VM size 'Standard_F16s' is not available in this region
```

**Solution:**
Check available sizes:
```bash
az vm list-sizes --location canadacentral --output table
```

Use available size:
```hcl
instance_type = "Standard_F8s"
```

### Debug Mode

Enable verbose Terraform logging:

```bash
export TF_LOG=DEBUG
export TF_LOG_PATH=terraform-debug.log
terraform plan
terraform apply
```

Review `terraform-debug.log` for detailed execution information.

### State Issues

#### Corrupted State
```bash
# Pull remote state
terraform state pull > backup.tfstate

# Fix and push back
terraform state push fixed.tfstate
```

#### Remove Resource from State
```bash
# If resource exists in Azure but not in Terraform anymore
terraform state rm azurerm_linux_virtual_machine.virtual_machine[\"vm-name\"]
```

#### Import Existing Resource
```bash
# If resource exists in Azure but not in Terraform state
terraform import azurerm_resource_group.resource_group /subscriptions/<sub-id>/resourceGroups/<rg-name>
```

---

## 📖 Additional Resources

### Fortinet Documentation

- [FortiGate Documentation](https://docs.fortinet.com/product/fortigate)
- [FortiWeb Documentation](https://docs.fortinet.com/product/fortiweb)
- [FortiGate Azure HA Guide](https://docs.fortinet.com/document/fortigate-public-cloud/7.2.0/azure-administration-guide/632940/ha-for-fortigate-vm-on-azure)

### Azure Documentation

- [Azure Virtual Networks](https://docs.microsoft.com/en-us/azure/virtual-network/)
- [Azure Load Balancer](https://docs.microsoft.com/en-us/azure/load-balancer/)
- [Azure NSGs](https://docs.microsoft.com/en-us/azure/virtual-network/network-security-groups-overview)

### Terraform Resources

- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Terraform for_each](https://www.terraform.io/language/meta-arguments/for_each)
- [Terraform locals](https://www.terraform.io/language/values/locals)

---

## 🤝 Contributing

### Code Style

- Use `terraform fmt` before committing
- Follow existing locals pattern for new resources
- Document new variables in `terraform.tfvars.example`
- Update this README for significant changes

### File Naming Conventions

- `locals_*.tf` - Local value definitions (configuration as data)
- `resource_*.tf` - Resource implementations (iterate over locals)
- `data.tf` - Data source lookups
- `variables.tf` - Input variable declarations
- `outputs.tf` - Output value definitions
- `provider.tf` - Provider configuration

### Pull Request Guidelines

1. Test deployment in your Azure subscription
2. Run `terraform fmt -recursive`
3. Run `terraform validate`
4. Update documentation
5. Provide before/after resource counts

---

## 📝 License

See repository LICENSE file.

---

## 🆘 Support

For issues specific to this Terraform code:
- Open an issue in the repository
- Check existing issues for solutions

For Fortinet product support:
- [Fortinet Support Portal](https://support.fortinet.com)
- [Fortinet Community Forums](https://community.fortinet.com)

For Azure support:
- [Azure Support](https://azure.microsoft.com/support/)
- [Azure Documentation](https://docs.microsoft.com/azure/)

---

**Version:** 1.0
**Last Updated:** 2025
**Maintained By:** [Your Organization]
