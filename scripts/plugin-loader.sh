#!/bin/bash

PLUGIN_DIR=${PLUGIN_DIR:-/usr/local/bin/plugins}

discover_plugins() {
    local plugin_dir=$1
    if [ ! -d "$plugin_dir" ]; then
        return
    fi
    for manifest in "$plugin_dir"/*/manifest.yaml; do
        if [ -f "$manifest" ]; then
            local name
            name=$(yq e '.name // ""' "$manifest" 2>/dev/null)
            if [ -n "$name" ] && [ "$name" != "null" ]; then
                echo "$name"
            fi
        fi
    done
}

load_plugin_config() {
    local plugin_name=$1
    local plugin_dir=$2
    local manifest="$plugin_dir/$plugin_name/manifest.yaml"

    if [ ! -f "$manifest" ]; then
        return 1
    fi

    yq e '.' "$manifest" 2>/dev/null
}

validate_plugin_manifest() {
    local manifest=$1
    if [ ! -f "$manifest" ]; then
        echo "ERROR: Manifest not found: $manifest"
        return 1
    fi

    local name
    name=$(yq e '.name // ""' "$manifest")
    local script
    script=$(yq e '.script // ""' "$manifest")
    local enabled
    enabled=$(yq e '.enabled // ""' "$manifest")

    if [ -z "$name" ]; then
        echo "ERROR: Plugin manifest missing 'name'"
        return 1
    fi
    if [ -z "$script" ]; then
        echo "ERROR: Plugin manifest '$name' missing 'script'"
        return 1
    fi
    if [ "$enabled" != "true" ] && [ "$enabled" != "false" ] && [ -n "$enabled" ]; then
        echo "ERROR: Plugin '$name' has invalid 'enabled' value"
        return 1
    fi
    return 0
}

run_plugin() {
    local name=$1
    local plugin_dir=$2
    local config_file=$3
    local manifest="$plugin_dir/$name/manifest.yaml"

    local script
    script=$(yq e '.script' "$manifest")
    local script_path="$plugin_dir/$name/$script"

    if [ ! -f "$script_path" ]; then
        echo "ERROR: Plugin script not found: $script_path"
        return 1
    fi
    if [ ! -x "$script_path" ]; then
        chmod +x "$script_path"
    fi

    local args
    args=$(yq e '.args // [] | join(" ")' "$manifest")
    # shellcheck disable=SC2086
    "$script_path" "$config_file" $args
}
