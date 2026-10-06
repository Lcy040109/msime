#pragma once
#import <Foundation/Foundation.h>

// Swift class is loaded from the bundled dylib, not linked into native tests.
@protocol LINGYAOBackendAccountEntry <NSObject>
+ (id)shared;
- (void)showAccount;
- (void)showCloudClipboard;
@end

static inline BOOL LINGYAOOpenBackendAccount(Class windowClass) {
    if (![windowClass respondsToSelector:@selector(shared)]) return NO;
    id<LINGYAOBackendAccountEntry> window = [(id<LINGYAOBackendAccountEntry>)windowClass shared];
    if (![window respondsToSelector:@selector(showAccount)]) return NO;
    [window showAccount];
    return YES;
}

static inline BOOL LINGYAOOpenBackendClipboard(Class windowClass) {
    if (![windowClass respondsToSelector:@selector(shared)]) return NO;
    id<LINGYAOBackendAccountEntry> window = [(id<LINGYAOBackendAccountEntry>)windowClass shared];
    if (![window respondsToSelector:@selector(showCloudClipboard)]) return NO;
    [window showCloudClipboard];
    return YES;
}
