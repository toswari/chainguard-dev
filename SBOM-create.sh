#!/usr/bin/env bash
set -euo pipefail

# This script generates a Software Bill of Materials (SBOM) for a container image using Syft.
# Usage: ./generate-sbom.sh <image-name> <output-file>

IMAGE=${1:-}
OUTPUT=${2:-sbom.json}

if [[ -z "$IMAGE" ]]; then
  echo "Usage: $0 <image-name> [output-file]"
  exit 1
fi

# Generate SBOM in JSON format
syft $IMAGE -o json > "$OUTPUT"

echo "SBOM generated at $OUTPUT"