#import "PreferencesWindowController.h"
#import "AppearancePreferences.h"
#import "SettingsLayout.h"
#import "../candidate/CandidateSkinAppearance.h"
#import "../cloud/CloudAppearanceSettings.h"
#import "../core/WindowPresentation.h"

static NSString *const LINGYAOSchemeKey = @"LingyaoImeScheme";
static NSString *const LINGYAOShuangpinSchemaKey = @"LingyaoImeShuangpinSchema";
NSNotificationName const LINGYAOStandalonePreferencesDidCloseNotification =
    @"LINGYAOStandalonePreferencesDidCloseNotification";

@implementation LINGYAOPreferencesWindowController {
    BOOL _standaloneLaunch;
}
+ (NSDictionary *)cloudSettingsSnapshot { return [[LINGYAOAppearancePreferences sharedPreferences] cloudSettingsSnapshot]; }
+ (NSNumber *)validateCloudSettingsSnapshot:(NSDictionary *)values { return @(LINGYAOValidateCloudAppearance(values)); }
+ (NSNumber *)applyCloudSettingsSnapshot:(NSDictionary *)values {
    return @([[LINGYAOAppearancePreferences sharedPreferences] applyCloudSettingsSnapshot:values]);
}
+ (NSString *)storedGlobalTheme { return LingyaoStoredGlobalTheme(); }
+ (void)setStoredGlobalTheme:(NSString *)themeId { LingyaoSetStoredGlobalTheme(themeId); }
+ (NSString *)themeTitleForIdentifier:(NSString *)themeId {
    return @(lingyao::mac::ThemeTitle(themeId.UTF8String ?: "").c_str());
}
+ (instancetype)sharedController {
    static LINGYAOPreferencesWindowController *controller;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ controller = [[self alloc] initWithWindow:nil]; });
    return controller;
}
- (void)presentAndActivate {
    // The first presentation builds every settings page, which is long enough to read as a click that did nothing.
    const uint64_t started = clock_gettime_nsec_np(CLOCK_UPTIME_RAW);
    const BOOL built = [LINGYAOAppearancePreferences sharedPreferences].isWindowLoaded;
    [[LINGYAOAppearancePreferences sharedPreferences] showWindow:nil];
    NSWindow *window = [LINGYAOAppearancePreferences sharedPreferences].window;
    os_log(LINGYAOUILog(), "settings_window_shown standalone=%d already_built=%d elapsed_ms=%llu", _standaloneLaunch, built,
           (unsigned long long)((clock_gettime_nsec_np(CLOCK_UPTIME_RAW) - started) / 1000000));
    // This controller is the one that presents the settings window and the one that decides what
    // closing it means, so it is the one that has to hold it: -window answered nil until now, and
    // every caller reaching through it — starting with the standalone launch that has to know which
    // window closing terminates the process — was reaching through nothing.
    self.window = window;
    window.delegate = self;
    // Only when the user has never placed this window. Centring unconditionally is what made the
    // saved frame pointless: the window came back the size it was left at, in the middle of the
    // screen, on every single presentation.
    if (!LINGYAOSettingsWindowHasSavedFrame()) [window center];
    LINGYAOPresentWindow(window);
}
- (void)showAndActivate {
    _standaloneLaunch = NO;
    [self presentAndActivate];
}
- (void)showAndActivateWithPageIdentifier:(NSString *)identifier {
    [self showAndActivate];
    const uint64_t started = clock_gettime_nsec_np(CLOCK_UPTIME_RAW);
    [[LINGYAOAppearancePreferences sharedPreferences] showSettingsPageWithIdentifier:identifier];
    os_log(LINGYAOUILog(), "settings_page_shown page=%{public}@ elapsed_ms=%llu", identifier,
           (unsigned long long)((clock_gettime_nsec_np(CLOCK_UPTIME_RAW) - started) / 1000000));
}
- (void)showAndActivateForStandaloneLaunch {
    _standaloneLaunch = YES;
    [self presentAndActivate];
}
- (void)windowWillClose:(NSNotification *)notification {
    (void)notification;
    if (!_standaloneLaunch) return;
    _standaloneLaunch = NO;
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter]
            postNotificationName:LINGYAOStandalonePreferencesDidCloseNotification object:self];
    });
}
- (NSDictionary *)cloudSettingsSnapshot { return [self.class cloudSettingsSnapshot]; }
- (BOOL)validateCloudSettingsSnapshot:(NSDictionary *)values { return [[self.class validateCloudSettingsSnapshot:values] boolValue]; }
- (BOOL)applyCloudSettingsSnapshot:(NSDictionary *)values { return [[self.class applyCloudSettingsSnapshot:values] boolValue]; }
@end
