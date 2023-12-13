#!/bin/bash

clientId="$1"
clientSecret="$2"
script="add-manager-client.sh"

foundClient="$(/opt/keycloak/bin/kcadm.sh get clients --fields id,clientId 2>&1 | grep -oP "\"clientId\" : \"\K$clientId")"
echo "$(date +%F' '%T,%3N) INFO  [$script] Found client: '$foundClient'"
if [ "$foundClient" != "$clientId" ]; then
  echo "$(date +%F' '%T,%3N) INFO  [$script] Creating a new admin client [clientId: $clientId]"

  /opt/keycloak/bin/kcadm.sh create clients \
    --target-realm master \
    --set clientId="$clientId" \
    --set serviceAccountsEnabled=true \
    --set publicClient=false \
    --set clientAuthenticatorType=client-secret \
    --set secret="$clientSecret" \
    --set standardFlowEnabled=false \
    &>/dev/null

  /opt/keycloak/bin/kcadm.sh add-roles \
    --uusername service-account-"$clientId" \
    --rolename admin \
    --rolename create-realm \
    &>/dev/null

  echo "$(date +%F' '%T,%3N) INFO  [$script] Admin client '$clientId' has been created successfully"
else
  echo "$(date +%F' '%T,%3N) INFO  [$script] Admin client '$clientId' already exists, skipping client creation"
fi
