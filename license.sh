#!/bin/bash

licensesPlist="Playground/Settings.bundle/Licenses.plist"
sourcePackagesPath="$HOME/Library/Developer/Xcode/DerivedData/Playground-goyzuhpfiefigjcuoorztvrvqlaf/SourcePackages"
workspaceStatePath="$sourcePackagesPath/workspace-state.json"
checkoutsPath="$sourcePackagesPath/checkouts"
licensesDir="$(dirname "$licensesPlist")/Licenses"
plistBuddy="/usr/libexec/PlistBuddy"

# Ensure jq is installed
if ! command -v jq &> /dev/null; then
    echo "jq could not be found, please install it to parse JSON."
    exit 1
fi

# Remove existing Licenses.plist and Licenses directory
if [ -f "$licensesPlist" ]; then
    rm "$licensesPlist"
fi

if [ -d "$licensesDir" ]; then
    rm -r "$licensesDir"
fi

# Create the Licenses directory
mkdir -p "$licensesDir"

# Create the main Licenses.plist file
/bin/cat <<EOF >"$licensesPlist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>PreferenceSpecifiers</key>
  <array>
    <dict>
      <key>Title</key>
      <string>Licenses</string>
      <key>Type</key>
      <string>PSGroupSpecifier</string>
    </dict>
    <!-- License Entries Will Be Added Here -->
  </array>
</dict>
</plist>
EOF

# Add license entries to the Root.plist and create individual license files
index=1
for dependency in $(jq -r '.object.dependencies[] | .packageRef.name' "$workspaceStatePath" | sort | uniq); do
    name="$dependency"
    repositoryLocation=$(jq -r --arg name "$name" '.object.dependencies[] | select(.packageRef.name == $name) | .packageRef.location' "$workspaceStatePath")
    repositoryName=$(basename "$repositoryLocation" .git)

    # Find the license file
    licenseFile=$(find "$checkoutsPath/$repositoryName" -iname 'LICENSE' -o -iname 'LICENCE' | head -n 1)

    if [ -n "$licenseFile" ]; then
        # Create individual license plist file
        /bin/cat <<EOF >"$licensesDir/$name.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>PreferenceSpecifiers</key>
  <array>
    <dict>
      <key>FooterText</key>
      <string>$(cat "$licenseFile")</string>
      <key>Title</key>
      <string>$name</string>
      <key>Type</key>
      <string>PSGroupSpecifier</string>
    </dict>
  </array>
</dict>
</plist>
EOF

        # Add a new entry to the 'PreferenceSpecifiers' array in the main plist
        $plistBuddy -c "Add :PreferenceSpecifiers:$index dict" "$licensesPlist"
        $plistBuddy -c "Add :PreferenceSpecifiers:$index:File string 'Licenses/$name'" "$licensesPlist"
        $plistBuddy -c "Add :PreferenceSpecifiers:$index:Title string '$name'" "$licensesPlist"
        $plistBuddy -c "Add :PreferenceSpecifiers:$index:Type string 'PSChildPaneSpecifier'" "$licensesPlist"

        ((index++))
    else
        echo "Warning: No license found for $name."
    fi
done

echo "Updated Root.plist with licenses."
