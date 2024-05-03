#!/bin/bash

# Set the repository owner and name
OWNER="Lakr233"
REPO="GitLab-License-Generator"

# Set the artifact name to download
ARTIFACT_NAME="build"

# Set the number of artifacts per build to retrieve (latest only)
ARTIFACTS_PER_BUILD=1

# Set the output directory for the downloaded artifact
OUTPUT_DIR="gitlab-license"

# Set the desired name for the downloaded artifact file
ARTIFACT_FILE_NAME="gitlab-license.zip"

# Set the path to the file containing the GitHub token
TOKEN_FILE="github-token"

# Check if the token file exists
if [[ ! -f "$TOKEN_FILE" ]]; then
  echo "GitHub token file not found: $TOKEN_FILE"
  exit 1
fi

# Read the GitHub token from the file, ignoring commented lines
GITHUB_TOKEN=$(grep -v '^#' "$TOKEN_FILE" | tr -d '\n')

# Construct the API URL to retrieve the list of artifacts
ARTIFACTS_URL="https://api.github.com/repos/$OWNER/$REPO/actions/artifacts?per_page=$ARTIFACTS_PER_BUILD"

# Fetch the artifacts JSON data from the API
ARTIFACTS_JSON=$(curl -s -H "Authorization: token $GITHUB_TOKEN" "$ARTIFACTS_URL")

echo "Artifacts JSON:"
echo "$ARTIFACTS_JSON"

# Extract the archive download URL from the JSON data
ARCHIVE_DOWNLOAD_URL=$(echo "$ARTIFACTS_JSON" | jq -r '.artifacts[0].archive_download_url')

echo "Archive Download URL:"
echo "$ARCHIVE_DOWNLOAD_URL"

# Check if the archive download URL is available
if [[ -n "$ARCHIVE_DOWNLOAD_URL" ]]; then
  # Create the output directory if it doesn't exist
  mkdir -p "$OUTPUT_DIR"

  # Download the artifact file to the output directory with the desired name
  if curl -L -H "Authorization: token $GITHUB_TOKEN" -o "$OUTPUT_DIR/$ARTIFACT_FILE_NAME" "$ARCHIVE_DOWNLOAD_URL"; then
    echo "Artifact downloaded successfully as $ARTIFACT_FILE_NAME"
  else
    echo "Failed to download the artifact."
    exit 1
  fi

  # Unzip the downloaded artifact
  if unzip -o "$OUTPUT_DIR/$ARTIFACT_FILE_NAME" -d "$OUTPUT_DIR"; then
    echo "Artifact unzipped successfully in the $OUTPUT_DIR directory."

    # Copy public.key to /opt/gitlab/embedded/service/gitlab-rails/.license_encryption_key.pub
    if [[ -f "$OUTPUT_DIR/public.key" ]]; then
      cp -rf "$OUTPUT_DIR/public.key" /opt/gitlab/embedded/service/gitlab-rails/.license_encryption_key.pub
      echo "Copied public.key to /opt/gitlab/embedded/service/gitlab-rails/.license_encryption_key.pub"
    else
      echo "public.key not found in the artifact."
    fi

    # Copy result.gitlab-license to /etc/gitlab/Gitlab.gitlab-license
    if [[ -f "$OUTPUT_DIR/result.gitlab-license" ]]; then
      cp -rf "$OUTPUT_DIR/result.gitlab-license" /etc/gitlab/Gitlab.gitlab-license
      echo "Copied result.gitlab-license to /etc/gitlab/Gitlab.gitlab-license"
    else
      echo "result.gitlab-license not found in the artifact."
    fi

    # Remove the gitlab-license directory
    rm -rf "$OUTPUT_DIR"
    echo "Removed the $OUTPUT_DIR directory."

    # Display success message and prompt for GitLab restart
    echo ""
    echo "GitLab license applied successfully!"
    echo "Please restart GitLab for the changes to take effect."
    read -p "Do you want to restart GitLab now? [Y/n]: " restart_choice

    case "$restart_choice" in
      Y|y|"")
        echo "Restarting GitLab..."
        gitlab-ctl restart
        ;;
      *)
        echo "Please restart GitLab manually later using the command: gitlab-ctl restart"
        ;;
    esac
  else
    echo "Failed to unzip the artifact."
    exit 1
  fi
else
  echo "Failed to retrieve the archive download URL."
  exit 1
fi