#!/usr/bin/env bash
# Upload a logo image to Dynatrace as an image document via dtctl apply.
#
# Usage:
#   ./upload-logo.sh                                   # nvidia-logo.png -> nvidia-dcgm-logo
#   ./upload-logo.sh logo.png my-tech-logo "My Logo"
#
# Arguments:
#   $1  Image file  (default: nvidia-logo.png)
#   $2  Document ID (default: nvidia-dcgm-logo)
#   $3  Description (default: Dashboard logo)
#
# The document ID appears in the dashboard tile as:
#   imageSettings.defaultSource: /platform/document/v1/documents/<id>/content
#
# Requires: dtctl authenticated to the target tenant, base64, fold (both POSIX standard)

set -euo pipefail

FILE="${1:-$(dirname "$0")/nvidia-logo.png}"
DOC_ID="${2:-nvidia-dcgm-logo}"
DESCRIPTION="${3:-Dashboard logo}"

if [[ ! -f "$FILE" ]]; then
  echo "ERROR: Image file not found: $FILE" >&2
  exit 1
fi

TMP_YAML=$(mktemp /tmp/dtlogo.XXXXXX.yaml)
trap 'rm -f "$TMP_YAML"' EXIT

# Build YAML with base64-encoded binary content (2-space indent, 76-char wrap)
{
  printf "id: %s\n" "$DOC_ID"
  printf "name: %s\n" "$DOC_ID"
  printf "type: image\n"
  printf "isPrivate: false\n"
  printf "description: %s\n" "$DESCRIPTION"
  printf "content: !!binary |\n"
  base64 < "$FILE" | fold -w 76 | sed 's/^/  /'
} > "$TMP_YAML"

echo "Uploading $FILE as document '$DOC_ID'..."
dtctl apply -f "$TMP_YAML" --plain
echo "defaultSource: /platform/document/v1/documents/$DOC_ID/content"
