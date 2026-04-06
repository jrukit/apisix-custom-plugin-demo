#!/bin/bash

GOLD='\033[38;5;220m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color
RED='\033[38;5;196m'

ICON_TEST="🧪"
ICON_LOG="📝"
ICON_WAIT="⏳"
ICON_ERROR="❌"
ICON_SUCCESS="✅"

CONTAINER_NAME="apisix"
SPEC_FILE=$(basename "$2")
CONTAINER_ID=$(docker ps -q -f name=$CONTAINER_NAME)

case "$1" in
    "up")
        clear
        echo -e "${GOLD}${BOLD}"
        echo "      ███████╗ █████╗ ██████╗ ██╗  ██╗██╗   ██╗"
        echo "      ██╔════╝██╔══██╗██╔══██╗██║  ██║██║   ██║"
        echo "      ███████╗███████║██║  ██║███████║██║   ██║"
        echo "      ╚════██║██╔══██║██║  ██║██╔══██║██║   ██║"
        echo "      ███████║██║  ██║██████╔╝██║  ██║╚██████╔╝"
        echo "      ╚══════╝╚═╝  ╚═╝╚═════╝ ╚═╝  ╚═╝ ╚═════╝ "
        echo -e "         ${GREY}--- G A T E W A Y B L E S S E D ---${NC}"
        echo -e ""
        echo -e ""
        echo -e "${GOLD}  ──────────────────────────────────────────────────────────${NC}"
        echo -e "    ${GOLD}Prophecy:${NC} ${GREY}\"Commit with faith, Deploy with hope.\"${NC}"
        echo -e "    ${GOLD}Ritual:${NC}   ${GREY}Cleansing legacy sins from your local cache.${NC}"
        echo -e "${GOLD}  ──────────────────────────────────────────────────────────${NC}"
        docker-compose down && docker-compose up -d
        echo -en "${YELLOW}${ICON_WAIT} Waiting for APISIX readiness...${NC} "
        for i in {1..5}; do echo -n "."; sleep 1; done
        echo -e " ${GREEN}${ICON_SUCCESS} Ready!${NC}"
        ;;

    "down")
        clear
        echo -e "${GREY}${BOLD}"
        echo "      ███████╗ █████╗ ██████╗ ██╗  ██╗██╗   ██╗"
        echo "      ██╔════╝██╔══██╗██╔══██╗██║  ██║██║   ██║"
        echo "      ███████╗███████║██║  ██║███████║██║   ██║"
        echo "      ╚════██║██╔══██║██║  ██║██╔══██║██║   ██║"
        echo "      ███████║██║  ██║██████╔╝██║  ██║╚██████╔╝"
        echo "      ╚══════╝╚═╝  ╚═╝╚═════╝ ╚═╝  ╚═╝ ╚═════╝ "
        echo -e "               ${GREY}--- G A T E W A Y B L E S S E D ---${NC}"
        echo -e ""
        echo -e "${RED}  ──────────────────────────────────────────────────────────${NC}"
        echo -e "    ${RED}Status:${NC}   ${WHITE}Closing the Temple (Docker Down)${NC}"
        echo -e "    ${RED}Prophecy:${NC} ${GREY}\"Go home, your bugs will wait for you tomorrow.\"${NC}"
        echo -e "${RED}  ──────────────────────────────────────────────────────────${NC}"
        
        docker-compose down
        ;;

    "run")
        if [ -z "$CONTAINER_ID" ]; then
            echo "Error: Environment is down. Run 'up' first.";
            exit 1;
        fi
        echo -e "${CYAN}${BOLD}${ICON_TEST} [Sadhu] Running: ${SPEC_FILE}${NC}"

        if [ "$3" == "-c" ] || [ "$3" == "--coverage" ]; then
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
        ;;

    "tail")
        if [ -z "$CONTAINER_ID" ]; then
            echo -e "${RED}${ICON_ERROR} Error: APISIX is not running.${NC}"
            exit 1;
        fi
        echo -e "${MAGENTA}${BOLD}${ICON_LOG} [Sadhu] Tailing Recent Logs (Press Ctrl+C to stop)${NC}"
        echo -e "${CYAN}------------------------------------------------------------${NC}"
        docker logs --tail 50 -f $CONTAINER_ID
        ;;

    *)
        echo -e "Usage: sadhu ${GREEN}<command>${NC} [options]"
        echo -e ""
        echo -e "Commands:"
        echo -e "  ${GREEN}up${NC}                  Reset & Start APISIX environment"
        echo -e "  ${GREEN}down${NC}                Close APISIX environment"
        echo -e "  ${GREEN}run${NC}     <file>      Execute Busted tests (add -c for coverage)"
        echo -e "  ${GREEN}tail${NC}                Follow APISIX docker logs"
        exit 1
        ;;
esac