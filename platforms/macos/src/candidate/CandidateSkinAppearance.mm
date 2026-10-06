#import "CandidateSkinAppearance.h"

NSNotificationName const LingyaoCandidateSkinDidChangeNotification =
    @"LingyaoCandidateSkinDidChangeNotification";
// The same key MSIMEAppearancePreferences writes, so the retained panel and the toolbar fallback draw the theme the settings window chose.
static NSString *const kGlobalThemePreferenceKey = @"MSIMEClientGlobalTheme";

NSColor *LingyaoColorFromRgba(lingyao::mac::Rgba color)
{
    return [NSColor colorWithSRGBRed:color.r green:color.g blue:color.b alpha:color.a];
}

BOOL LingyaoAppearanceIsDark(NSAppearance *appearance)
{
    NSAppearance *resolved = appearance;
    if (resolved == nil)
    {
        resolved = NSApp.effectiveAppearance;
    }
    if (resolved == nil)
    {
        resolved = NSAppearance.currentDrawingAppearance;
    }
    if (resolved == nil)
    {
        return NO;
    }
    NSString *match = [resolved bestMatchFromAppearancesWithNames:@[ NSAppearanceNameAqua, NSAppearanceNameDarkAqua ]];
    return [match isEqualToString:NSAppearanceNameDarkAqua];
}

NSURL *LingyaoCandidateSkinsDirectoryURL(void)
{
    const std::filesystem::path path = lingyao::mac::DefaultSkinsRoot();
    if (path.empty())
    {
        return nil;
    }
    return [NSURL fileURLWithPath:@(path.c_str()) isDirectory:YES];
}

NSString *LingyaoStoredGlobalTheme(void)
{
    NSString *value = [[NSUserDefaults standardUserDefaults] stringForKey:kGlobalThemePreferenceKey];
    return lingyao::mac::IsGlobalThemeId(value.UTF8String ?: "") ? value : @"system";
}

void LingyaoSetStoredGlobalTheme(NSString *themeId)
{
    if (!lingyao::mac::IsGlobalThemeId(themeId.UTF8String ?: ""))
    {
        return;
    }
    [[NSUserDefaults standardUserDefaults] setObject:themeId forKey:kGlobalThemePreferenceKey];
    [[NSNotificationCenter defaultCenter] postNotificationName:LingyaoCandidateSkinDidChangeNotification
                                                        object:themeId];
}

lingyao::mac::CustomTheme LingyaoStoredCustomTheme(void)
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    auto read = [defaults](NSString *key) {
        NSString *value = [defaults stringForKey:key];
        return std::string(value.UTF8String ?: "");
    };
    lingyao::mac::CustomTheme custom;
    const std::string base = read(@"MSIMEClientCustomThemeBase");
    custom.base = lingyao::mac::IsThemeBaseId(base) ? base : "system";
    custom.candidateSkin = read(@"MSIMEClientCustomCandidateSkin");
    custom.candidateColors.text = read(@"MSIMEClientCandidateTextColor");
    custom.candidateColors.number = read(@"MSIMEClientCandidateNumberColor");
    custom.candidateColors.accent = read(@"MSIMEClientCandidateAccentColor");
    custom.candidateColors.selected = read(@"MSIMEClientCandidateSelectedColor");
    custom.candidateColors.hover = read(@"MSIMEClientCandidateHoverColor");
    custom.candidateColors.surface = read(@"MSIMEClientCandidateSurfaceColor");
    custom.candidateColors.border = read(@"MSIMEClientCandidateBorderColor");
    return custom;
}

lingyao::mac::ResolvedSkin LingyaoResolveStoredTheme(BOOL dark, BOOL vertical)
{
    return lingyao::mac::ResolveSkin(LingyaoStoredGlobalTheme().UTF8String, LingyaoStoredCustomTheme(), dark,
                                         vertical ? "vertical" : "horizontal", lingyao::mac::DefaultSkinsRoot());
}
