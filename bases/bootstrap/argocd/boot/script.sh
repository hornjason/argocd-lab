#!/bin/bash

# Update Identity Secret
clientSecret="${1}"
# convert to base64 for kubesealer
identitySecret=$(echo ${clientSecret} |base64)
