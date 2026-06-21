#!/bin/bash
case "${CONFIGURATION}" in
  "Debug"|"Test")
    if [ "${PLATFORM_NAME}" = "iphonesimulator" ] || [ -n "${MAC_IP_ADDRESS}" ]; then
      PLIST_SOURCE="${PROJECT_DIR}/YouDoYouClient/env/plists/GoogleService-Info-emu.plist"
    else
      PLIST_SOURCE="${PROJECT_DIR}/YouDoYouClient/env/plists/GoogleService-Info-dev.plist"
    fi
    ;;
  "Release")
    PLIST_SOURCE="${PROJECT_DIR}/YouDoYouClient/env/plists/GoogleService-Info-prod.plist"
    ;;
esac

cp "${PLIST_SOURCE}" "${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.app/GoogleService-Info.plist"
