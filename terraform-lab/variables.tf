/*
variables.tf = defines the variable schema 
terraform.tfvars = provides the values 

variables.tf = function parameters 
terraform.tfvars = arguments passed in
*/


###############################################################################
# Meraki API Key
###############################################################################
variable "meraki_api_key" {
  description = "Meraki Dashboard API key. For production move to env vars or a secret store."
  type        = string
  sensitive   = true
}

###############################################################################
# Organization ID
###############################################################################
variable "org_id" {
  description = "Meraki organization ID"
  type        = string
}

###############################################################################
# Time Zone
###############################################################################
variable "time_zone" {
  description = "Time zone for all Meraki sites"
  type        = string
  default     = "America/Chicago"
}

###############################################################################
# WiFi Settings (applies to all sites)
# Editing out because we don't use Meraki Wi-Fi
###############################################################################
# variable "ssid_name" {
#  description = "SSID name"
#  type        = string
# }

# variable "ssid_psk" {
#  description = "SSID password"
#  type        = string
#  sensitive   = true
# }

###############################################################################
# Sites configuration
#
# Each site contains:
# - site_name
# - device_serials (optional)
# - VLAN definitions
###############################################################################
variable "sites" {
  description = "Map of Meraki sites to deploy"

  type = map(object({
    site_name      = string
    device_serials = list(string)

    vlans = map(object({
      subnet       = string
      appliance_ip = string
    }))

    ports = optional(map(object({
      enabled               = bool
      type                  = string
      vlan                  = number
      allowed_vlans         = optional(string)
      drop_untagged_traffic = optional(bool)
    })), {})
  }))
}