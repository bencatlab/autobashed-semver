#!/usr/bin/env bash

# ---------------------------------------------
# Determine witch function to use to increment
# the next semver
# ---------------------------------------------
# Arguments:
#   $1: SemVer kind
#   $2: Current version
# Required Variable:
#   $INPUT_ENABLE_SNAPSHOT
# Return:
#   Depend on called function:
#       - convert_snapshot_onto_release()
#       - increment_semver()
# ---------------------------------------------
semver_gateway() {
    local semver_kind="$1"
    local current_version="$2"

    if [[ ! ${current_version} = *${INPUT_SNAPSHOT_SUFFIX}* && ${INPUT_ENABLE_SNAPSHOT} = true ]]; then
        create_snapshot "${semver_kind}" "${current_version}"
    elif [[ ${current_version} = *${INPUT_SNAPSHOT_SUFFIX}* && ${INPUT_ENABLE_SNAPSHOT} = true && ${semver_kind} = patch ]]; then
        increment_snapshot "${current_version}"
    elif [[ ${current_version} = *${INPUT_SNAPSHOT_SUFFIX}* && ${INPUT_ENABLE_SNAPSHOT} = false ]]; then
        convert_snapshot_onto_release "$current_version"
    else
        increment_semver "${semver_kind}" "${current_version}"
    fi
}

# ---------------------------------------------
# Create SNAPSHOT
# ---------------------------------------------
# Arguments:
#   $1: Current version
# Return:
#   SNAPSHOT SemVer stating at .1
# ---------------------------------------------
create_snapshot() {
    local semver_kind
    semver_kind="$1"

    local current_version
    current_version="$2"

    local incremented_semver
    incremented_semver=$(increment_semver "${semver_kind}" "${current_version}")

    local snapshot
    snapshot="${incremented_semver}-${INPUT_SNAPSHOT_SUFFIX}.1"

    echo "$snapshot"
}

# ---------------------------------------------
# Increment SNAPSHOT
# ---------------------------------------------
# Arguments:
#   $1: Current version
# Return:
#   Increment SNAPSHOT by 1
# ---------------------------------------------
increment_snapshot() {
    local current_version
    current_version="$1"

    local latest_snapshot
    latest_snapshot="${current_version##*.}"

    local incremented_snapshot
    incremented_snapshot=$((latest_snapshot++))

    local snapshot
    snapshot="${current_version:0:(-${#incremented_snapshot})}${latest_snapshot}"

    echo "$snapshot"
}

# ---------------------------------------------
# Increment current SemVer
# ---------------------------------------------
# Arguments:
#   $1: Semver kind
#   $2: Current version
# Return:
#   Increment RELEASE
# ---------------------------------------------
increment_semver() {
    local semver_kind
    semver_kind="$1"

    local current_version
    current_version=$(echo "$2" | tr -dc '0-9.')

    local array_semver
    IFS="." read -r -a array_semver <<< "$current_version"

    case "${semver_kind}" in
        "${INPUT_MAJOR,,}" )
            ((array_semver[0]++))
            array_semver[1]=0
            array_semver[2]=0
        ;;
        "${INPUT_MINOR,,}" )
            ((array_semver[1]++))
            array_semver[2]=0
        ;;
        "patch" )
            ((array_semver[2]++))
        ;;
    esac

    local incremented_semver
    incremented_semver="${array_semver[0]}.${array_semver[1]}.${array_semver[2]}"

    printf '%s' "$incremented_semver"
}

# ---------------------------------------------
# Bump new SemVer on given JSON file
# Use 'jq' to update the file (based on v1.6)
# ---------------------------------------------
# Required Variable:
#   $INPUT_PREFIX
# Return:
#   0 if JSON file's updated successfully
# ---------------------------------------------
bump_version_into_json_file() {
    local semver
    semver=$(echo "$1" | sed -r 's/^'"${INPUT_PREFIX}"'//')

    local file_path="${INPUT_FILE_PATH}"

    if [[ ${file_path,,} = *".json"* ]]; then
        jq --arg semver "$semver" '.version=$semver' "${file_path}" > tmpfile && mv tmpfile "${file_path}"
    fi
}

semver_kind_from_commit_message() {
    local message="$1"

    if [[ ${message,,} = ${INPUT_MAJOR,,}* ]]; then
        printf '%s' "${INPUT_MAJOR,,}"
    elif [[ ${message,,} = ${INPUT_MINOR,,}* ]]; then
        printf '%s' "${INPUT_MINOR,,}"
    else
        printf "patch"
    fi
}

convert_snapshot_onto_release() {
    local current_version
    current_version="$1"

    local convert
    convert="${current_version%-*}"

    echo "$convert"
}
