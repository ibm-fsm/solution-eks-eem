#!/bin/bash
set -e
set -x

# Ensure jq is installed (required for parsing API responses safely)
if ! command -v jq &> /dev/null; then
    echo "jq could not be found. Please install jq on the runner."
    exit 1
fi

echo "========================================================================="
echo " EEM Kafka Cluster & Topic Registration (Idempotent) "
echo "========================================================================="

# 1. Register the Cluster (Idempotent Check)
echo "> Checking if cluster exists..."

# Tell curl to output the HTTP status code to a variable, and save the body to a temp file
HTTP_STATUS=$(curl -s -k -o /tmp/cluster_response.json -w "%{http_code}" -X POST "$EEM_API_URL/eem/clusters" \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -d "@${CLUSTER_PAYLOAD_PATH}")

if [ "$HTTP_STATUS" == "409" ]; then
    echo "> Cluster already exists. Fetching existing Cluster ID..."
    
    # Read the expected name from our rendered JSON payload
    EXPECTED_NAME=$(jq -r '.name' "$CLUSTER_PAYLOAD_PATH")
    
    # GET all clusters
    ALL_CLUSTERS=$(curl -s -k -X GET "$EEM_API_URL/eem/clusters" \
      -H 'Accept: application/json' \
      -H "Authorization: Bearer $ACCESS_TOKEN")
      
    # Use jq to find the exact cluster ID that matches our name
    CLUSTERID=$(echo "$ALL_CLUSTERS" | jq -r ".[] | select(.name == \"$EXPECTED_NAME\") | .id")

elif [ "$HTTP_STATUS" == "200" ] || [ "$HTTP_STATUS" == "201" ]; then
    echo "> Cluster registered successfully."
    CLUSTERID=$(jq -r '.id' /tmp/cluster_response.json)
    
else
    echo "ERROR: Failed to register cluster. HTTP Status: $HTTP_STATUS"
    cat /tmp/cluster_response.json
    exit 1
fi

if [ -z "$CLUSTERID" ] || [ "$CLUSTERID" == "null" ]; then
    echo "ERROR: Failed to obtain a valid Cluster ID."
    exit 1
fi

echo "> Using Cluster ID: $CLUSTERID"

echo "========================================================================="
echo " Registration Complete "
echo "========================================================================="