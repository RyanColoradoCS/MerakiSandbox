import os
import meraki

# export MERAKI_DASHBOARD_API_KEY="your_api_key_here"
# python3 meraki-lab/create_network.py

from dotenv import load_dotenv
load_dotenv()

api_key = os.getenv("MERAKI_DASHBOARD_API_KEY")

dashboard = meraki.DashboardAPI(api_key, suppress_logging=True)

orgs = dashboard.organizations.getOrganizations()

for org in orgs:
    print(f"Name: {org['name']}  ID: {org['id']}")