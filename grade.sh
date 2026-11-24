#!/bin/bash
if [ -z "$1" ]; then
    echo "Usage: $0 FILE.csv" >&2
    exit 1
fi 

CSV_FILE=$1


if [ ! -f "$CSV_FILE" ] || [ ! -r "$CSV_FILE" ]; then
    echo "Error: File '$CSV_FILE' is missing or unreadable." >&2
    exit 1
fi

# Skip header and read each line
line_num=1
tmp_data=$(mktemp)
trap 'rm -f "$tmp_data"' EXIT
skipped_lines=0

while IFS=, read -r name html css bash git; do 
(( line_num++))

# Check for missing values (now completely safe from subshell loss)
if [[ -z "$name" || -z "$html" || -z "$css" || -z "$bash" || -z "$git" ]]; then
    echo "Warning: Line $line_num has missing data. Skipping." >&2
    ((skipped_lines++))
    continue
fi

# check maximum score
if [[ ! "$html" =~ ^[0-9]+$ || ! "$css" =~ ^[0-9]+$ || ! "$bash" =~ ^[0-9]+$ || ! "$git" =~ ^[0-9]+$ ]]; then
        echo "Warning: Line $line_num has a score above 20. Skipping." >&2
        ((skipped_lines++))
        continue
fi

# if (( html > 20 || css > 20 || bash > 20 || git > 20 )); then
#         echo "Warning: Line $line_num skipped (score exceeds maximum limit)." >&2
#         continue
# fi

# calculate total and average
 sum=$((html + css + bash + git))
 avg=$(awk -v total="$sum" 'BEGIN {printf "%.2f", total/4}')
#  echo "$sum|$name|$html|$css|$bash|$git" >> "$tmp_data"
# done < <(tail -n +2 "$CSV_FILE" | tr -d '\r')

#   # Trim messy whitespaces completely
#   name=$(echo "$name" | xargs 2>/dev/null)
#   html=$(echo "$html" | xargs 2>/dev/null)
#   css=$(echo "$css" | xargs 2>/dev/null)
#   bash=$(echo "$bash" | xargs 2>/dev/null)
#   git=$(echo "$git" | xargs 2>/dev/null)
 

#     sum=$((html + css +bash + git))
#     avg=$(awk "BEGIN {prinf \"%.2f\", $sum/4}")
#     echo "$avg,$name"

# Calculate the total score first
total=$(( html + css + bash + git ))

# Determine the mention
if (( total >= 64 )); then 
    mention="Très bien"
  elif (( total >= 56 )); then 
    mention="Bien"
  elif (( total >= 48 )); then 
    mention="Assez bien"
  elif (( total >= 40 )); then 
    mention="Passable"
  else 
    mention="Échec"
fi

#Store student record
echo "$avg|$name|$html|$css|$bash|$git|$mention" >> "$tmp_data"
 
# if [[ -z "$name" ]]; then
#     echo "Line $line_num: missing name, skipped" >&2
 
# fi

# for score in "$html" "$css" "$bash" "$git"; do
# if ! [[ "$score" =~ ^[0-9]+$ ]]  || (( score > 20 )); then
#     echo "Line $line_num: invalid score '$score' for $name, skipped" >&2
# continue 2

# fi 
 done < <(tail -n +2 "$CSV_FILE" | tr -d '\r')


# printf "%-6s %-15s %-10s %-15s\n" "Rank" "Name" "Average" "mention"

  # Output cleanly structured records to our storage file

# =====================================================================
# 3. SORTING AND FINAL ALIGNED PRINT
# =====================================================================
# skipped_lines=$(grep -c "skipped" "$tmp_data" 2>/dev/null || echo 0)

# Aligned Blueprint Layout
printf "%-6s %-15s %-6s %-6s %-6s %-6s %-8s %-15s\n" \
 "RANK" "NAME" "HTML" "CSS" "BASH" "GIT" "AVG" "MENTION"

rank=1
class_sum=0
valid_student_count=0

# Process valid records sorted from highest average downwards
while IFS='|' read -r avg name html css bash git mention; do
if [ -n "$avg" ]; then 
    printf "  %-6d %-15s %-6s %-6s %-6s %-6s %-8s %-15s\n" \
     "$rank" "$name" "$html" "$css" "$bash" "$git" "$avg" "$mention"
             
    class_sum=$(awk -v cs="$class_sum" -v a="$avg" 'BEGIN {print cs + a}')
    ((rank++))
    ((valid_student_count++))
fi
done < <(sort -rn -t'|' -k1 "$tmp_data")

# Summary computations
if [ "$valid_student_count" -gt 0 ]; then
    class_avg=$(awk -v cs="$class_sum" -v vc="$valid_student_count" 'BEGIN {printf "%.2f", cs / vc}')
else
    class_avg="0.00"
fi

echo "------------------------------------------------------------"
echo "Class average: $class_avg"
echo "Skipped $skipped_lines invalid lines (see warnings above)."
