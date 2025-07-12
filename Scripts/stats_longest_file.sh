#!/bin/bash

# Default values
TARGET_DIR="${1:-.}"
SHOW_EMPTY=${SHOW_EMPTY:-false}
MIN_LINES=${MIN_LINES:-0}
EXCLUDE_TESTS=${EXCLUDE_TESTS:-false}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Function to display usage
show_usage() {
    echo "Usage: $0 [directory] [options]"
    echo "Options:"
    echo "  SHOW_EMPTY=true     - Include files with 0 lines"
    echo "  MIN_LINES=n         - Only show files with at least n lines"
    echo "  EXCLUDE_TESTS=true  - Exclude test files"
}

# Check if directory exists
if [[ ! -d "$TARGET_DIR" ]]; then
    echo -e "${RED}Error: Directory '$TARGET_DIR' does not exist${NC}"
    show_usage
    exit 1
fi

# Build find command
find_cmd="find \"$TARGET_DIR\" -name \"*.swift\" -type f"
if [[ "$EXCLUDE_TESTS" == "true" ]]; then
    find_cmd="$find_cmd ! -path \"*/Tests/*\" ! -path \"*/*Test*\" ! -name \"*Test*.swift\" ! -name \"*Tests.swift\""
fi
swift_files=$(eval $find_cmd)

if [[ -z "$swift_files" ]]; then
    echo -e "${YELLOW}No Swift files found in '$TARGET_DIR'${NC}"
    exit 0
fi

file_count=$(echo "$swift_files" | wc -l)
total_lines=0
total_non_empty=0
total_comments=0
total_blank=0

echo -e "${BLUE}🔍 Analyzing Swift files in: $TARGET_DIR${NC}"
echo -e "${BLUE}📁 Files found: $file_count${NC}"

stats_temp=$(mktemp)

while IFS= read -r file; do
    if [[ -f "$file" ]]; then
        lines=$(wc -l < "$file" 2>/dev/null || echo 0)
        non_empty=$(grep -c -v '^[[:space:]]*$' "$file" 2>/dev/null || echo 0)
        comments=$(grep -c '^\s*\/\/' "$file" 2>/dev/null || echo 0)
        blank=$((lines - non_empty))

        echo "$file:$lines:$non_empty:$comments:$blank" >> "$stats_temp"

        total_lines=$((total_lines + lines))
        total_non_empty=$((total_non_empty + non_empty))
        total_comments=$((total_comments + comments))
        total_blank=$((total_blank + blank))
    fi
done <<< "$swift_files"

# Summary
echo ""
echo -e "${GREEN}📊 Summary Statistics:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
printf "%-20s %10s %10s %10s %10s\n" "Metric" "Total" "Avg/File" "Min" "Max"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

min_lines=999999
max_lines=0

while IFS=: read -r file lines non_empty comments blank; do
    [[ $lines -lt $min_lines ]] && min_lines=$lines
    [[ $lines -gt $max_lines ]] && max_lines=$lines
done < "$stats_temp"

avg_lines=$((file_count > 0 ? total_lines / file_count : 0))
avg_non_empty=$((file_count > 0 ? total_non_empty / file_count : 0))
avg_comments=$((file_count > 0 ? total_comments / file_count : 0))
avg_blank=$((file_count > 0 ? total_blank / file_count : 0))

printf "%-20s %10s %10s %10s %10s\n" "Total Lines" "$total_lines" "$avg_lines" "$min_lines" "$max_lines"
printf "%-20s %10s %10s %10s %10s\n" "Non-empty Lines" "$total_non_empty" "$avg_non_empty" "-" "-"
printf "%-20s %10s %10s %10s %10s\n" "Comment Lines" "$total_comments" "$avg_comments" "-" "-"
printf "%-20s %10s %10s %10s %10s\n" "Blank Lines" "$total_blank" "$avg_blank" "-" "-"

echo ""
echo -e "${GREEN}📋 Detailed File Analysis:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
printf "%6s %7s %6s %6s   %s\n" "Lines" "Percent" "Code" "Blank" "File"
echo "──────────────────────────────────────────────────────────────────────────"

output_temp=$(mktemp)
while IFS=: read -r file lines non_empty comments blank; do
    if [[ "$SHOW_EMPTY" == "false" && $lines -eq 0 ]]; then
        continue
    fi
    if [[ $lines -lt $MIN_LINES ]]; then
        continue
    fi

    percent=$(awk "BEGIN { printf \"%.2f\", ($lines/$total_lines)*100 }")

    if [[ $lines -gt 500 ]]; then
        color="$RED"
    elif [[ $lines -gt 200 ]]; then
        color="$YELLOW"
    else
        color="$GREEN"
    fi

    display_file=$(echo "$file" | sed "s|^$TARGET_DIR/||" | sed 's|^\./||')
    printf "%s%6s %6s%% %6s %6s   %s%s\n" "$color" "$lines" "$percent" "$non_empty" "$blank" "$display_file" "$NC" >> "$output_temp"
done < "$stats_temp"

sort -rn "$output_temp"
rm "$output_temp"

echo ""
echo -e "${BLUE}💡 Tips:${NC}"
echo "• Files with >500 lines (${RED}red${NC}) might benefit from refactoring"
echo "• Files with >200 lines (${YELLOW}yellow${NC}) should be monitored"

echo ""
echo -e "${YELLOW}🔝 Top 5 Largest Files:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
sort -t: -k2 -nr "$stats_temp" | head -n 5 | nl | while read -r num line; do
    file=$(echo "$line" | cut -d: -f1)
    lines=$(echo "$line" | cut -d: -f2)
    display_file=$(echo "$file" | sed "s|^$TARGET_DIR/||" | sed 's|^\./||')
    echo "$num. $lines lines - $display_file"
done

rm "$stats_temp"
