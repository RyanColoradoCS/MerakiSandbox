terraform {
  required_providers {
    meraki = {
      source  = "CiscoDevNet/meraki"
      version = "1.9.0"
    }
  }
}

provider "meraki" {
  api_key = var.meraki_api_key
}

# Site / Network
resource "meraki_network" "site" {
  organization_id = var.org_id
  name            = var.site_name
  product_types   = ["appliance", "wireless"]
  time_zone       = "America/Chicago"
}

# Create VLANs
resource "meraki_appliance_vlans_settings" "vlans_on" {
  network_id    = meraki_network.site.id
  vlans_enabled = true
}

resource "meraki_appliance_vlan" "private" {
  network_id   = meraki_network.site.id
  vlan_id      = "10"
  name         = "Private"
  subnet       = "10.10.10.0/24"
  appliance_ip = "10.10.10.1"

  depends_on = [meraki_appliance_vlans_settings.vlans_on]
}

resource "meraki_appliance_vlan" "public" {
  network_id   = meraki_network.site.id
  vlan_id      = "20"
  name         = "Public"
  subnet       = "10.10.20.0/24"
  appliance_ip = "10.10.20.1"

  depends_on = [meraki_appliance_vlans_settings.vlans_on]
}

# MX layer 3 FIREWALL for inter-VLAN isolation ---
resource "meraki_appliance_l3_firewall_rules" "isolate_vlans" {
  network_id = meraki_network.site.id

  rules = [
    {
      comment        = "Block Private to Public"
      policy         = "deny"
      protocol       = "any"
      src_cidr       = "10.10.10.0/24"
      src_port       = "Any"
      dest_cidr      = "10.10.20.0/24"
      dest_port      = "Any"
      syslog_enabled = false
    },
    {
      comment        = "Block Public to Private"
      policy         = "deny"
      protocol       = "any"
      src_cidr       = "10.10.20.0/24"
      src_port       = "Any"
      dest_cidr      = "10.10.10.0/24"
      dest_port      = "Any"
      syslog_enabled = false
    },
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
}

#  WIFI SSID (slot 0)
resource "meraki_wireless_ssid" "ssid0" {
  network_id = meraki_network.site.id
  number     = 0

  name    = var.ssid_name
  enabled = true

  auth_mode       = "psk"
  encryption_mode = "wpa"
  psk             = var.ssid_psk
}