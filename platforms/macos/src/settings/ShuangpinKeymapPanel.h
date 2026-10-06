#pragma once

#import <AppKit/AppKit.h>

FOUNDATION_EXPORT NSArray<NSArray<NSDictionary<NSString *, NSString *> *> *> *LINGYAOShuangpinKeymapRows(
    NSString *profileName);

FOUNDATION_EXPORT NSString *LINGYAOShuangpinZeroInitialText(NSString *profileName);

FOUNDATION_EXPORT BOOL LINGYAOShouldShowShuangpinKeymap(BOOL isShuangpin, BOOL enabled, BOOL hasComposition);

// Raw Engine input, independent of the selected preedit display format.
FOUNDATION_EXPORT NSString *LINGYAOShuangpinKeymapEditingText(NSDictionary *view);
FOUNDATION_EXPORT NSString *LINGYAOShuangpinKeymapHighlightedKey(NSDictionary *view);

FOUNDATION_EXPORT NSRect LINGYAOShuangpinKeymapPanelFrame(NSRect caretRect, NSSize panelSize,
                                                              CGFloat candidateClearance, NSRect visibleFrame);

@interface LINGYAOShuangpinKeymapPanel : NSPanel
- (void)setProfileName:(NSString *)profileName;
- (void)updateHighlightedKey:(NSString *)key;
/// The fill of the highlighted key: the theme's accent, as a dynamic colour so it resolves in the panel's appearance. Until set, the panel's own teal.
- (void)setAccentColor:(NSColor *)accent;
@property(nonatomic, readonly) NSColor *accentColor;
- (void)showNearCaretRect:(NSRect)caretRect candidateClearance:(CGFloat)candidateClearance;
@end
