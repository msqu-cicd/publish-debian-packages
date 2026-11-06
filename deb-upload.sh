#!/usr/bin/env bash

set -u

# Check if all required environment variables are set
if [ -z "${FORGEJO_USER:-}" ]; then
  echo "Error: The environment variable FORGEJO_USER is not set." >&2
  exit 1
fi

if [ -z "${TOKEN:-}" ]; then
  echo "Error: The environment variable TOKEN is not set." >&2
  exit 1
fi

if [ -z "${FORGEJO_SERVER_URL:-}" ]; then
  echo "Error: The environment variable FORGEJO_SERVER_URL is not set." >&2
  exit 1
fi

if [ -z "${DIST:-}" ]; then
  echo "Error: The environment variable DIST is not set." >&2
  exit 1
fi

if [ -z "${COMPONENT:-}" ]; then
  echo "Error: The environment variable COMPONENT is not set." >&2
  exit 1
fi

if [ -z "${OVERWRITE:-}" ]; then
  echo "Error: The environment variable OVERWRITE is not set." >&2
  exit 1
fi

OVERWRITE=${OVERWRITE,,}
case "$OVERWRITE" in
  true | false) ;;
  *)
    echo "Error: OVERWRITE must be 'true' or 'false', got: $OVERWRITE" >&2
    exit 1
    ;;
esac

REPO_URL="$FORGEJO_SERVER_URL/api/packages/$FORGEJO_USER/debian/pool/$DIST/$COMPONENT"

# curl wrapper that passes the credentials via a config file on stdin
# instead of the command line, where other processes could read them.
curl_auth() {
  curl --silent --show-error --config - "$@" <<EOF
user = "$FORGEJO_USER:$TOKEN"
EOF
}

# Function to delete an existing version
# https://forgejo.org/docs/latest/user/packages/debian/
delete_version() {
  local package_name=$1
  local package_version=$2
  local arch=$3
  local delete_url="$REPO_URL/$package_name/$package_version/$arch"
  local http_status

  echo "Deleting existing version: $delete_url"
  if ! http_status=$(curl_auth -o /dev/null -w '%{http_code}' -X DELETE "$delete_url"); then
    echo "Error: DELETE request failed for $delete_url" >&2
    return 1
  fi

  if [ "$http_status" != "204" ]; then
    echo "Error: deleting $delete_url failed with HTTP status $http_status." >&2
    return 1
  fi
}

# Function to upload a package.
# Returns 0 on success, 2 if the version already exists (HTTP 409),
# and 1 on any other failure.
upload_package() {
  local deb_file=$1
  local upload_url="$REPO_URL/upload"
  local http_status

  echo "Uploading: $deb_file to $upload_url"
  if ! http_status=$(curl_auth -o /dev/null -w '%{http_code}' --upload-file "$deb_file" "$upload_url"); then
    echo "Error: upload request failed for $deb_file" >&2
    return 1
  fi

  case "$http_status" in
    201)
      echo "Upload of $deb_file completed."
      return 0
      ;;
    409)
      return 2
      ;;
    *)
      echo "Error: upload of $deb_file failed with HTTP status $http_status." >&2
      return 1
      ;;
  esac
}

# Check if at least one .deb file is provided as an argument
if [ "$#" -lt 1 ]; then
  echo "Usage: $0 <deb-file1> <deb-file2> ..." >&2
  exit 1
fi

FAILED=0

# Process each provided .deb file
for DEB_FILE in "$@"; do
  echo "Processing file: $DEB_FILE"

  if [ ! -f "$DEB_FILE" ]; then
    echo "Error: file not found: $DEB_FILE" >&2
    FAILED=1
    echo "----------------------------------------"
    continue
  fi

  # Extract package name, version and architecture from the
  # filename, which must follow the name_version_arch.deb scheme.
  FILE_NAME=$(basename "$DEB_FILE")
  BASE_NAME=${FILE_NAME%.deb}
  PACKAGE_NAME=$(echo "$BASE_NAME" | cut -d'_' -f1)
  PACKAGE_VERSION=$(echo "$BASE_NAME" | cut -d'_' -f2)
  ARCH=$(echo "$BASE_NAME" | cut -d'_' -f3)

  echo "Package name: $PACKAGE_NAME"
  echo "Package version: $PACKAGE_VERSION"
  echo "Architecture: $ARCH"

  upload_package "$DEB_FILE"
  UPLOAD_RESULT=$?

  if [ "$UPLOAD_RESULT" -eq 2 ]; then
    # Version already exists in the repository
    if [ "$OVERWRITE" = "true" ]; then
      if [ -z "$PACKAGE_NAME" ] || [ -z "$PACKAGE_VERSION" ] || [ -z "$ARCH" ]; then
        echo "Error: cannot overwrite $FILE_NAME, filename does not follow name_version_arch.deb." >&2
        FAILED=1
      elif ! delete_version "$PACKAGE_NAME" "$PACKAGE_VERSION" "$ARCH"; then
        FAILED=1
      else
        if ! upload_package "$DEB_FILE"; then
          echo "Error: re-upload of $DEB_FILE after deleting the existing version failed." >&2
          FAILED=1
        fi
      fi
    else
      echo "Version exists. Overwrite is disabled. Skipping file: $DEB_FILE"
    fi
  elif [ "$UPLOAD_RESULT" -ne 0 ]; then
    FAILED=1
  fi

  echo "----------------------------------------"
done

exit "$FAILED"
