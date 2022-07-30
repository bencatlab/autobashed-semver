#!/usr/bin/env bash

# ---------------------------------------------
# Bump tag based on the new SemVer,
# and add the latest commit message to it
# ---------------------------------------------
# Arguments:
#   $1: Version from latest tag
#   $2: Latest commit message
# Return:
#   0 if tag was created successfully
# ---------------------------------------------
bump_tag_into_git_repository() {
	local tag_semver="$1"
	local tag_message="$2"

	git tag -a "${tag_semver}" -m "${tag_message}"
	git push origin "${tag_semver}" >/dev/null 2>&1
}

# ---------------------------------------------
# Get latest commit message from repository
# ---------------------------------------------
# Return:
#   Latest commit message
# ---------------------------------------------
latest_git_commit_message() {
	local commit_message
	commit_message=$(git log -1 --pretty=%B)

	printf '%s\n' "${commit_message}"
}

# ---------------------------------------------
# Get latest tag from repository,
# or create one if not exist
# ---------------------------------------------
# Return:
#   Latest tag || 0.0.0
# ---------------------------------------------
latest_tag_from_git_repository() {
	local latest_commit_id
	latest_commit_id=$(git rev-list --tags --max-count=1)

	local latest_tag
	if [ -z "$latest_commit_id" ]; then
		latest_tag="0.0.0"
	else
		latest_tag=$(git describe --tags "$latest_commit_id")
	fi
	printf '%s\n' "$latest_tag"
}

# ---------------------------------------------
# Authenticate current user to Github, 
# get json profile, trim name and email
# ---------------------------------------------
# Returns:
#   User name
#   User email
# ---------------------------------------------
github_user_config() {
    local gh_user_info
    gh_user_info=$(curl -s -S \
        -H "Accept: application/vnd.github.v3+json Authorization: token ${GITHUB_TOKEN}" \
        "https://api.github.com/users/${GITHUB_ACTOR}")

    if [[ "$gh_user_info" == *"Bad credentials"* || "$gh_user_info" == *"Not Found"* ]]; then
        printf "\t❌ Oups, something's wrong !\n\t🔔 Please check your token access level.\n"
        exit 1
    fi

    local gh_user_name
    gh_user_name="$(printf '%s' "$gh_user_info" | jq -r .name)"
    git config --global user.name "$gh_user_name"
    echo "${gh_user_name}"

    local gh_user_email
    gh_user_email="$(printf '%s' "$gh_user_info" | jq -r .email)"
    if [[ "$gh_user_email" == "null" ]]; then
        local gh_user_login
        gh_user_login="$(printf '%s' "$gh_user_info" | jq -r .login)"
        gh_user_email="${gh_user_login}@users.noreply.github.com"
    fi
    git config --global user.email "$gh_user_email"
    echo "${gh_user_email}"
}

# ---------------------------------------------
# Update current commit with updated file
# ---------------------------------------------
# Argument:
#   $1: Relative path of updated file
# Return:
#   0 if commit was pushed successfully
# ---------------------------------------------
update_current_commit() {
	local file_path
    file_path="$1"

	git add "${file_path}"
	git pull > /dev/null 2>&1
	git commit --amend --no-edit > /dev/null 2>&1
	git push origin -f > /dev/null 2>&1
}

