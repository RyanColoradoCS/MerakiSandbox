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

# Print orgs - Only 1 org in my account, but this is how you would get them all
orgs = dashboard.organizations.getOrganizations()
print(f"Found {len(orgs)} org(s):")
for org in orgs:
    print(f"- {org['name']} (id={org['id']})")

# I have one org, print networks in the first org
if orgs:
    org_id = orgs[0]["id"]
    nets = dashboard.organizations.getOrganizationNetworks(org_id)
    print(f"\nNetworks in '{orgs[0]['name']}' ({len(nets)}):")
    for n in nets:
        print(f"- {n['name']} (id={n['id']}, productTypes={n.get('productTypes')})")