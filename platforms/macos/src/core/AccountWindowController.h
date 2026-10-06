#pragma once
#import <AppKit/AppKit.h>
@interface LINGYAOAccountWindowController : NSWindowController
+ (instancetype)sharedController;
- (void)showForAccountID:(NSString *)accountID;
@end
