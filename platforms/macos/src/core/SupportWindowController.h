#pragma once

#import <AppKit/AppKit.h>

typedef NS_ENUM(NSInteger, LINGYAOSupportPage) {
    LINGYAOSupportPageHelp = 0,
    LINGYAOSupportPageAbout,
    LINGYAOSupportPageFeedback,
};

NS_ASSUME_NONNULL_BEGIN

/// Native counterparts of the Windows help, about, and feedback pages.
@interface LINGYAOSupportWindowController : NSWindowController
+ (instancetype)sharedController;
@property(nonatomic, readonly) LINGYAOSupportPage page;
- (void)showPage:(LINGYAOSupportPage)page;
@end

NS_ASSUME_NONNULL_END
