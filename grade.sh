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
tail -n +2 "$CSV_FILE" | tr -d '\r' while IFS=, read -r name html css bash git; do
  ((line_num++))
  # Trim messy whitespaces completely
  name=$(echo "$name" | xargs 2>/dev/null)
  html=$(echo "$html" | xargs 2>/dev/null)
  css=$(echo "$css" | xargs 2>/dev/null)
  bash=$(echo "$bash" | xargs 2>/dev/null)
  git=$(echo "$git" | xargs 2>/dev/null)
fi 

# 1. Check for missing name or any missing scores
if [[ -z "$name" || -z "$html" || -z "$css" || -z "$bash" || -z "$git" ]]; then
      echo "Warning: Line $line_num skipped (missing name or score)." >&2
      echo "skipped" >> "$tmp_data"
      continue
fi

  # 2. Check if scores are integers (not a number)
if [[ ! "$html" =~ ^[0-9]+$ || ! "$css" =~ ^[0-9]+$ || \
        ! "$bash" =~ ^[0-9]+$ || ! "$git" =~ ^[0-9]+$ ]]; then
      echo "Warning: Line $line_num skipped (score is not a whole number)." >&2
      echo "skipped" >> "$tmp_data"
      continue
fi

  # 3. Check if any score is over 20
if (( html > 20 || css > 20 || bash > 20 || git > 20 )); then
      echo "Warning: Line $line_num skipped (score over 20 detected)." >&2
      echo "skipped" >> "$tmp_data"
      continue
fi
    sum=$((html + css +bash + git))
    avg=$(awk "BEGIN {prinf \"%.2f\", $sum/4}")
    echo "$avg,$name"

 if (( total >= 64 )); then mention="Très bien"
  elif (( total >= 56 )); then mention="Bien"
  elif (( total >= 48 )); then mention="Assez bien"
  elif (( total >= 40 )); then mention="Passable"
  else mention="Échec"
  fi

line_no=1
while IFS=, read -r name html css bash git; do
 (( line_no++ ))

 
if [[ -z "$name" ]]; then
    echo "Line $line_no: missing name, skipped" >&2
 continue
fi

for score in "$html" "$css" "$bash" "$git"; do
if ! [[ "$score" =~ ^[0-9]+$ ]]  || (( score > 20 )); then
    echo "Line $line_no: invalid score '$score' for $name, skipped" >&2
continue 2

fi
done
printf "%-6s %-15s %-10s %-15s\n" "Rank" "Name" "Average" "mention"

  # Output cleanly structured records to our storage file
  echo "$avg|$name|$html|$css|$bash|$git|$mention" >> "$tmp_data"
done

# =====================================================================
# 3. SORTING AND FINAL ALIGNED PRINT
# =====================================================================
skipped_lines=$(grep -c "skipped" "$tmp_data" 2>/dev/null || echo 0)

# Aligned Blueprint Layout
FMT="  %-5s %-17s %-5s %-5s %-5s %-5s %-6s %-s\n"
printf "$FMT" "RANK" "NAME" "HTML" "CSS" "BASH" "GIT" "AVG" "MENTION"

rank=1
class_sum=0
valid_student_count=0

# Process valid records sorted from highest average downwards
while IFS='|' read -r avg name html css bash git mention; do
  if [ -n "$avg" ]; then
      printf "  %-5d %-17s %-5s %-5s %-5s %-5s %-6s %-s\n" \
             "$rank" "$name" "$html" "$css" "$bash" "$git" "$avg" "$mention"
             
      class_sum=$(awk -v cs="$class_sum" -v a="$avg" 'BEGIN {print cs + a}')
      ((rank++))
      ((valid_student_count++))
  fi
done < <(grep -v "skipped" "$tmp_data" | sort -rn -t'|' -k1 2>/dev/null)

# Summary computations
if [ "$valid_student_count" -gt 0 ]; then
    class_avg=$(awk -v cs="$class_sum" -v vc="$valid_student_count" 'BEGIN {printf "%.2f", cs / vc}')
else
    class_avg="0.00"
fi

echo "------------------------------------------------------------"
echo "Class average: $class_avg"
echo "Skipped $skipped_lines invalid lines (see warnings above)."
