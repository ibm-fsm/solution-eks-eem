#!/bin/bash
set -e

# 1. Pre-flight Checks
if ! command -v jq &> /dev/null; then
    echo "ERROR: jq could not be found. Please install jq on the runner."
    exit 1
fi

if [ -z "$EEM_API_URL" ] || [ -z "$ACCESS_TOKEN" ] || [ -z "$CLUSTER_ID" ] || [ -z "$DATA_PRODUCTS_DIR" ]; then
    echo "ERROR: Missing required environment variables."
    exit 1
fi

echo "========================================================================="
echo " EEM Data Product Registration (Topics & Options) "
echo "========================================================================="
echo "> Target Cluster ID: $CLUSTER_ID"

# 2. Iterate over all Data Product directories
for PRODUCT_DIR in "$DATA_PRODUCTS_DIR"/*/; do
    # Ensure it's actually a directory
    [ -d "$PRODUCT_DIR" ] || continue
    
    PRODUCT_NAME=$(basename "$PRODUCT_DIR")
    echo "-------------------------------------------------------------------------"
    echo ">> Processing Data Product: $PRODUCT_NAME"
    
    TOPIC_FILE="${PRODUCT_DIR}topic.json"
    
    if [ ! -f "$TOPIC_FILE" ]; then
        echo "   [WARNING] No topic.json found in $PRODUCT_NAME. Skipping."
        continue
    fi

    # ==========================================
    # PHASE A: TOPIC REGISTRATION
    # ==========================================
    
    # Inject the CLUSTER_ID into the JSON safely without breaking formatting
    sed "s|CLUSTERID|$CLUSTER_ID|g" "$TOPIC_FILE" > "/tmp/topic-request.json"
    
    # Read the expected name so we can look it up if a 409 occurs
    EXPECTED_TOPIC_NAME=$(jq -r '.name' "/tmp/topic-request.json")
    echo "   -> Registering Topic: $EXPECTED_TOPIC_NAME"

    HTTP_STATUS=$(curl -s -k -o /tmp/topic_response.json -w "%{http_code}" -X POST "$EEM_API_URL/eem/eventsources" \
        -H 'Accept: application/json' \
        -H 'Content-Type: application/json' \
        -H "Authorization: Bearer $ACCESS_TOKEN" \
        -d "@/tmp/topic-request.json")

    if [ "$HTTP_STATUS" == "409" ]; then
        echo "      Topic already exists. Fetching existing Topic ID..."
        ALL_TOPICS=$(curl -s -k -X GET "$EEM_API_URL/eem/eventsources" \
            -H 'Accept: application/json' \
            -H "Authorization: Bearer $ACCESS_TOKEN")
        
        TOPIC_ID=$(echo "$ALL_TOPICS" | jq -r ".[] | select(.name == \"$EXPECTED_TOPIC_NAME\") | .id")
        
    elif [ "$HTTP_STATUS" == "200" ] || [ "$HTTP_STATUS" == "201" ]; then
        echo "      Topic registered successfully."
        TOPIC_ID=$(jq -r '.id' /tmp/topic_response.json)
    else
        echo "   [ERROR] Failed to register topic $EXPECTED_TOPIC_NAME. HTTP Status: $HTTP_STATUS"
        cat /tmp/topic_response.json
        exit 1
    fi

    if [ -z "$TOPIC_ID" ] || [ "$TOPIC_ID" == "null" ]; then
        echo "   [ERROR] Failed to obtain a valid Topic ID."
        exit 1
    fi

    echo "   -> Active Topic ID: $TOPIC_ID"

    # ==========================================
    # PHASE B: OPTIONS REGISTRATION
    # ==========================================
    
    OPTIONS_DIR="${PRODUCT_DIR}options"
    if [ -d "$OPTIONS_DIR" ]; then
        
        # Loop over any .json or .tpl files in the options directory
        for OPTION_FILE in "$OPTIONS_DIR"/*.json "$OPTIONS_DIR"/*.tpl; do
            [ -e "$OPTION_FILE" ] || continue
            
            OPTION_FILENAME=$(basename "$OPTION_FILE")
            
            # Inject the dynamically retrieved TOPIC_ID into the Option JSON
            sed "s|EVENTSOURCEID|$TOPIC_ID|g" "$OPTION_FILE" > "/tmp/option-request.json"
            
            EXPECTED_OPTION_NAME=$(jq -r '.name' "/tmp/option-request.json")
            echo "      -> Registering Option: $EXPECTED_OPTION_NAME"

            OPT_HTTP_STATUS=$(curl -s -k -o /tmp/option_response.json -w "%{http_code}" -X POST "$EEM_API_URL/eem/options" \
                -H 'Accept: application/json' \
                -H 'Content-Type: application/json' \
                -H "Authorization: Bearer $ACCESS_TOKEN" \
                -d "@/tmp/option-request.json")

            if [ "$OPT_HTTP_STATUS" == "409" ]; then
                echo "         Option already exists. Skipping."
                # Unlike the topic, we usually don't need the Option ID for a downstream dependency, 
                # so skipping on 409 is perfectly safe here.
            elif [ "$OPT_HTTP_STATUS" == "200" ] || [ "$OPT_HTTP_STATUS" == "201" ]; then
                echo "         Option registered successfully."
            else
                echo "         [ERROR] Failed to register option $EXPECTED_OPTION_NAME. HTTP Status: $OPT_HTTP_STATUS"
                cat /tmp/option_response.json
                exit 1
            fi
        done
    else
        echo "   -> No 'options' directory found for $PRODUCT_NAME."
    fi
done

echo "========================================================================="
echo ""