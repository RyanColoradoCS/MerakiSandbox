import os
import meraki

# export MERAKI_DASHBOARD_API_KEY="your_api_key_here"
# python3 meraki-lab/create_network.py

from dotenv import load_dotenv
load_dotenv()

# Get API key from environment variable
api_key = os.environ.get("MERAKI_DASHBOARD_API_KEY")
if not api_key:
    raise SystemExit("Missing MERAKI_DASHBOARD_API_KEY environment variable.")

dashboard = meraki.DashboardAPI(
    api_key=api_key,
    suppress_logging=True
)

NEW_SITE_NAME = "Site-001-NoTerraform"  # example site name, change as needed

# 1) First org
orgs = dashboard.organizations.getOrganizations()
org_id = orgs[0]["id"]

# 2) Create a new network (site) with Appliance product type
new_net = dashboard.organizations.createOrganizationNetwork(
    org_id,
    name=NEW_SITE_NAME,
    productTypes=["appliance"],
    timeZone="America/Chicago"  # change for where site is located
)

network_id = new_net["id"]
print("Created network:", new_net["name"], network_id)

# 3) Enable VLANs
dashboard.appliance.updateNetworkApplianceVlansSettings(
    network_id,
    vlansEnabled=True
)

# 4) Create the VLANs
vlans = [
    {"id": "10", "name": "Private", "subnet": "10.10.10.0/24", "ip": "10.10.10.1"},
    {"id": "20", "name": "Public",  "subnet": "10.10.20.0/24", "ip": "10.10.20.1"},
]

for v in vlans:
    vlan = dashboard.appliance.createNetworkApplianceVlan(
        network_id,
        v["id"],
        v["name"],
        subnet=v["subnet"],
        applianceIp=v["ip"]
    )
    print("Created VLAN:", vlan["id"], vlan["name"])