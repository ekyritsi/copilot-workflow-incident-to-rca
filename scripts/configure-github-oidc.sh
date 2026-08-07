#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 <github-owner> <github-repository>" >&2
  exit 1
fi

: "${RESOURCE_GROUP:=rg-copilot-incident-demo}"
: "${SUBSCRIPTION_ID:?Set SUBSCRIPTION_ID to the Azure subscription ID}"
: "${TENANT_ID:?Set TENANT_ID to the Microsoft Entra tenant ID}"

github_owner="$1"
github_repository="$2"
identity_name="${github_repository}-actions"
federated_name="github-main"

az account set --subscription "$SUBSCRIPTION_ID"

az identity create \
  --resource-group "$RESOURCE_GROUP" \
  --name "$identity_name" \
  --location "$(az group show --name "$RESOURCE_GROUP" --query location --output tsv)" \
  --output none

client_id="$(az identity show --resource-group "$RESOURCE_GROUP" --name "$identity_name" --query clientId --output tsv)"
principal_id="$(az identity show --resource-group "$RESOURCE_GROUP" --name "$identity_name" --query principalId --output tsv)"

az role assignment create \
  --assignee-object-id "$principal_id" \
  --assignee-principal-type ServicePrincipal \
  --role Contributor \
  --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP" \
  --output none

az identity federated-credential create \
  --resource-group "$RESOURCE_GROUP" \
  --identity-name "$identity_name" \
  --name "$federated_name" \
  --issuer "https://token.actions.githubusercontent.com" \
  --subject "repo:${github_owner}/${github_repository}:ref:refs/heads/main" \
  --audiences "api://AzureADTokenExchange" \
  --output none

web_app_name="$(az deployment group show \
  --resource-group "$RESOURCE_GROUP" \
  --name incident-to-rca \
  --query properties.outputs.webAppName.value \
  --output tsv 2>/dev/null || true)"

cat <<EOF
Configure these GitHub repository variables:

AZURE_CLIENT_ID=$client_id
AZURE_SUBSCRIPTION_ID=$SUBSCRIPTION_ID
AZURE_TENANT_ID=$TENANT_ID
AZURE_RESOURCE_GROUP=$RESOURCE_GROUP
AZURE_WEBAPP_NAME=$web_app_name

The identity currently has Contributor at the demo resource-group scope.
Replace it with a narrower custom role before using this pattern outside the demo.
EOF

