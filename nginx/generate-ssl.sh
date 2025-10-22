#!/bin/bash

# This script generates a self-signed SSL certificate for local development.

# Create a directory for the SSL certs if it doesn't exist
mkdir -p ssl

# Generate the SSL certificate and key using openssl
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout ssl/nginx.key \
  -out ssl/nginx.crt \
  -subj "/C=eg/ST=cairo/L=cairo/O=MyProject/CN=localhost"

echo "✅ SSL certificate and key generated successfully in the 'ssl/' directory."
