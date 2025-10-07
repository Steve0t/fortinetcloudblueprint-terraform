#####################################################################
# Data Sources
#####################################################################

# Get the current public IP of the machine running Terraform (only if not manually specified)
data "http" "my_public_ip" {
  count = var.my_public_ip == "" ? 1 : 0
  url   = "https://api.ipify.org?format=text"
}
