#!/usr/bin/env bash

set -e -u -o pipefail

get_commit_message_from_git () {
  echo $(git log -1 --pretty=%B)
}

get_incremented_semver () {
  local semver_kind="$1"
  local current_semver="$2"

  local semver=$(func_increment_semver $semver_kind $current_semver)
  echo "${INPUT_PREFIX}$semver"
}

get_latest_tag_from_git () {
  local last_commit_id=$(git rev-list --tags --max-count=1)

  if [ -z "$last_commit_id" ]; then
      echo "0.0.0"
  else
      local latest_tag=$(git describe --tags $last_commit_id)
      echo "$latest_tag"
  fi
}

get_semver_kind_from_latest_commit_message () {
  local latest_commit_message="$(get_commit_message_from_git)"
  echo $(func_semver_kind_from_commit_message "$latest_commit_message")
}

func_bump_tag_into_git_repository () {
  local tag_semver="$1"
  local tag_message="$2"

  git tag -a "${tag_semver}" -m "${tag_message}"
  git push origin "${tag_semver}"
}

func_bump_version_into_json_file () {
  local semver=$(echo $1 | sed -r 's/^'"${INPUT_PREFIX}"'//')
  local file_path="${INPUT_FILE_PATH}"

  if [[ ${file_path,,} == *".json"* ]]; then
      echo "`jq --arg semver "$semver" '.version=$semver' ${file_path}`" > ${file_path}
  fi
}

func_git_config () {
  if [ -n "${GITHUB_TOKEN:-}" ];
  then
      git_profile="$(curl -s -H "Authorization: token ${GITHUB_TOKEN}" "https://api.github.com/users/${GITHUB_ACTOR}")"
      git config --global user.name "$(printf '%s' "$git_profile" | jq -r .name)"
      git config --global user.email "$(printf '%s' "$git_profile" | jq -r .email)"
  fi
}

func_increment_semver () {
  local semver_kind="$1"
  local current_semver=$(echo "$2" | tr -dc '0-9.')
  local array_semver=(${current_semver//./ })

  case $semver_kind in
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

  echo "${array_semver[0]}.${array_semver[1]}.${array_semver[2]}"
}

func_semver_kind_from_commit_message () {
  local message="$1"

  if [[ ${message,,} == *"${INPUT_MAJOR,,}"* ]]; then
      echo "${INPUT_MAJOR,,}"
  elif [[ ${message,,} == *"${INPUT_MINOR,,}"* ]]; then
      echo "${INPUT_MINOR,,}"
  else
      echo "patch"
  fi
}

func_update_last_commit_add_file () {
  local file_path="$1"

  git add $file_path
  git pull
  git commit --amend --no-edit
  git push origin -f

  return 0
}

echo "🔰 Git Config"
func_git_config

echo "🔰 Reading latest tag from Git repository"
latest_tag=$(get_latest_tag_from_git)
echo "💠 Latest tag: $latest_tag"

echo "🔰 Reading commit message from Git repository"
commit_message=$(get_commit_message_from_git)
echo "💠 Commit message: '$commit_message'"

echo "🔰 Determine SemVer kind from latest commit message"
semver_kind=$(get_semver_kind_from_latest_commit_message)
echo "💠 Semantic Version kind: '${semver_kind^^}'"

echo "🔰 Generate next SemVer based on last commit message"
next_semver=$(get_incremented_semver $semver_kind $latest_tag)
echo "💠 Next SemVer: '$next_semver'"

if [ "${INPUT_FILE_UPDATE}" = true ]; then
    echo "🔰 Update version in ${INPUT_FILE_PATH}"
    $(func_bump_version_into_json_file "$next_semver")

    echo "🔰 Update commit with updated file"
    func_update_last_commit_add_file "${INPUT_FILE_PATH}"
fi

if [ "${INPUT_BUMP_TAG}" = true ]; then
    echo "🔰 Bump SemVer tag to Git repository"
    func_bump_tag_into_git_repository "$next_semver" "$commit_message"
fi

echo "::set-output name=next-semver::$(echo $next_semver)"

echo "🔔 Done !"
