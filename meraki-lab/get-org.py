import os
import meraki

api_key = os.getenv("MERAKI_DASHBOARD_API_KEY")

dashboard = meraki.DashboardAPI(api_key, suppress_logging=True)

orgs = dashboard.organizations.getOrganizations()

for org in orgs:
    print(f"Name: {org['name']}  ID: {org['id']}")