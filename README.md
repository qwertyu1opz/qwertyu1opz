# ViberLegacyTLS

Jailbreak (MobileSubstrate) tweak that makes a legacy **Viber** build launch and
negotiate the strongest available TLS on **iOS 5**, without patching the app
binary and without an external proxy. Version-agnostic: it filters by bundle id
`com.viber` and hooks CFNetwork stream creation, so it does not depend on any
particular Viber build's offsets.

## What step 1 fixes
The previously injected `ViberLegacy.dylib` hard-imported
`kCFStreamPropertySSLContext` (introduced long after iOS 5), so `dyld` failed to
bind the symbol and killed the app before `main()`. This tweak uses only
`kCFStreamPropertySSLSettings` (available since iOS 2), so the launch crash is
gone. Certificate validation is left enabled (not bypassed).

## Build
No local machine needed — GitHub Actions builds the `.deb`:
push to `claude/help-needed-xazcdt` (or run the **build-tweak** workflow
manually), then download the `ViberLegacyTLS-deb` artifact from the run.

Locally, with Theos + an armv7-capable iOS SDK:

    cd tweak/ViberLegacyTLS && make package

## Install on device (jailbroken iOS 5)

    dpkg -i com.legacy.viberlegacytls_*.deb
    killall -9 Viber SpringBoard

Then reproduce the launch and capture syslog lines prefixed `[ViberLegacyTLS]`
plus any crash report — that decides the next step (whether iOS 5's own TLS can
reach the server, or a bundled modern TLS stack is required).
