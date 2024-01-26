#!/bin/bash

licensesPlist="Playground/Settings.bundle/Licenses.plist"
sourcePackagesPath="$HOME/Library/Developer/Xcode/DerivedData/Playground-goyzuhpfiefigjcuoorztvrvqlaf/SourcePackages"
workspaceStatePath="$sourcePackagesPath/workspace-state.json"
checkoutsPath="$sourcePackagesPath/checkouts"
licensesDir="$(dirname "$licensesPlist")/Licenses"
plistBuddy="/usr/libexec/PlistBuddy"

check_jq_installed() {
    if ! command -v jq &> /dev/null; then
        echo "jq could not be found, please install it to parse JSON."
        exit 1
    fi
}

remove_existing_files() {
    rm -f "$licensesPlist"
    rm -rf "$licensesDir"
}

create_licenses_directory() {
    mkdir -p "$licensesDir"
}

create_main_licenses_plist() {
    cat <<EOF >"$licensesPlist"
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
  </array>
</dict>
</plist>
EOF
}

add_license_entry() {
    local name="$1"
    local licenseFile="$2"
    local index="$3"

    cat <<EOF >"$licensesDir/$name.plist"
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

    $plistBuddy -c "Add :PreferenceSpecifiers:$index dict" "$licensesPlist"
    $plistBuddy -c "Add :PreferenceSpecifiers:$index:File string 'Licenses/$name'" "$licensesPlist"
    $plistBuddy -c "Add :PreferenceSpecifiers:$index:Title string '$name'" "$licensesPlist"
    $plistBuddy -c "Add :PreferenceSpecifiers:$index:Type string 'PSChildPaneSpecifier'" "$licensesPlist"
}

process_dependencies() {
    local index=1
    jq -r '.object.dependencies[] | .packageRef.name' "$workspaceStatePath" | sort | uniq | \
    while IFS= read -r name; do
        local repositoryLocation
        repositoryLocation=$(jq -r --arg name "$name" '.object.dependencies[] | select(.packageRef.name == $name) | .packageRef.location' "$workspaceStatePath")
        local repositoryName
        repositoryName=$(basename "$repositoryLocation" .git)

        local licenseFile
        licenseFile=$(find "$checkoutsPath/$repositoryName" -iname 'LICENSE' -o -iname 'LICENCE' | head -n 1)

        if [ -n "$licenseFile" ]; then
            add_license_entry "$name" "$licenseFile" "$index"
            ((index++))
        else
            echo "Warning: No license found for $name."
        fi
    done
}

main() {
    check_jq_installed
    remove_existing_files
    create_licenses_directory
    create_main_licenses_plist
    process_dependencies
    echo "Updated licenses."
}

main
