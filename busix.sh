#!/bin/bash

BOLD='\033[1m'
CYAN='\033[38;5;51m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color
RED='\033[38;5;196m'
SLATE='\033[38;5;244m'

ICON_TEST="🧪"
ICON_LOG="📝"
ICON_ERROR="❌"

CONTAINER_NAME="apisix"
CONTAINER_ID=$(docker ps -q -f name=$CONTAINER_NAME)

case "$1" in
    "up")
        docker-compose down && docker-compose up -d
        ;;

    "down")
        docker-compose down
        ;;

    "run")
        if [[ "$2" == -* ]] || [ -z "$2" ]; then
            SPEC_FILE=""
        else
            SPEC_FILE=$(basename "$2")
        fi

        if [ -z "$CONTAINER_ID" ]; then
            echo -e "${RED}${ICON_ERROR} Error: BUSIX is down. Run 'up' first.${NC}"
            exit 1;
        fi

        echo -e "${CYAN}${BOLD}${ICON_TEST} [Busix] Running: ${SPEC_FILE}${NC}"

        if [ "$2" == "-c" ] || [ "$3" == "-c" ]; then
            docker exec -it $CONTAINER_ID sh -c "
                cd /opt/apisix && \
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
        ;;

    "tail")
        if [ -z "$CONTAINER_ID" ]; then
            echo -e "${RED}${ICON_ERROR} Error: BUSIX is down. Run 'up' first.${NC}"
            exit 1;
        fi

        echo -e "${CYAN}${BOLD}${ICON_LOG} [Busix] Tailing Recent Logs (Press Ctrl+C to stop)${NC}"
        echo -e "${CYAN}------------------------------------------------------------${NC}"
        docker logs --tail 50 -f $CONTAINER_ID
        ;;

    *)
        echo -e "${CYAN}${BOLD}"
        echo "      ██████╗ ██╗   ██╗███████╗██╗██╗  ██╗"
        echo "      ██╔══██╗██║   ██║██╔════╝██║╚██╗██╔╝"
        echo "      ██████╔╝██║   ██║███████╗██║ ╚███╔╝ "
        echo "      ██╔══██╗██║   ██║╚════██║██║ ██╔██╗ "
        echo "      ██████╔╝╚██████╔╝███████║██║██╔╝ ██╗"
        echo "      ╚═════╝  ╚═════╝ ╚══════╝╚═╝╚═╝  ╚═╝"
        echo -e "         ${SLATE}SYSTEM QUALITY :: TRUST ME BRO${NC}"
        echo -e ""
        echo -e "${CYAN}──────────────────────────────────────────────────────────${NC}"
        echo -e "Usage: busix ${GREEN}<command>${NC} [options]"
        echo -e ""
        echo -e "Commands:"
        echo -e "  ${GREEN}up${NC}                  Reset & Start APISIX environment"
        echo -e "  ${GREEN}down${NC}                Close APISIX environment"
        echo -e "  ${GREEN}run${NC}     <file>      Execute Busted tests (add -c for coverage)"
        echo -e "  ${GREEN}tail${NC}                Follow APISIX docker logs"
        exit 1
        ;;
esac