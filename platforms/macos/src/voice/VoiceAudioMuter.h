#pragma once
#import <Foundation/Foundation.h>
#ifdef __cplusplus
#import <CoreAudio/CoreAudio.h>
struct LINGYAOVoiceAudioAPI {
    decltype(&AudioObjectGetPropertyData) get = AudioObjectGetPropertyData;
    decltype(&AudioObjectSetPropertyData) set = AudioObjectSetPropertyData;
    // Null listener functions disable following default output device changes.
    decltype(&AudioObjectAddPropertyListenerBlock) addListener = AudioObjectAddPropertyListenerBlock;
    decltype(&AudioObjectRemovePropertyListenerBlock) removeListener = AudioObjectRemovePropertyListenerBlock;
};
#endif
@interface LINGYAOVoiceAudioMuter : NSObject
// Main-thread lifecycle. Injection keeps tests away from real output devices.
#ifdef __cplusplus
- (instancetype)initWithAudioAPI:(LINGYAOVoiceAudioAPI)api;
// nil keeps injected tests entirely in memory. Production uses a private directory.
- (instancetype)initWithAudioAPI:(LINGYAOVoiceAudioAPI)api recoveryDirectory:(NSURL *)directory;
#endif
// Mutes the default output device and, until restore, follows the default to whichever device replaces it, handing each previous device back to its original state.
- (BOOL)mute:(NSError **)error;
// A one-shot mute to run later (after the start cue has played). It does nothing once restore has been called after it was created, so a cue that finishes after recording stopped cannot mute.
- (void (^)(void))deferredMute;
- (void)restore;
@end
