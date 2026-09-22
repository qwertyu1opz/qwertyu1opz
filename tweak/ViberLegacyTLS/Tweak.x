// ViberLegacyTLS — iOS 5 launch-crash fix + TLS negotiation shim for Viber.
//
// Step 1 (this file): make the legacy Viber app LAUNCH on iOS 5 and use the
// highest TLS its own SecureTransport supports, using only iOS-5-safe APIs.
//
// Why: the earlier injected ViberLegacy.dylib hard-imported
// kCFStreamPropertySSLContext (introduced long after iOS 5), so dyld failed
// to bind it and the app was killed before main(). Here we only touch
// kCFStreamPropertySSLSettings, which exists since iOS 2.
//
// Certificate validation is NOT disabled — with a modern CA bundle the right
// move is to validate properly, not bypass. If a later step routes traffic
// through a bundled modern TLS stack, validation happens there against the
// provided cacert.pem.

#import <substrate.h>
#import <CoreFoundation/CoreFoundation.h>
#import <CFNetwork/CFNetwork.h>

#define VL_LOG 1
#if VL_LOG
  #define VLLog(fmt, ...) CFShow(CFStringCreateWithFormat(NULL,NULL,CFSTR("[ViberLegacyTLS] " fmt),##__VA_ARGS__))
#else
  #define VLLog(fmt, ...)
#endif

static Boolean vl_is_viber_host(CFStringRef host) {
    if (!host) return false;
    CFRange r = CFStringFind(host, CFSTR("viber.com"), kCFCompareCaseInsensitive);
    return r.location != kCFNotFound;
}

// iOS-5-safe SSL settings: negotiate the strongest protocol/cipher the
// device supports. No kCFStreamPropertySSLContext anywhere.
static CFDictionaryRef vl_make_ssl_settings(CFStringRef peerName) {
    CFMutableDictionaryRef d = CFDictionaryCreateMutable(
        NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    CFDictionarySetValue(d, kCFStreamSSLLevel,
                         kCFStreamSocketSecurityLevelNegotiatedSSL);
    if (peerName)
        CFDictionarySetValue(d, kCFStreamSSLPeerName, peerName);
    // NOTE: chain validation intentionally left at the default (enabled).
    return d;
}

static void vl_apply(CFReadStreamRef rs, CFStringRef host) {
    if (!rs) return;
    CFDictionaryRef ssl = vl_make_ssl_settings(host);
    Boolean ok = CFReadStreamSetProperty(rs, kCFStreamPropertySSLSettings, ssl);
    CFRelease(ssl);
    VLLog("SSL settings applied host=%@ ok=%d", host ? host : CFSTR("(nil)"), ok);
}

%hookf(CFReadStreamRef, CFReadStreamCreateForHTTPRequest,
       CFAllocatorRef alloc, CFHTTPMessageRef request) {
    CFReadStreamRef rs = %orig(alloc, request);
    if (rs && request) {
        CFURLRef url = CFHTTPMessageCopyRequestURL(request);
        if (url) {
            CFStringRef scheme = CFURLCopyScheme(url);
            CFStringRef host   = CFURLCopyHostName(url);
            Boolean https = scheme && CFStringCompare(scheme, CFSTR("https"),
                              kCFCompareCaseInsensitive) == kCFCompareEqualTo;
            if (https && vl_is_viber_host(host)) vl_apply(rs, host);
            if (scheme) CFRelease(scheme);
            if (host)   CFRelease(host);
            CFRelease(url);
        }
    }
    return rs;
}

%hookf(void, CFStreamCreatePairWithSocketToHost,
       CFAllocatorRef alloc, CFStringRef host, UInt32 port,
       CFReadStreamRef *readStream, CFWriteStreamRef *writeStream) {
    %orig(alloc, host, port, readStream, writeStream);
    if (vl_is_viber_host(host) && readStream && *readStream)
        vl_apply(*readStream, host);
}

%ctor {
    VLLog("loaded — iOS5 launch shim active (SSLSettings path, no SSLContext symbol)");
}
