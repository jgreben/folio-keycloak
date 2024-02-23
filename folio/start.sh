#!/bin/bash
# Wrapper script as docker entrypoint to run configure-realms.sh in parallel to actual kc.sh (the official entrypoint).

if [[ -z "$KC_FOLIO_BE_ADMIN_CLIENT_SECRET" ]]; then
  echo "$(date +%F' '%T,%3N) ERROR [start.sh] Environment variable KC_FOLIO_BE_ADMIN_CLIENT_SECRET is not set, check 
  the configuration"
  exit 1
fi

# Generate BCFKS keystore
/opt/keycloak/bin/folio/keystore.sh &

/opt/keycloak/bin/folio/configure-realms.sh &

if [[ "$FIPS" == "true" ]]; then
  echo "Starting in FIPS mode"
  /opt/keycloak/bin/kc.sh start \
   --optimized --https-key-store-password=${KC_HTTPS_KEY_STORE_PASSWORD} \
   --spi-password-hashing-pbkdf2-sha256-max-padding-length=14 \
   -Djava.security.properties=/opt/keycloak/conf/kc.java.security
else
  echo "Starting in non-FIPS mode"
  /opt/keycloak/bin/kc.sh start --optimized --https-key-store-password=${KC_HTTPS_KEY_STORE_PASSWORD}
fi
