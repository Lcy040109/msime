#pragma once
#import <AppKit/AppKit.h>
@class LINGYAODesktopInputSession;

@protocol LINGYAODesktopCloudClipboardProvider
- (NSProgress *)request:(NSDictionary *)request completion:(void (^)(NSDictionary *))completion;
@end

@interface LINGYAODesktopCloudClipboardSession : NSObject
- (instancetype)initWithProvider:(id<LINGYAODesktopCloudClipboardProvider>)provider;
- (instancetype)initWithProvider:(id<LINGYAODesktopCloudClipboardProvider>)provider dictionary:(BOOL)dictionary;
@property(nonatomic, readonly, copy) NSDictionary<NSString *, NSString *> *launchEnvironment;
- (void)authorizePID:(pid_t)pid stillValid:(BOOL (^)(void))valid;
- (void)stop;
@end

void LINGYAOOpenDesktopCloudClipboard(NSString *optionsPath, NSWorkspace *workspace, dispatch_block_t fallback);
void LINGYAOOpenDesktopCloudDictionary(NSString *optionsPath, NSWorkspace *workspace, dispatch_block_t fallback);
void LINGYAOOpenDesktopCloudClipboardWithInput(NSString *optionsPath, NSWorkspace *workspace,
    LINGYAODesktopInputSession *inputSession, dispatch_block_t fallback);
