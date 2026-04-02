#!/bin/bash

SPEC_FILE=$(basename "$1")

CONTAINER_ID=$(docker ps -q -f name=apisix)

if [ -z "$CONTAINER_ID" ]; then
    echo "Error: APISIX container is not running."
    exit 1
fi

docker exec -it $CONTAINER_ID sh -c "
    busted --lua=resty -o gtest /opt/spec/$SPEC_FILE
" 2>&1 | sed '/_G write guard/,/context: ngx.timer/d'