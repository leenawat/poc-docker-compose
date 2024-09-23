#!/bin/bash

# Set variables
KEYSTORE_FILENAME="kafka.keystore.jks"
VALIDITY=365
KEYSTORE_PASSWORD="keystore_password"
TRUSTSTORE_FILENAME="kafka.truststore.jks"
TRUSTSTORE_PASSWORD="truststore_password"
TRUSTSTORE_PEM="kafka.truststore.pem"
KAFKA_HOSTNAME="kafka"
PRIVATE_KEY_PEM="kafka_private_key.pem"

# Create directory for certificates
mkdir -p certs
cd certs

# Generate CA certificate
keytool -genkeypair -v \
  -alias ca \
  -dname "CN=MyCA,OU=MyUnit,O=MyOrg,L=San Francisco,ST=CA,C=US" \
  -keystore ca.jks \
  -storepass $KEYSTORE_PASSWORD \
  -keypass $KEYSTORE_PASSWORD \
  -keyalg RSA \
  -keysize 4096 \
  -ext KeyUsage:critical="keyCertSign" \
  -ext BasicConstraints:critical="ca:true" \
  -validity $VALIDITY

# Export CA certificate
keytool -export -v \
  -alias ca \
  -file ca.crt \
  -keystore ca.jks \
  -storepass $KEYSTORE_PASSWORD \
  -rfc

# Generate Kafka server keystore
keytool -genkeypair -v \
  -alias $KAFKA_HOSTNAME \
  -dname "CN=$KAFKA_HOSTNAME,OU=MyUnit,O=MyOrg,L=San Francisco,ST=CA,C=US" \
  -keystore $KEYSTORE_FILENAME \
  -storepass $KEYSTORE_PASSWORD \
  -keypass $KEYSTORE_PASSWORD \
  -keyalg RSA \
  -keysize 2048 \
  -validity $VALIDITY

# Create certificate signing request (CSR)
keytool -certreq -v \
  -alias $KAFKA_HOSTNAME \
  -keystore $KEYSTORE_FILENAME \
  -file kafka.csr \
  -storepass $KEYSTORE_PASSWORD \
  -keypass $KEYSTORE_PASSWORD

# Sign the CSR with the CA
keytool -gencert -v \
  -alias ca \
  -keystore ca.jks \
  -infile kafka.csr \
  -outfile kafka.crt \
  -storepass $KEYSTORE_PASSWORD \
  -ext KeyUsage:critical="digitalSignature,keyEncipherment" \
  -ext ExtendedKeyUsage="serverAuth,clientAuth" \
  -ext SAN="DNS:$KAFKA_HOSTNAME,DNS:localhost,IP:127.0.0.1" \
  -rfc

# Import CA certificate to server keystore
keytool -import -v \
  -alias ca \
  -file ca.crt \
  -keystore $KEYSTORE_FILENAME \
  -storepass $KEYSTORE_PASSWORD \
  -keypass $KEYSTORE_PASSWORD \
  -noprompt

# Import signed certificate to server keystore
keytool -import -v \
  -alias $KAFKA_HOSTNAME \
  -file kafka.crt \
  -keystore $KEYSTORE_FILENAME \
  -storepass $KEYSTORE_PASSWORD \
  -keypass $KEYSTORE_PASSWORD

# Create truststore and import the CA certificate
keytool -import -v \
  -alias ca \
  -file ca.crt \
  -keystore $TRUSTSTORE_FILENAME \
  -storepass $TRUSTSTORE_PASSWORD \
  -noprompt

# Export the Kafka private key and certificate to a PKCS12 (.p12) file
keytool -importkeystore -srckeystore $KEYSTORE_FILENAME -destkeystore kafka-keystore.p12 -deststoretype PKCS12 \
  -srcalias $KAFKA_HOSTNAME \
  -deststorepass $KEYSTORE_PASSWORD \
  -destkeypass $KEYSTORE_PASSWORD \
  -srcstorepass $KEYSTORE_PASSWORD \
  -srckeypass $KEYSTORE_PASSWORD

# Extract the private key from the PKCS12 file using OpenSSL
openssl pkcs12 -in kafka-keystore.p12 -nocerts -out $PRIVATE_KEY_PEM -nodes -passin pass:$KEYSTORE_PASSWORD

# Optional: Convert private key to remove password protection (if necessary)
# openssl rsa -in $PRIVATE_KEY_PEM -out kafka_private_key_nopass.pem

echo "SSL certificates, keystores, and private key have been generated."
echo "Keystore: $KEYSTORE_FILENAME"
echo "Truststore: $TRUSTSTORE_FILENAME"
echo "Private Key (PEM): $PRIVATE_KEY_PEM"
echo "Keystore password: $KEYSTORE_PASSWORD"
echo "Truststore password: $TRUSTSTORE_PASSWORD"
