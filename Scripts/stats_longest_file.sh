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
NC='\033[0m' # No Color

# Function to display usage
show_usage() {
    echo "Usage: $0 [directory] [options]"
    echo "Options:"
    echo "  SHOW_EMPTY=true     - Include files with 0 lines"
    echo "  MIN_LINES=n         - Only show files with at least n lines"
    echo "  EXCLUDE_TESTS=true  - Exclude test files"
    echo ""
    echo "Examples:"
    echo "  $0                           # Analyze current directory"
    echo "  $0 ./Sources                 # Analyze specific directory"
    echo "  MIN_LINES=50 $0              # Only show files with 50+ lines"
    echo "  EXCLUDE_TESTS=true $0        # Exclude test files"
}

# Check if directory exists
if [[ ! -d "$TARGET_DIR" ]]; then
    echo -e "${RED}Error: Directory '$TARGET_DIR' does not exist${NC}"
    show_usage
    exit 1
fi

# Build find command with filters
find_cmd="find \"$TARGET_DIR\" -name \"*.swift\" -type f"

# Exclude test files if requested
if [[ "$EXCLUDE_TESTS" == "true" ]]; then
    find_cmd="$find_cmd ! -path \"*/Tests/*\" ! -path \"*/*Test*\" ! -name \"*Test*.swift\" ! -name \"*Tests.swift\""
fi

# Find all .swift files
swift_files=$(eval $find_cmd)

# Check if any Swift files were found
if [[ -z "$swift_files" ]]; then
    echo -e "${YELLOW}No Swift files found in '$TARGET_DIR'${NC}"
    exit 0
fi

# Count total files
file_count=$(echo "$swift_files" | wc -l)

# Calculate totals
total_lines=0
total_non_empty=0
total_comments=0
total_blank=0

echo -e "${BLUE}🔍 Analyzing Swift files in: $TARGET_DIR${NC}"
echo -e "${BLUE}📁 Files found: $file_count${NC}"

# First pass: calculate totals and detailed metrics
declare -A file_stats
while IFS= read -r file; do
    if [[ -f "$file" ]]; then
        lines=$(wc -l < "$file" 2>/dev/null || echo 0)
        non_empty=$(grep -c -v '^[[:space:]]*$' "$file" 2>/dev/null || echo 0)
        comments=$(grep -c '^\s*\/\/' "$file" 2>/dev/null || echo 0)
        blank=$((lines - non_empty))
        
        file_stats["$file"]="$lines:$non_empty:$comments:$blank"
        
        total_lines=$((total_lines + lines))
        total_non_empty=$((total_non_empty + non_empty))
        total_comments=$((total_comments + comments))
        total_blank=$((total_blank + blank))
    fi
done <<< "$swift_files"

# Display summary
echo ""
echo -e "${GREEN}📊 Summary Statistics:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
printf "%-20s %10s %10s %10s %10s\n" "Metric" "Total" "Avg/File" "Min" "Max"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Calculate min/max
min_lines=999999
max_lines=0
for file in $swift_files; do
    if [[ -f "$file" ]]; then
        lines=$(echo "${file_stats[$file]}" | cut -d: -f1)
        [[ $lines -lt $min_lines ]] && min_lines=$lines
        [[ $lines -gt $max_lines ]] && max_lines=$lines
    fi
done

avg_lines=$((total_lines / file_count))
avg_non_empty=$((total_non_empty / file_count))

printf "%-20s %10s %10s %10s %10s\n" "Total Lines" "$total_lines" "$avg_lines" "$min_lines" "$max_lines"
printf "%-20s %10s %10s %10s %10s\n" "Non-empty Lines" "$total_non_empty" "$avg_non_empty" "-" "-"
printf "%-20s %10s %10s %10s %10s\n" "Comment Lines" "$total_comments" "$((total_comments / file_count))" "-" "-"
printf "%-20s %10s %10s %10s %10s\n" "Blank Lines" "$total_blank" "$((total_blank / file_count))" "-" "-"

echo ""
echo -e "${GREEN}📋 Detailed File Analysis:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
printf "%6s %7s %6s %6s   %s\n" "Lines" "Percent" "Code" "Blank" "File"
echo "──────────────────────────────────────────────────────────────────────────"

# Create temporary file for sorting
temp_file=$(mktemp)

# Second pass: output file details
for file in $swift_files; do
    if [[ -f "$file" ]]; then
        IFS=':' read -r lines non_empty comments blank <<< "${file_stats[$file]}"
        
        # Apply filters
        if [[ "$SHOW_EMPTY" == "false" && $lines -eq 0 ]]; then
            continue
        fi
        
        if [[ $lines -lt $MIN_LINES ]]; then
            continue
        fi
        
        if [[ $total_lines -gt 0 ]]; then
            percent=$(awk "BEGIN { printf \"%.2f\", ($lines/$total_lines)*100 }")
        else
            percent="0.00"
        fi
        
        # Color code based on file size
        color=""
        if [[ $lines -gt 500 ]]; then
            color="$RED"
        elif [[ $lines -gt 200 ]]; then
            color="$YELLOW"
        else
            color="$GREEN"
        fi
        
        # Clean up file path for display
        display_file=$(echo "$file" | sed "s|^$TARGET_DIR/||" | sed 's|^\./||')
        
        printf "%s%6s %6s%% %6s %6s   %s%s\n" "$color" "$lines" "$percent" "$non_empty" "$blank" "$display_file" "$NC" >> "$temp_file"
    fi
done

# Sort by line count (descending) and display
sort -rn "$temp_file"
rm "$temp_file"

echo ""
echo -e "${BLUE}💡 Tips:${NC}"
echo "• Files with >500 lines (${RED}red${NC}) might benefit from refactoring"
echo "• Files with >200 lines (${YELLOW}yellow${NC}) should be monitored"
echo "• Use MIN_LINES=50 to focus on larger files"
echo "• Use EXCLUDE_TESTS=true to exclude test files"

# Show largest files
echo ""
echo -e "${YELLOW}🔝 Top 5 Largest Files:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
largest_files=$(for file in $swift_files; do
    if [[ -f "$file" ]]; then
        lines=$(echo "${file_stats[$file]}" | cut -d: -f1)
        echo "$lines:$file"
    fi
done | sort -rn | head -5)

counter=1
while IFS=':' read -r lines file; do
    display_file=$(echo "$file" | sed "s|^$TARGET_DIR/||" | sed 's|^\./||')
    printf "%d. %s lines - %s\n" "$counter" "$lines" "$display_file"
    counter=$((counter + 1))
done <<< "$largest_files"
