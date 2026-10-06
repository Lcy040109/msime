#import <AppKit/AppKit.h>
#import <InputMethodKit/InputMethodKit.h>
#import "InputModeIdentifiers.h"
#import "InputSourceRegistration.h"
#import "../settings/PreferencesWindowController.h"
#import "../settings/RuntimeOptions.h"
#import "../settings/RuntimeOptionsRefresh.h"
#import "../settings/AppearancePreferences.h"
#import "../core/FloatingToolbarPanel.h"
#import "../core/UsageReporting.h"
#import "../candidate/CandidateSkin.h"
#import "../voice/VoiceAudioMuter.h"
#include <cstring>
#include <dlfcn.h>

static bool LINGYAOShouldShowPreferences(int argc, const char *argv[]) {
    for (int index = 1; index < argc; ++index) {
        if (strcmp(argv[index], "--preferences") == 0) return true;
    }
    return false;
}

static void LINGYAOConfigureMovableState(void) {
    NSDictionary *options = LINGYAOLoadRuntimeOptions();
    NSString *directory = [options[@"preferences_directory"] isKindOfClass:NSString.class]
        ? options[@"preferences_directory"] : nil;
    if (directory.length > 0 && directory.isAbsolutePath) {
        lingyao::mac::SetDefaultSkinsRoot(
            std::filesystem::path(directory.fileSystemRepresentation) / "skins");
    } else if (!LINGYAOEditionIsFull()) {
        // 没有配置状态目录时 CandidateSkin.cpp 退回 full 的状态目录；其他版本的皮肤在自己的状态目录下。
        NSURL *state = LINGYAODefaultClientStateDirectory(NSFileManager.defaultManager);
        if (state.path.length > 0)
            lingyao::mac::SetDefaultSkinsRoot(std::filesystem::path(state.path.fileSystemRepresentation) / "skins");
    }
}

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        if (LINGYAOShouldRegisterInputSource(argc, argv)) {
            NSURL *bundleURL = NSBundle.mainBundle.bundleURL;
            NSString *identifier = NSBundle.mainBundle.bundleIdentifier;
            OSStatus status = LINGYAORegisterAndEnableInputSources(bundleURL, identifier,
                TISRegisterInputSource, TISCreateInputSourceList,
                [](TISInputSourceRef source, CFStringRef key) -> void * {
                    return (void *)TISGetInputSourceProperty(source, key);
                }, TISEnableInputSource);
            return status == noErr ? 0 : 1;
        }
        [NSApplication sharedApplication];
        // After an app upgrade the options still point at the previous dictionary generation; bring them to the installed one (replaying the user dictionary) before any session, including the standalone preferences window's, reads them.
        // A missing file is the not-yet-configured state, which is not a refresh failure.
        NSString *optionsPath = LINGYAORuntimeOptionsPath();
        switch (optionsPath && [NSFileManager.defaultManager fileExistsAtPath:optionsPath]
                    ? LINGYAORefreshRuntimeOptions(optionsPath) : LINGYAORuntimeOptionsRefreshCurrent) {
        case LINGYAORuntimeOptionsRefreshUpdated:
            NSLog(@"LINGYAO dictionary updated to the installed generation");
            break;
        case LINGYAORuntimeOptionsRefreshFailed:
            NSLog(@"LINGYAO cannot update the dictionary to the installed generation; keeping the current one");
            break;
        case LINGYAORuntimeOptionsRefreshCurrent:
            break;
        }
        LINGYAOConfigureMovableState();
        NSString *swiftBackend = [NSBundle.mainBundle.privateFrameworksPath stringByAppendingPathComponent:@"LINGYAOBackend.dylib"];
        if (swiftBackend.length > 0 && dlopen(swiftBackend.fileSystemRepresentation, RTLD_NOW | RTLD_GLOBAL) == nullptr) return 1;
        // 独立设置窗口也要检查模式是否已加入输入法列表，所以在进入该分支前初始化探针。
        LINGYAOInputModeEnabledProbe = LINGYAOInputSourceIsEnabled;
        if (LINGYAOShouldShowPreferences(argc, argv)) {
            [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
            id closeObserver = [[NSNotificationCenter defaultCenter]
                addObserverForName:LINGYAOStandalonePreferencesDidCloseNotification
                            object:nil
                             queue:NSOperationQueue.mainQueue
                        usingBlock:^(NSNotification *notification) {
                            (void)notification;
                            [NSApp terminate:nil];
                        }];
            [[LINGYAOPreferencesWindowController sharedController] showAndActivateForStandaloneLaunch];
            [NSApp run];
            [[NSNotificationCenter defaultCenter] removeObserver:closeObserver];
            return 0;
        }
        // One input method process is one usage session; the standalone preferences window above is not.
        NSDictionary *reportingOptions = LINGYAOLoadRuntimeOptions();
        id reportingPreferences = reportingOptions[@"preferences_directory"];
        LINGYAOUsageReportingStart([reportingPreferences isKindOfClass:NSString.class] && [reportingPreferences isAbsolutePath] ? reportingPreferences : nil);
        // Recover a prior crashed capture before accepting new IMK sessions.
        // A running owner holds the journal lock, so this cannot undo its mute.
        [[[LINGYAOVoiceAudioMuter alloc] init] restore];
        // imklaunchagent 用这个名字找到本 bundle；名字为什么必须是这种形式，见 Info.plist.in。
        NSString *connectionName = NSBundle.mainBundle.infoDictionary[@"InputMethodConnectionName"];
        if (![connectionName isKindOfClass:NSString.class] || connectionName.length == 0) return 1;
        __attribute__((objc_precise_lifetime)) IMKServer *server = [[IMKServer alloc] initWithName:connectionName bundleIdentifier:NSBundle.mainBundle.bundleIdentifier];
        if (!server) return 1;
        // Turn on, once each, the input modes this version added and the install that brought it did not register. The opt-in modes are only recorded, and turned off once if the system turned them on.
        NSString *const offeredModesKey = @"LINGYAOOfferedInputModes";
        NSArray *offeredModes = [NSUserDefaults.standardUserDefaults arrayForKey:offeredModesKey];
        NSArray<NSString *> *offered = LINGYAOEnableNewInputModes(NSBundle.mainBundle.bundleIdentifier, offeredModes,
            TISCreateInputSourceList,
            [](TISInputSourceRef source, CFStringRef key) -> void * {
                return (void *)TISGetInputSourceProperty(source, key);
            }, TISEnableInputSource, TISDisableInputSource);
        if (![offered isEqualToArray:offeredModes]) [NSUserDefaults.standardUserDefaults setObject:offered forKey:offeredModesKey];
        __attribute__((objc_precise_lifetime)) LINGYAOInputSourceMonitor *sourceMonitor =
            [[LINGYAOInputSourceMonitor alloc] initWithCenter:NSDistributedNotificationCenter.defaultCenter
                bundleIdentifier:NSBundle.mainBundle.bundleIdentifier copySource:TISCopyCurrentKeyboardInputSource
                propertyGetter:[](TISInputSourceRef source, CFStringRef key) -> void * {
                    return (void *)TISGetInputSourceProperty(source, key);
                } switchedAway:^{
                    // Leaving this input method is the counterpart of TSF Deactivate, which clears the open/close, punctuation and width compartments together: every app, in either ime_mode_scope, starts from default_ime_mode and the saved punctuation and width when it comes back. The shared record of the shown mode is cleared too, so picking either mode entry on the way back is adopted as a choice. Focus changes between clients never get here.
                    LINGYAOAppearancePreferences *preferences = [LINGYAOAppearancePreferences sharedPreferences];
                    [preferences resetRememberedInputModes];
                    [preferences resetAllRuntimeInputState];
                    LINGYAOResetSystemInputModeState(LINGYAOSharedSystemInputModeState());
                    [[LINGYAOFloatingToolbarPanel sharedPanel] deactivateForInputSourceSwitch];
                }];
        Class bridge = NSClassFromString(@"LINGYAOBackendWindowBridge");
        id shared = [bridge respondsToSelector:@selector(shared)] ? [bridge performSelector:@selector(shared)] : nil;
        if ([shared respondsToSelector:@selector(startClipboardCaptureWithOptions:)]) {
            [shared performSelector:@selector(startClipboardCaptureWithOptions:) withObject:LINGYAOLoadRuntimeOptions() ?: @{}];
        }
        [NSApp run];
        if ([shared respondsToSelector:@selector(stopClipboardCapture)]) [shared performSelector:@selector(stopClipboardCapture)];
        [sourceMonitor stop];
        LINGYAOUsageReportingStop();
        (void)server;
    }
    return 0;
}
