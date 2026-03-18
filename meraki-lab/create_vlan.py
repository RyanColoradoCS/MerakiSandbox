import os
import meraki

# Get API key from environment variable
api_key = os.environ.get("MERAKI_DASHBOARD_API_KEY")
if not api_key:
    raise SystemExit("Missing MERAKI_DASHBOARD_API_KEY environment variable.")

dashboard = meraki.DashboardAPI(
    api_key=api_key,
    suppress_logging=True
)

# Get first org - I only have one 
orgs = dashboard.organizations.getOrganizations()
org_id = orgs[0]["id"]

# Get first network
networks = dashboard.organizations.getOrganizationNetworks(org_id)
network_id = networks[0]["id"]

print("Using network:", networks[0]["name"])

# Enable VLANs
dashboard.appliance.updateNetworkApplianceVlansSettings(
    network_id,
    vlansEnabled=True
)

# Create VLAN 10 named Private
response = dashboard.appliance.createNetworkApplianceVlan(
    network_id,
    "80",                     # VLAN ID
    "Servers",                # Name
    subnet="10.10.80.0/24",   # Subnet
    applianceIp="10.10.80.1"  # Gateway IP
)

print("Created VLAN:")
print(response)