#pragma once
#import <Foundation/Foundation.h>

@protocol LINGYAOVoiceSettingsWindowRouting
+ (id)sharedController;
- (void)showAndActivate;
@end

// Both the input menu and the native appearance fallback must open the same
// provider editor. Keep the dynamic lookup because several isolated settings
// tests compile AppearancePreferences without linking the voice window.
static inline BOOL LINGYAOShowVoiceSettingsWindow(Class windowClass) {
    if (!windowClass || ![windowClass respondsToSelector:@selector(sharedController)]) return NO;
    id controller = [(Class<LINGYAOVoiceSettingsWindowRouting>)windowClass sharedController];
    if (![controller respondsToSelector:@selector(showAndActivate)]) return NO;
    [(id<LINGYAOVoiceSettingsWindowRouting>)controller showAndActivate];
    return YES;
}
