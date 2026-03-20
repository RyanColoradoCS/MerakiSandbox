# How to run - multiple sites
# terraform init
# terraform validate
# terraform plan -var-file="terraform.tfvars"
# terraform apply -var-file="terraform.tfvars"
# terraform destroy -var-file="terraform.tfvars"

# This tf file:
# 1. Creates all 5 sites
# Creates VLAN settings for all 5
# Creates all VLANs for all 5 sites
# Creates firewall rules for all 5
# Creates SSID 0 for all 5
# Only claims a Meraki device for sites where device_serials is not empty.
# This allows you to deploy settings without a Meraki yet.

terraform {
  required_providers {
    meraki = {
      source  = "CiscoDevNet/meraki"
      version = "1.9.0"
    }
  }
}

###############################################################################
# Provider
# Note - This uses var.meraki_api_key. For production, move the API key to environment 
# variables or a secret store.
###############################################################################
provider "meraki" {
  api_key = var.meraki_api_key
}

###############################################################################
# Network / Site
###############################################################################
locals {
  vlan_names = {
    "100" = "Management"
    "10"  = "Server"
    "20"  = "Workstations"
    "40"  = "IoT"
    "50"  = "Voice"
    "60"  = "Printers"
    "70"  = "PCN"
    "80"  = "Guest"
    "90"  = "InfoSec"
  }

  site_vlans = merge([
    for site_key, site in var.sites : {
      for vlan_id, vlan_data in site.vlans : "${site_key}-${vlan_id}" => {
        site_key     = site_key
        vlan_id      = vlan_id
        vlan_name    = lookup(local.vlan_names, vlan_id, "VLAN-${vlan_id}")
        subnet       = vlan_data.subnet
        appliance_ip = vlan_data.appliance_ip
      }
    }
  ]...)

  firewall_rules_by_site = {
    for site_key, site in var.sites : site_key => concat(
      flatten([
        for src_vlan_id, src_vlan in site.vlans : [
          for dst_vlan_id, dst_vlan in site.vlans : {
            comment        = "Deny ${lookup(local.vlan_names, src_vlan_id, src_vlan_id)} to ${lookup(local.vlan_names, dst_vlan_id, dst_vlan_id)}"
            policy         = "deny"
            protocol       = "any"
            src_cidr       = src_vlan.subnet
            src_port       = "Any"
            dest_cidr      = dst_vlan.subnet
            dest_port      = "Any"
            syslog_enabled = false
          } if src_vlan_id != dst_vlan_id
        ]
      ]),
      [
        {
          comment        = "Allow everything else"
          policy         = "allow"
          protocol       = "any"
          src_cidr       = "Any"
          src_port       = "Any"
          dest_cidr      = "Any"
          dest_port      = "Any"
          syslog_enabled = false
        }
      ]
    )
  }
}

resource "meraki_network" "site" {
  for_each = var.sites
  organization_id = var.org_id
  name            = each.value.site_name
  product_types   = ["appliance", "wireless"]
  time_zone       = var.time_zone
}

resource "meraki_network_device_claim" "claim_devices" {
  for_each = {
    for site_key, site in var.sites : site_key => site
    if length(site.device_serials) > 0
  }

  network_id = meraki_network.site[each.key].id
  serials    = each.value.device_serials
}

resource "meraki_appliance_vlans_settings" "vlans_on" {
  for_each = var.sites

  network_id    = meraki_network.site[each.key].id
  vlans_enabled = true
}

resource "meraki_appliance_vlan" "vlans" {
  for_each = local.site_vlans

  network_id   = meraki_network.site[each.value.site_key].id
  vlan_id      = each.value.vlan_id
  name         = each.value.vlan_name
  subnet       = each.value.subnet
  appliance_ip = each.value.appliance_ip

  depends_on = [meraki_appliance_vlans_settings.vlans_on]
}

resource "meraki_appliance_l3_firewall_rules" "isolate_all_vlans" {
  for_each = var.sites

  network_id = meraki_network.site[each.key].id
  rules      = local.firewall_rules_by_site[each.key]
}

/*
resource "meraki_wireless_ssid" "ssid0" {
  for_each = var.sites

  network_id = meraki_network.site[each.key].id
  number     = 0

  name    = var.ssid_name
  enabled = true

  auth_mode       = "psk"
  encryption_mode = "wpa"
  psk             = var.ssid_psk
}
*/

###############################################################################
# Enable VLANs on the MX
# Example shape for MX appliance ports
# Set all of the Meraki ports to VLAN 100
# I haven't figured out how to do this yet
###############################################################################
resource "meraki_appliance_ports" "mx64_lan_ports" {
  for_each = {
    for k, v in var.sites : k => v
    if length(v.ports) > 0
  }

  organization_id = var.org_id
  network_id      = meraki_network.site[each.key].id

  items = [
    for port_id, port in each.value.ports : {
      port_id               = port_id
      enabled               = port.enabled
      type                  = port.type
      vlan                  = port.vlan
      allowed_vlans         = try(port.allowed_vlans, null)
      drop_untagged_traffic = try(port.drop_untagged_traffic, null)
    }
  ]
}