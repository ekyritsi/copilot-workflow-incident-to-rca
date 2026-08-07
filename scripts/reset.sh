#!/usr/bin/env bash
set -euo pipefail

: "${RESOURCE_GROUP:?Set RESOURCE_GROUP, for example rg-copilot-incident-demo}"
: "${WEBAPP_NAME:?Set WEBAPP_NAME to the App Service name}"

echo "Resetting the demo application to healthy mode..."
az webapp config appsettings set \
  --resource-group "$RESOURCE_GROUP" \
  --name "$WEBAPP_NAME" \
  --settings DEMO_FAILURE_MODE=healthy \
  --output none

echo "Healthy mode restored."

