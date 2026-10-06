#pragma once

#import <AppKit/AppKit.h>

#include "CandidateSkin.h"

FOUNDATION_EXPORT NSNotificationName const LingyaoCandidateSkinDidChangeNotification;

NSColor *LingyaoColorFromRgba(metasequoia::mac::Rgba color);
BOOL LingyaoAppearanceIsDark(NSAppearance *appearance);
NSURL *LingyaoCandidateSkinsDirectoryURL(void);
/// The global theme id stored in the standard defaults under the key the settings window writes (`MSIMEClientGlobalTheme`). An id outside the catalog reads as `system`.
NSString *LingyaoStoredGlobalTheme(void);
/// Stores a global theme id and posts LingyaoCandidateSkinDidChangeNotification. An id outside the catalog is ignored.
void LingyaoSetStoredGlobalTheme(NSString *themeId);
/// The `custom_theme` the settings window stored: its base, its candidate skin and the seven picker colours.
metasequoia::mac::CustomTheme LingyaoStoredCustomTheme(void);
/// The stored global theme resolved for one mode and one candidate layout: a package is drawn only in the layouts its manifest declares.
metasequoia::mac::ResolvedSkin LingyaoResolveStoredTheme(BOOL dark, BOOL vertical);
