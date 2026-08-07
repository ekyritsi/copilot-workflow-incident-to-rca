#!/usr/bin/env bash
set -euo pipefail

: "${RESOURCE_GROUP:?Set RESOURCE_GROUP, for example rg-copilot-incident-demo}"
: "${CONTAINER_APP_NAME:?Set CONTAINER_APP_NAME to the Container App name}"

echo "Resetting the demo application to healthy mode..."
az containerapp update \
  --resource-group "$RESOURCE_GROUP" \
  --name "$CONTAINER_APP_NAME" \
  --set-env-vars DEMO_FAILURE_MODE=healthy \
  --output none

echo "Healthy mode restored."
