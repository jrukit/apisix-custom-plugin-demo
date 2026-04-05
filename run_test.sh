#!/bin/bash

SPEC_FILE=$(basename "$1")

CONTAINER_ID=$(docker ps -q -f name=apisix)

if [ -z "$CONTAINER_ID" ]; then
    echo "Error: APISIX container is not running."
    exit 1
fi

RUN_COVERAGE=false
if [ "$2" == "-c" ] || [ "$2" == "--coverage" ]; then
    RUN_COVERAGE=true
fi

if [ "$RUN_COVERAGE" = true ]; then
    docker exec -it $CONTAINER_ID sh -c "
        echo \"return { exclude = {'spec/.*', 'usr/.*'} }\" > .luacov && \
        rm -f luacov.stats.out luacov.report.out && \
        busted --lua=resty --coverage -o gtest /opt/spec/$SPEC_FILE && \
        luacov && \
        echo '\n--- Coverage Report ---' && \
        cat luacov.report.out
    " 2>&1 | sed -n '/--- Coverage Report ---/,$p'
else
    docker exec -it $CONTAINER_ID sh -c "
        busted --lua=resty -o gtest /opt/spec/$SPEC_FILE
    " 2>&1 | sed '/_G write guard/,/context: ngx.timer/d'
fi