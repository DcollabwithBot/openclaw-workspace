#!/bin/bash
# Upload all files from dist to cPanel

CREDS="kirsogda:XX4UQI4SAB31QF1D5XYDS4M2ABTU79TM"
HOST="cp05.nordicway.dk"
TARGET_BASE="/home/kirsogda/public_html/tjekbolig.ai"
SOURCE_DIR="/root/.openclaw/workspace/projects/tjekbolig-ai/tjekbolig-ai-frontend/dist"

echo "Starting upload from $SOURCE_DIR to $TARGET_BASE"

# Create directories first
create_dir() {
    local dir="$1"
    local target_dir="${TARGET_BASE}${dir#$SOURCE_DIR}"
    echo "Creating directory: $target_dir"
    curl -s -H "Authorization: cpanel $CREDS" \
        "https://$HOST:2083/execute/Fileman/mkdir?path=$(printf %s "$target_dir" | jq -sRr @uri)" > /dev/null 2>&1
}

# Upload file
upload_file() {
    local file="$1"
    local rel_path="${file#$SOURCE_DIR/}"
    local target_dir="$(dirname "$TARGET_BASE/$rel_path")"
    local filename="$(basename "$file")"
    
    echo "Uploading: $rel_path"
    
    curl -s -X POST \
        -H "Authorization: cpanel $CREDS" \
        -F "dir=$target_dir" \
        -F "file=@$file;filename=$filename" \
        "https://$HOST:2083/execute/Fileman/upload_files" > /dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        echo "  ✓ $rel_path"
    else
        echo "  ✗ Failed: $rel_path"
    fi
}

# First create all directories
find "$SOURCE_DIR" -type d | while read -r dir; do
    if [ "$dir" != "$SOURCE_DIR" ]; then
        create_dir "$dir"
    fi
done

# Upload all files
find "$SOURCE_DIR" -type f | while read -r file; do
    upload_file "$file"
    sleep 0.1
done

echo "Upload complete!"
