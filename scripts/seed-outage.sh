#!/usr/bin/env bash
set -euo pipefail

: "${RESOURCE_GROUP:?Set RESOURCE_GROUP, for example rg-copilot-incident-demo}"
: "${WEBAPP_NAME:?Set WEBAPP_NAME to the App Service name}"

echo "Setting the demo application to outage mode..."
az webapp config appsettings set \
  --resource-group "$RESOURCE_GROUP" \
  --name "$WEBAPP_NAME" \
  --settings DEMO_FAILURE_MODE=outage \
  --output none

echo "Outage seeded. Check the site and /health endpoint, then start the Copilot investigation."

