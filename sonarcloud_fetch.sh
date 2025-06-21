#!/bin/bash

# SonarCloud Issues Fetcher - Bash Version
# Compatible with Mac/Linux systems

# Default values
ORGANIZATION="w159"
PROJECT_KEY="w159_unstract"
OUTPUT_FILE="sonarcloud_issues_$(date +%Y%m%d_%H%M%S).csv"
PAGE_SIZE=500
API_TOKEN=""
INCLUDE_CLOSED=false

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to display usage
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  -t, --token TOKEN        SonarCloud API token (or set SONARCLOUD_TOKEN env var)"
    echo "  -o, --output FILE        Output CSV file (default: sonarcloud_issues_TIMESTAMP.csv)"
    echo "  -p, --project KEY        Project key (default: w159_unstract)"
    echo "  -g, --org ORGANIZATION   Organization (default: w159)"
    echo "  -c, --include-closed     Include closed issues"
    echo "  -h, --help              Show this help message"
    exit 1
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--token)
            API_TOKEN="$2"
            shift 2
            ;;
        -o|--output)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        -p|--project)
            PROJECT_KEY="$2"
            shift 2
            ;;
        -g|--org)
            ORGANIZATION="$2"
            shift 2
            ;;
        -c|--include-closed)
            INCLUDE_CLOSED=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
done

# Check for API token
if [ -z "$API_TOKEN" ]; then
    API_TOKEN="$SONARCLOUD_TOKEN"
fi

if [ -z "$API_TOKEN" ]; then
    # Try to read from saved token file
    TOKEN_FILE="$HOME/.sonarcloud_token"
    if [ -f "$TOKEN_FILE" ]; then
        API_TOKEN=$(cat "$TOKEN_FILE")
        echo -e "${GREEN}Using saved API token${NC}"
    else
        echo -e "${YELLOW}API Token Required${NC}"
        echo "Generate a token at: https://sonarcloud.io/account/security"
        echo -n "Enter your SonarCloud API token: "
        read -s API_TOKEN
        echo
        
        # Offer to save token
        echo -n "Save token for future use? (y/n): "
        read -n 1 SAVE_TOKEN
        echo
        if [[ "$SAVE_TOKEN" == "y" || "$SAVE_TOKEN" == "Y" ]]; then
            echo "$API_TOKEN" > "$TOKEN_FILE"
            chmod 600 "$TOKEN_FILE"
            echo -e "${GREEN}Token saved to $TOKEN_FILE${NC}"
        fi
    fi
fi

# Validate token
echo -n "Validating API token..."
VALIDATE_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" \
    -H "Authorization: Bearer $API_TOKEN" \
    "https://sonarcloud.io/api/organizations/search?organizations=$ORGANIZATION")

if [ "$VALIDATE_RESPONSE" -ne 200 ]; then
    echo -e " ${RED}Failed!${NC}"
    echo "Invalid API token or no access to organization"
    exit 1
fi
echo -e " ${GREEN}Valid!${NC}"

# Set issue statuses
if [ "$INCLUDE_CLOSED" = true ]; then
    STATUSES="OPEN,CONFIRMED,REOPENED,RESOLVED,CLOSED"
else
    STATUSES="OPEN,CONFIRMED,REOPENED"
fi

# Initialize variables
PAGE=1
TOTAL_ISSUES=0
ALL_ISSUES=""

echo -e "\n${CYAN}Fetching issues from project: $PROJECT_KEY${NC}"
echo -e "Organization: $ORGANIZATION"
echo -e "Status filter: $STATUSES\n"

# Create CSV header
echo "Key,Type,Rule,Severity,Status,Resolution,FilePath,FileName,Message,Effort,Debt,Author,Tags,CreationDate,UpdateDate,Line,TextRange,URL" > "$OUTPUT_FILE"

# Fetch all pages
while true; do
    echo -n "Fetching page $PAGE..."
    
    # Make API request
    RESPONSE=$(curl -s -H "Authorization: Bearer $API_TOKEN" \
        "https://sonarcloud.io/api/issues/search?componentKeys=$PROJECT_KEY&organization=$ORGANIZATION&statuses=$STATUSES&ps=$PAGE_SIZE&p=$PAGE&s=FILE_LINE&additionalFields=_all")
    
    # Check for errors
    if [ $? -ne 0 ]; then
        echo -e " ${RED}Failed!${NC}"
        echo "Error fetching data from SonarCloud API"
        exit 1
    fi
    
    # Parse total issues on first page
    if [ $PAGE -eq 1 ]; then
        TOTAL_ISSUES=$(echo "$RESPONSE" | jq -r '.total // 0')
        TOTAL_PAGES=$(( (TOTAL_ISSUES + PAGE_SIZE - 1) / PAGE_SIZE ))
        echo -e " (Total issues: $TOTAL_ISSUES)"
    else
        echo -e " ${GREEN}Done${NC}"
    fi
    
    # Extract issues and append to CSV
    echo "$RESPONSE" | jq -r '.issues[] | 
        [
            .key,
            .type,
            .rule,
            .severity,
            .status,
            .resolution // "",
            (.component | sub("^'$PROJECT_KEY':"; "")),
            (.component | sub("^'$PROJECT_KEY':"; "") | split("/") | .[-1]),
            .message,
            .effort // "",
            .debt // "",
            .author // "",
            (.tags | join(";")),
            .creationDate,
            .updateDate // "",
            .line // "",
            (if .textRange then "L\(.textRange.startLine):\(.textRange.startOffset)-L\(.textRange.endLine):\(.textRange.endOffset)" else "" end),
            "https://sonarcloud.io/project/issues?id='$PROJECT_KEY'&open=\(.key)"
        ] | @csv' >> "$OUTPUT_FILE"
    
    # Check if there are more pages
    ISSUES_COUNT=$(echo "$RESPONSE" | jq '.issues | length')
    if [ "$ISSUES_COUNT" -lt "$PAGE_SIZE" ] || [ $PAGE -ge $TOTAL_PAGES ]; then
        break
    fi
    
    PAGE=$((PAGE + 1))
    sleep 0.2  # Rate limiting
done

# Count issues in CSV (minus header)
FINAL_COUNT=$(($(wc -l < "$OUTPUT_FILE") - 1))

echo -e "\n${GREEN}Fetch complete! Total issues collected: $FINAL_COUNT${NC}"
echo -e "Issues exported to: ${CYAN}$OUTPUT_FILE${NC}"

# Generate summary
echo -e "\n${CYAN}Summary Report${NC}"
echo "=============="

# Summary by severity
echo -e "\n${YELLOW}Issues by Severity:${NC}"
tail -n +2 "$OUTPUT_FILE" | cut -d',' -f4 | sort | uniq -c | sort -nr

# Summary by type
echo -e "\n${YELLOW}Issues by Type:${NC}"
tail -n +2 "$OUTPUT_FILE" | cut -d',' -f2 | sort | uniq -c | sort -nr

# Top 10 rules
echo -e "\n${YELLOW}Top 10 Rules:${NC}"
tail -n +2 "$OUTPUT_FILE" | cut -d',' -f3 | sort | uniq -c | sort -nr | head -10

# Top 10 files
echo -e "\n${YELLOW}Top 10 Files with Most Issues:${NC}"
tail -n +2 "$OUTPUT_FILE" | cut -d',' -f8 | sort | uniq -c | sort -nr | head -10

echo -e "\n${GREEN}Script completed successfully!${NC}"