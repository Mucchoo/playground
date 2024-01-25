#!/bin/bash

# USAGE: ./script.sh [output directory path] [SourcePackages directory path]

outputPath="$1"
sourcePackagesPath="$2"
workspaceStatePath="$sourcePackagesPath/workspace-state.json"
checkoutsPath="$sourcePackagesPath/checkouts"

# Exit with usage information
if [ "$#" -ne 2 ]; then
    echo "USAGE: $0 [output directory path] [SourcePackages directory path]"
    exit 1
fi

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "jq could not be found, please install it to parse JSON."
    exit 1
fi

# Load workspace-state.json
if [ ! -f "$workspaceStatePath" ]; then
    echo "Error: Could not read workspace-state.json."
    exit 1
fi

# Initialize license-list.plist
plistPath="$outputPath/license-list.plist"
echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>" > "$plistPath"
echo "<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">" >> "$plistPath"
echo "<plist version=\"1.0\">" >> "$plistPath"
echo "<dict>" >> "$plistPath"
echo "<key>libraries</key>" >> "$plistPath"
echo "<array>" >> "$plistPath"

# Parse each dependency from workspace-state.json
dependencies=$(jq -r '.object.dependencies[] | .packageRef.name + " " + .packageRef.location' "$workspaceStatePath")

for dependency in $dependencies; do
    name=$(echo "$dependency" | cut -d' ' -f1)
    location=$(echo "$dependency" | cut -d' ' -f2)
    repositoryName=$(basename "$location" .git)

    # Find the license file
    licenseFile=$(find "$checkoutsPath/$repositoryName" -iname 'LICENSE' -o -iname 'LICENCE' | head -n 1)

    if [ -n "$licenseFile" ]; then
        # Read license file content
        licenseBody=$(cat "$licenseFile")

        # Append to plist
        echo "<dict>" >> "$plistPath"
        echo "<key>name</key><string>$name</string>" >> "$plistPath"
        echo "<key>url</key><string>$location</string>" >> "$plistPath"
        echo "<key>licenseBody</key><string><![CDATA[$licenseBody]]></string>" >> "$plistPath"
        echo "</dict>" >> "$plistPath"
    else
        echo "Warning: No license found for $name."
    fi
done

# Close plist tags
echo "</array>" >> "$plistPath"
echo "</dict>" >> "$plistPath"
echo "</plist>" >> "$plistPath"

echo "Generated license-list.plist at $plistPath."
