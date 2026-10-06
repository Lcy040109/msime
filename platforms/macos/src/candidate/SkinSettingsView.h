#pragma once

#import <AppKit/AppKit.h>

@class LINGYAOAppearancePreferences;
@interface LingyaoSkinSettingsView : NSView
@property(nonatomic, weak, readonly) LINGYAOAppearancePreferences *preferences;
@property(nonatomic, copy) BOOL (^directoryOpener)(NSURL *url);
- (instancetype)initWithFrame:(NSRect)frameRect preferences:(LINGYAOAppearancePreferences *)preferences;
- (void)reload;
- (void)refreshSelection;
@end
