#!/bin/bash

# USAGE: ./license.sh [Root.plist path] [SourcePackages directory path]

rootPlist="$1"
sourcePackagesPath="$2"
workspaceStatePath="$sourcePackagesPath/workspace-state.json"
checkoutsPath="$sourcePackagesPath/checkouts"
plistBuddy="/usr/libexec/PlistBuddy"

# Check for correct usage
if [ "$#" -ne 2 ]; then
    echo "Error: Incorrect number of arguments."
    echo "USAGE: $0 [Root.plist path] [SourcePackages directory path]"
    echo "Example: $0 ./Settings.bundle/Root.plist ~/Library/Developer/Xcode/DerivedData/Project-abc123/SourcePackages"
    exit 1
fi

# Ensure jq is installed
if ! command -v jq &> /dev/null; then
    echo "jq could not be found, please install it to parse JSON."
    exit 1
fi

# Create a new Root.plist file with the base structure
/bin/cat <<EOF >"$rootPlist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>PreferenceSpecifiers</key>
  <array>
    <dict>
      <key>Type</key>
      <string>PSGroupSpecifier</string>
      <key>Title</key>
      <string>Licenses</string>
    </dict>
    <!-- License Entries Will Be Added Here -->
  </array>
</dict>
</plist>
EOF

# Add license entries to the Root.plist
index=1 # Start from 1 because 0 is the header
for dependency in $(jq -r '.object.dependencies[] | .packageRef.name + " " + .packageRef.location' "$workspaceStatePath"); do
    name=$(echo "$dependency" | cut -d' ' -f1)
    location=$(echo "$dependency" | cut -d' ' -f2)
    repositoryName=$(basename "$location" .git)

    # Find the license file
    licenseFile=$(find "$checkoutsPath/$repositoryName" -iname 'LICENSE' -o -iname 'LICENCE' | head -n 1)

    if [ -n "$licenseFile" ]; then
        # Read license file content
        licenseContent=$(<"$licenseFile")

        # Add a new entry to the 'PreferenceSpecifiers' array
        $plistBuddy -c "Add :PreferenceSpecifiers:$index dict" "$rootPlist"
        $plistBuddy -c "Add :PreferenceSpecifiers:$index:Title string '$name'" "$rootPlist"
        $plistBuddy -c "Add :PreferenceSpecifiers:$index:Type string 'PSGroupSpecifier'" "$rootPlist"
        $plistBuddy -c "Add :PreferenceSpecifiers:$index:FooterText string '$licenseContent'" "$rootPlist"
        ((index++))
    else
        echo "Warning: No license found for $name."
    fi
done

echo "Updated Root.plist with licenses."
