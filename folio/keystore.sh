#!/bin/bash
# Using self-signed certificates is for dev purposes only,
# so replace these certificates with proper certificates when moving to a production environment.

script="keystore.sh"
keycloakHost="${KC_HOSTNAME}"
keypass="${KC_HTTPS_KEY_STORE_PASSWORD}"
keystore=/opt/keycloak/conf/server.keystore

function generateKeystore() {
  if test -f "$keystore"; then
    if checkKeystore; then
      echo "$(date +%F' '%T,%3N) INFO  [$script] Keystore $keystore exists."
      return 0;
    else
      echo "$(date +%F' '%T,%3N) INFO  [$script] Keystore password is invalid. Re-creating keystore."
      rm $keystore
    fi
  fi

  if [ "$FIPS" = "true" ]; then
    keytool -keystore $keystore \
      -storetype BCFKS \
      -providername BCFIPS \
      -providerclass org.bouncycastle.jcajce.provider.BouncyCastleFipsProvider \
      -provider org.bouncycastle.jcajce.provider.BouncyCastleFipsProvider \
      -providerpath /opt/keycloak/providers/bc-fips-*.jar \
      -alias "$keycloakHost" \
      -genkeypair -sigalg SHA512withRSA -keyalg RSA -storepass "$keypass" \
      -dname CN="$keycloakHost" -keypass "$keypass" \
      -J-Djava.security.properties=/tmp/kc.keystore-create.java.security
  else
    keytool -genkeypair -alias "$keycloakHost" \
      -keyalg RSA \
      -keysize 2048 \
      -validity 365 \
      -keystore $keystore \
      -dname "CN=$keycloakHost" \
      -storepass "$keypass"
  fi
}

function checkKeystore() {
  if [ "$FIPS" = "true" ]; then
    keytool -list -keystore $keystore \
      -storetype BCFKS \
      -providername BCFIPS \
      -providerclass org.bouncycastle.jcajce.provider.BouncyCastleFipsProvider \
      -provider org.bouncycastle.jcajce.provider.BouncyCastleFipsProvider \
      -providerpath /opt/keycloak/providers/bc-fips-*.jar \
      -storepass "$keypass" \
      -J-Djava.security.properties=/tmp/kc.keystore-create.java.security
  else
    keytool -list -keystore $keystore \
      -storepass "$keypass"
  fi
}

echo "$(date +%F' '%T,%3N) INFO  [$script] Generating  keystore for hostname: '$keycloakHost'"
if generateKeystore; then
  echo "$(date +%F' '%T,%3N) INFO  [$script]  keystore generation finished."
fi