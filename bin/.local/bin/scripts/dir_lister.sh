#!/bin/bash

# Default output file if -o is not provided
OUTPUT_FILE="directory_listing.md"

# ==========================================
# PARSE ARGUMENTS AND FLAGS
# ==========================================

while getopts "o:" opt; do
  case ${opt} in
    o )
      OUTPUT_FILE=$OPTARG
      ;;
    \? )
      echo "Usage: $0 [-o output_file.md] dir1 dir2 dir3 ..."
      exit 1
      ;;
  esac
done

shift $((OPTIND -1))

if [ $# -eq 0 ]; then
    echo "Error: No directories provided."
    echo "Usage: $0 [-o output_file.md] dir1 dir2 dir3 ..."
    exit 1
fi

# ==========================================
# RECURSIVE SCAN FUNCTION
# ==========================================

scan_directory() {
    local target_dir="$1"
    local depth="$2"
    
    # Generate the folder depth prefix (#, ##, ###, etc.)
    local folder_prefix=""
    for ((i=1; i<=depth; i++)); do
        folder_prefix+="#"
    done

    # 1. Print the folder name with its depth hashes
    echo "${folder_prefix} $(basename "$target_dir")" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE" # 1 new line before content

    # Arrays to separate current level files and folders for clean ordering
    local files=()
    local subdirs=()

    # Read current directory contents safely (handles spaces)
    while IFS= read -r -d '' item; do
        if [ -d "$item" ]; then
            subdirs+=("$item")
        elif [ -f "$item" ]; then
            files+=("$item")
        fi
    done < <(find "$target_dir" -mindepth 1 -maxdepth 1 -print0 2>/dev/null)

    # 2. Print all files at this current level (always starting with just '*')
    for file in "${files[@]}"; do
        echo "* $(basename "$file")" >> "$OUTPUT_FILE"
    done

    # 3. Recursively process subfolders
    for subdir in "${subdirs[@]}"; do
        # Add exactly 4 new lines BEFORE a subfolder block starts
        echo -e "\n\n\n\n" >> "$OUTPUT_FILE"
        
        # Recurse into the subfolder, increasing the depth by 1
        scan_directory "$subdir" $((depth + 1))
    done
}

# ==========================================
# SCRIPT EXECUTION
# ==========================================

# Clear or create the output file
> "$OUTPUT_FILE"

for root_dir in "$@"; do
    root_dir="${root_dir%/}" # Remove trailing slash

    if [ ! -d "$root_dir" ]; then
        echo "Warning: '$root_dir' does not exist or is not a directory. Skipping." >&2
        continue
    fi

    echo "Processing: $root_dir"
    
    # Start the recursive scan for the root directory at depth 1
    scan_directory "$root_dir" 1
    
    # Add 4 new lines between the main argument directory blocks
    echo -e "\n\n\n\n" >> "$OUTPUT_FILE"
done

# Clean up any trailing excessive newlines at the very end of the file
sed -i -e :a -e '/^\n*$/{$d;N;ba' -e '}' "$OUTPUT_FILE" 2>/dev/null

echo "Done! Output successfully saved to: $OUTPUT_FILE"

