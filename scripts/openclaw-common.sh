#!/usr/bin/env bash

die() {
    echo "ERROR: $*" >&2
    exit 1
}

run_cmd() {
    printf '+ '
    printf '%q ' "$@"
    printf '\n'
    [[ $DRY_RUN -eq 1 ]] || "$@"
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

split_csv_into_array() {
    local raw="$1"
    local output_name="$2"
    local old_ifs="$IFS"
    local -a parsed=()

    IFS=',' read -r -a parsed <<< "$raw"
    IFS="$old_ifs"
    eval "$output_name=(\"\${parsed[@]}\")"
}
