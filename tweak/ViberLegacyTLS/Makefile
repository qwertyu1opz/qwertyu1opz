# Theos tweak for legacy Viber TLS compatibility on iOS 5.
# Build:  make package        (produces .deb under ./packages)
# Deploy: make package install THEOS_DEVICE_IP=<device>
#
# Requires Theos with an iOS 5.x/6.x SDK available. Deployment target
# is pinned to 5.0 so nothing newer than iOS 5 symbols gets linked.

TARGET   := iphone:clang:8.1:5.0
ARCHS    := armv7 armv7s

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = ViberLegacyTLS
ViberLegacyTLS_FILES      = Tweak.x
ViberLegacyTLS_FRAMEWORKS = CoreFoundation CFNetwork Security
ViberLegacyTLS_CFLAGS     = -Wno-deprecated-declarations -Wno-unused

include $(THEOS)/makefiles/tweak.mk
