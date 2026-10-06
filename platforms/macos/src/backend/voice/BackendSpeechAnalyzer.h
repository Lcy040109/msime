#pragma once
#import <AVFoundation/AVFoundation.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// macOS 26's on-device SpeechAnalyzer for the `system` voice provider. The analyzer is Swift-only, so it lives in LINGYAOBackend.dylib (BackendSpeechAnalyzer.swift) and is reached by class name; a process without the dylib, a toolchain older than the macOS 26 SDK, or an older system all leave VoiceInputService on SFSpeechRecognizer.
@protocol LINGYAOBackendSpeechAnalyzerSession <NSObject>
// Capture callback thread. Converts to the analyzer's format and queues the audio.
- (void)appendBuffer:(AVAudioPCMBuffer *)buffer;
// Main thread. No more audio; the handler still gets the final text.
- (void)finishAudio;
// Main thread. Stops analysis; the handler is not called again.
- (void)cancel;
@end

@protocol LINGYAOBackendSpeechAnalyzerFactory <NSObject>
// A session for `locale` when its on-device model is installed, otherwise nil while the model is checked and installed in the background for a later session. The handler runs on main with the whole text so far; `final` ends the session, and an empty final is a failure, the same contract as the SFSpeech path.
+ (nullable id<LINGYAOBackendSpeechAnalyzerSession>)sessionWithLocale:(NSString *)locale textHandler:(void (^)(NSString *text, BOOL final))handler;
@end

static inline id<LINGYAOBackendSpeechAnalyzerSession> _Nullable LINGYAOStartBackendSpeechAnalyzer(NSString *locale, void (^handler)(NSString *text, BOOL final)) {
    Class type = NSClassFromString(@"LINGYAOBackendSpeechAnalyzer");
    if (![type respondsToSelector:@selector(sessionWithLocale:textHandler:)]) return nil;
    return [(Class<LINGYAOBackendSpeechAnalyzerFactory>)type sessionWithLocale:locale textHandler:handler];
}

NS_ASSUME_NONNULL_END
