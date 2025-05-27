#!/bin/bash

# Find all .swift files
swift_files=$(find . -name "*.swift")

# Total Swift lines
total_lines=$(cat $swift_files | wc -l)

echo "📊 Total Swift LOC: $total_lines"
echo ""
printf "%6s %6s   %s\n" "Lines" "Percent" "File"
echo "----------------------------------------------"

# Loop through each file, count lines, print with %
for file in $swift_files; do
    lines=$(wc -l < "$file")
    percent=$(awk "BEGIN { printf \"%.2f\", ($lines/$total_lines)*100 }")
    printf "%6s %6s%%   %s\n" "$lines" "$percent" "$file"
done | sort -rn
