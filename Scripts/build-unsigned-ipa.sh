#!/bin/bash
#
# Build unsigned WebDriverAgent IPA for iOS devices
#

set -e

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DERIVED_DATA_PATH="${ROOT_DIR}/wdaBuild"
BUILD_DIR="${DERIVED_DATA_PATH}/Build/Products/Debug-iphoneos"
SCHEME="WebDriverAgentRunner"
TARGET_APP="${SCHEME}-Runner.app"
PAYLOAD_DIR="${ROOT_DIR}/Payload"
IPA_NAME="WebDriverAgent-unsigned.ipa"

echo "================================================"
echo "Building unsigned WebDriverAgent IPA"
echo "================================================"
echo "Root directory: ${ROOT_DIR}"
echo "Build directory: ${BUILD_DIR}"
echo ""

# Clean previous builds
echo "Cleaning previous builds..."
rm -rf "${DERIVED_DATA_PATH}"
rm -rf "${PAYLOAD_DIR}"
rm -f "${ROOT_DIR}/${IPA_NAME}"

# Build for device without signing
echo ""
echo "Building WebDriverAgent for iOS device (unsigned)..."
xcodebuild clean build-for-testing \
  -project "${ROOT_DIR}/WebDriverAgent.xcodeproj" \
  -scheme "${SCHEME}" \
  -derivedDataPath "${DERIVED_DATA_PATH}" \
  -destination "generic/platform=iOS" \
  -sdk iphoneos \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  AD_HOC_CODE_SIGNING_ALLOWED=NO

echo ""
echo "Build completed successfully!"
echo ""

# Create Payload directory structure
echo "Creating IPA package structure..."
mkdir -p "${PAYLOAD_DIR}"
cp -r "${BUILD_DIR}/${TARGET_APP}" "${PAYLOAD_DIR}/"

# Remove unnecessary frameworks to reduce size
# These frameworks should be loaded from the device instead of being embedded
echo "Removing unnecessary embedded frameworks..."
if [ -d "${PAYLOAD_DIR}/${TARGET_APP}/Frameworks" ]; then
  cd "${PAYLOAD_DIR}/${TARGET_APP}/Frameworks"
  rm -rf XCTAutomationSupport.framework 2>/dev/null || true
  rm -rf XCTest.framework 2>/dev/null || true
  rm -rf XCTestCore.framework 2>/dev/null || true
  rm -rf XCUIAutomation.framework 2>/dev/null || true
  rm -rf XCUnit.framework 2>/dev/null || true
  rm -rf Testing.framework 2>/dev/null || true
  rm -f libXCTestSwiftSupport.dylib 2>/dev/null || true
  cd "${ROOT_DIR}"
fi

# Create IPA file
echo ""
echo "Creating IPA file..."
cd "${ROOT_DIR}"
zip -qr "${IPA_NAME}" Payload

# Clean up temporary Payload directory
rm -rf "${PAYLOAD_DIR}"

echo ""
echo "================================================"
echo "SUCCESS!"
echo "================================================"
echo "IPA file created: ${ROOT_DIR}/${IPA_NAME}"
echo ""
echo "Note: This is an unsigned IPA. To install on a device, you need to:"
echo "1. Sign it with your own certificate using tools like iOS App Signer"
echo "2. Or use tools like Sideloadly, AltStore, etc. to install"
echo ""
