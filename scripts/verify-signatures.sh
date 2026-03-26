#!/bin/bash

# Signature Verification Script
# This script verifies the Cosign signatures of Go container images

set -e

echo "=========================================="
echo "Container Image Signature Verification"
echo "=========================================="
echo ""

# List of images to verify
IMAGES=(
    "localhost:5000/go-multi-patched:latest"
)

# Track verification results
PASSED=0
FAILED=0

for image in "${IMAGES[@]}"; do
    echo "Verifying: $image"
    echo "------------------------------------------"
    
    if cosign verify "$image" --insecure-ignore-sct 2>/dev/null; then
        echo "✅ Signature verified successfully"
        ((PASSED++))
    else
        echo "❌ Signature verification failed"
        ((FAILED++))
    fi
    echo ""
done

echo "=========================================="
echo "Summary"
echo "=========================================="
echo "Passed: $PASSED"
echo "Failed: $FAILED"
echo ""

if [ $FAILED -eq 0 ]; then
    echo "All images verified successfully!"
    exit 0
else
    echo "Some images failed verification."
    exit 1
fi