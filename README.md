# Meraki Multi-Site Terraform Lab

This project uses Terraform and the Cisco Meraki provider to automatically deploy and configure multiple Meraki branch networks.

The design allows deploying multiple sites from one Terraform codebase while optionally focusing on one site at a time.

This structure also scales well for environments with dozens or hundreds of Meraki sites.

The current configuration creates:
Meraki networks / Sites
VLAN interfaces
Inter-VLAN firewall isolation rules
Wireless SSIDs
Optional device adoption (MX)

# Project Goals

This lab demonstrates how to:
Automate Meraki infrastructure with Terraform
Deploy multiple branch networks from one configuration
Generate VLAN firewall isolation rules
Adopt devices in Terraform
Manage sites individually using separate tfvars files

# Project Structure

terraform-lab/
│
├── main.tf
├── variables.tf
├── README.md
│
├── sites/
│   ├── site1.tfvars
│   ├── site2.tfvars
│   ├── site3.tfvars
│   ├── site4.tfvars
│   └── site5.tfvars
│
└── .gitignore
What Terraform Creates

For each site Terraform will:
- Create a Meraki Network
- Enable VLANs
- Create VLAN Interfaces

Example VLANs deployed per site:

VLAN	Name	Purpose
100	Management	Device management
10	Server	Servers
20	Workstations	User devices
40	IoT	IoT / OT devices
50	Voice	VoIP phones
60	Printers	Printer network
70	PCN	Private control network
80	Guest	Guest network
90	InfoSec	Security tools
4️⃣ Generate Firewall Rules Automatically

Terraform dynamically builds rules to block communication between all VLANs.

Example generated rule:
Deny Workstations to Server
Deny Server to Guest
Deny IoT to Printers

Then a final rule allows all other traffic: Allow everything else

- Configure Wireless
- Creates SSID 0 on each site.
- Terraform will claim the device into the network:
- Sites without devices still receive configuration so hardware can be added later.

# Variables - defined in variables.tf.

Variable	Description
meraki_api_key	Meraki Dashboard API key
org_id	Meraki organization ID
time_zone	Network time zone
ssid_name	WiFi network name
ssid_psk	WiFi password
sites	Map containing site configuration

# Example tfvars and site configuration:

sites = {
  site1 = {
    site_name      = "Lab-Site-1"
    device_serials = ["QQQQ-RRRR-8989"]

    vlans = {
      "100" = { subnet = "10.50.90.0/24", appliance_ip = "10.50.90.1" }
      "10"  = { subnet = "10.50.91.0/24", appliance_ip = "10.50.91.1" }
      "20"  = { subnet = "10.50.92.0/23", appliance_ip = "10.50.92.1" }
    }
  }
}

# Deploying All Sites

Run Terraform with the main tfvars file.

terraform init
terraform validate
terraform plan -var-file="terraform.tfvars"
terraform apply -var-file="terraform.tfvars"
Deploying a Single Site

# Each site can be managed independently.

Example:
terraform plan -var-file="sites/site1.tfvars"
terraform apply -var-file="sites/site1.tfvars"

This allows editing or testing one branch at a time.

# Destroy Infrastructure

To remove resources:
terraform destroy -var-file="terraform.tfvars"

Or per site:

terraform destroy -var-file="sites/site1.tfvars"
Terraform State

Terraform keeps a state file to track resources it creates.

Default state file: terraform.tfstate

The state file stores: 
Meraki network IDs
VLAN IDs
Firewall rule IDs
SSID numbers

DO NOT edit the state file manually.

# Security Concerns

For lab environments the API key can be stored in tfvars.
For production environments it should be stored in:
environment variables
a secrets manager
Terraform Cloud variables

Add this to .gitignore:
*.tfstate
*.tfstate.*
.terraform/
terraform.tfvars

NEVER commit:
API keys
Terraform state
secrets