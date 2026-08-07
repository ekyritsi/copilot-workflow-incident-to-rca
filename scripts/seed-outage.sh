#!/usr/bin/env bash
set -euo pipefail

: "${RESOURCE_GROUP:?Set RESOURCE_GROUP, for example rg-copilot-incident-demo}"
: "${CONTAINER_APP_NAME:?Set CONTAINER_APP_NAME to the Container App name}"

echo "Setting the demo application to outage mode..."
az containerapp update \
  --resource-group "$RESOURCE_GROUP" \
  --name "$CONTAINER_APP_NAME" \
  --set-env-vars DEMO_FAILURE_MODE=outage \
  --output none

echo "Outage seeded. Check the site and /health endpoint, then start the Copilot investigation."
