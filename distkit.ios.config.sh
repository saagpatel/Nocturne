# distribution-kit iOS lane contract for Nocturne.
# Consumed by <distribution-kit>/lanes/ios.sh; every Nocturne-specific value
# lives here, none in the lane. No secrets: the ASC issuer id stays in the
# Keychain and is fetched by the lane at runtime.
DK_PRODUCT_NAME="Nocturne"
DK_BUNDLE_ID="com.nocturnn.app"
DK_VERSION="1.0"
DK_BUILD_NUMBER="3"
DK_PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DK_SCHEME="Nocturne"
DK_XCODE_PROJECT="Nocturne.xcodeproj"
DK_GENERATE_CMD="xcodegen generate"
DK_EXPORT_OPTIONS="$DK_PROJECT_DIR/ExportOptions.plist"
# Signing comes from per-target Release settings in project.yml.
DK_IOS_SIGN_STYLE="project"
DK_SIGNING_IDENTITY="Apple Distribution"
DK_PROFILE_NAME="Nocturne App Store"
DK_REQUIRE_PRIVACY_MANIFEST=1
DK_ASC_KEY_ID="6NPVH55ZWG"
DK_ASC_ISSUER_SERVICE="asc-radar"
DK_ASC_ISSUER_ACCOUNT="issuer_id"
