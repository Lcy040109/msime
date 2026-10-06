// Adapted from LINGYAO-Apple b637828e15eafcb5e459edd270a962dd14517285.
#pragma once

#import <AppKit/AppKit.h>

#include "CandidateSkin.h"

@class LINGYAOAppearancePreferences;
@interface LINGYAOCandidatePreviewView : NSView
@property(nonatomic, weak) LINGYAOAppearancePreferences *preferences;
@property(nonatomic, weak) NSButton *themeButton;
- (void)updatePanelStyle:(NSInteger)panelStyle pageSize:(NSInteger)pageSize fontSize:(NSInteger)fontSize;
- (void)setPreviewSkinId:(NSString *)skinId;
- (NSString *)previewSkinId;
/// The words the preview draws as candidates, whitespace separated. Empty text restores the built-in samples. Applied after a short delay, because this is what a text field the user is typing into is wired to.
- (void)setSampleText:(NSString *)sampleText;
- (NSString *)sampleText;
- (void)setShowsLayoutShowcase:(BOOL)showsLayoutShowcase;
- (void)toggleForcedTheme;
- (BOOL)previewUsesDark;
- (NSString *)forcedThemeButtonTitle;
- (void)reloadPreview;
- (lingyao::mac::ResolvedSkin)previewSkin;
- (NSColor *)previewCanvasFillColor;
- (NSColor *)previewPanelFillColor;
- (NSColor *)previewTextColor;
- (NSColor *)previewAccentColor;
- (CGFloat)previewContentHeight;
@end

/// The floating toolbar drawn at the size the toolbar settings actually produce: the components that are ticked, laid out with LingyaoFloatingToolbarPanel's own metrics for the chosen 工具栏缩放 and 工具栏字号. The 状态栏 page offers four scale steps and seven font sizes, and until this view there was nowhere in the window those 28 combinations looked like anything.
@interface LINGYAOToolbarPreviewView : NSView
@property(nonatomic, weak) LINGYAOAppearancePreferences *preferences;
- (void)reloadPreview;
- (BOOL)previewUsesDark;
@end

#define LingyaoCandidatePreviewView LINGYAOCandidatePreviewView
