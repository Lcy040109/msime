#pragma once

#import <AppKit/AppKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol LingyaoUpdateDriver <NSObject>
@property(nonatomic, readonly) BOOL canCheckForUpdates;
@property(nonatomic, readonly) BOOL automaticallyChecksForUpdates;
- (void)checkForUpdates:(nullable id)sender;
@end

typedef void (^LingyaoUpdateActivationHandler)(void);

typedef NS_ENUM(NSInteger, LingyaoUpdateRoute) {
    LingyaoUpdateRouteUnavailable,
    LingyaoUpdateRouteSparkle,
    LingyaoUpdateRouteReleasePage,
};

// Whether Sparkle can be started in this process at all. It needs an application bundle - a feed URL, a
// version, a code signature - and started anywhere else it reports the misconfiguration with a modal
// alert, which in an input method means the user's typing stops behind a dialog they never asked for.
// A pure function so the decision can be tested without starting an updater.
static inline BOOL LINGYAOUpdateHostCanStartSparkle(NSString *_Nullable identifier, NSString *_Nullable path,
                                                  NSString *_Nullable feedURL)
{
    return identifier.length > 0 && [path.pathExtension isEqualToString:@"app"] && feedURL.length > 0;
}

// A shipped application with no Sparkle feed must still give an honest, actionable result when the
// shared settings bundle cannot be launched. Test binaries and command-line helpers have neither
// route: presenting AppKit update UI from them would steal focus for an action they did not initiate.
static inline LingyaoUpdateRoute LINGYAOUpdateRouteForHost(NSString *_Nullable identifier,
                                                             NSString *_Nullable path,
                                                             NSString *_Nullable feedURL)
{
    if (LINGYAOUpdateHostCanStartSparkle(identifier, path, feedURL)) return LingyaoUpdateRouteSparkle;
    if (identifier.length > 0 && [path.pathExtension isEqualToString:@"app"])
        return LingyaoUpdateRouteReleasePage;
    return LingyaoUpdateRouteUnavailable;
}

typedef NSModalResponse (^LingyaoUpdateReleaseConfirmation)(NSURL *releaseURL);
typedef BOOL (^LingyaoUpdateReleaseOpener)(NSURL *releaseURL);
typedef void (^LingyaoUpdateReleaseFailure)(void);

// Public only so the no-feed failure path can be tested without opening a browser or showing a real
// alert. Production constructs it with fixed UI blocks and a fixed official release URL.
@interface LingyaoReleasePageUpdateDriver : NSObject <LingyaoUpdateDriver>
- (instancetype)initWithReleaseURL:(NSURL *)releaseURL
                       confirmation:(LingyaoUpdateReleaseConfirmation)confirmation
                             opener:(LingyaoUpdateReleaseOpener)opener
                            failure:(LingyaoUpdateReleaseFailure)failure;
@end

@interface LingyaoUpdateController : NSObject
+ (instancetype)sharedController;
- (instancetype)initWithDriver:(id<LingyaoUpdateDriver>)driver
             activationHandler:(LingyaoUpdateActivationHandler)activationHandler;
@property(nonatomic, readonly) BOOL canCheckForUpdates;
@property(nonatomic, readonly) BOOL automaticallyChecksForUpdates;
- (void)checkForUpdates:(nullable id)sender;
@end
#define LINGYAOUpdateController LingyaoUpdateController

NS_ASSUME_NONNULL_END
