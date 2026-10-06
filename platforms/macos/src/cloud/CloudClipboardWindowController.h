#pragma once
#import <AppKit/AppKit.h>
@interface LINGYAOCloudClipboardWindowController : NSWindowController
+ (instancetype)sharedController;
- (void)showWithToken:(NSString *)token;
@end
