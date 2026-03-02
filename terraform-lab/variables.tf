variable "org_id" { type = string }

variable "site_name" {
  type    = string
  default = "TF-Site-001"
}

variable "ssid_name" {
  type    = string
  default = "TF-WiFi"
}

variable "ssid_psk" {
  type      = string
  sensitive = true
}

variable "meraki_api_key" {
  type      = string
  sensitive = true
}