#!/bin/bash

# Ensure the script exits if any command fails
set -e

# Check if the source PNG file is provided
if [ $# -ne 1 ]; then
    echo "Usage: $0 source_icon.png"
    exit 1
fi

# Assign the source file name to a variable
SOURCE_ICON=$1

# Check if the source file exists
if [ ! -f "$SOURCE_ICON" ]; then
    echo "File $SOURCE_ICON not found!"
    exit 1
fi

# Create the .iconset directory
ICONSET_DIR="icon.icns"
mkdir -p "$ICONSET_DIR"

# Define sizes to be created
sizes=(16 32 64 128 256 512 1024)

# Loop through sizes and create the appropriate PNG files
for size in "${sizes[@]}"; do
    sips -z $size $size "$SOURCE_ICON" --out "$ICONSET_DIR/icon_${size}x${size}.png"
    if [ $size -ne 1024 ]; then
        double_size=$((size * 2))
        sips -z $double_size $double_size "$SOURCE_ICON" --out "$ICONSET_DIR/icon_${size}x${size}@2x.png"
    fi
done

# Create the ICNS file
iconutil -c icns "$ICONSET_DIR"

# Clean up the .iconset directory
rm -rf "$ICONSET_DIR"

echo "ICNS file created successfully."
