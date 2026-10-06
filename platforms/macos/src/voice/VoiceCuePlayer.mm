#import "VoiceCuePlayer.h"
#import <AppKit/AppKit.h>
NSURL *LINGYAOVoiceCueResourceURL(NSBundle *bundle, BOOL start) {
    return [bundle URLForResource:start ? @"start" : @"end" withExtension:@"mp3" subdirectory:@"audios"];
}
static NSSound *LINGYAOVoiceCueSound(NSBundle *bundle, BOOL start, BOOL *bundled) {
    NSURL *url = LINGYAOVoiceCueResourceURL(bundle, start);
    NSSound *sound = url ? [[NSSound alloc] initWithContentsOfURL:url byReference:NO] : nil;
    *bundled = sound != nil;
    if (sound) return sound;
    // A bundle staged without the product cues (or with an undecodable file) still gives audible start/stop feedback rather than none.
    NSLog(@"LINGYAO voice %@ cue is missing from the bundle; using the system sound", start ? @"start" : @"end");
    return [[NSSound soundNamed:start ? @"Glass" : @"Pop"] copy];
}
// NSSound refuses to play a sound that is already playing; stopping first restarts it from the beginning, matching the Windows stop/seek-to-zero/start.
static void LINGYAOVoiceCueRestart(NSSound *sound) {
    [sound stop];
    [sound play];
}
// NSSound may never report the end (for instance when the output device goes away), so the completion also runs this long after the cue should have ended.
static const NSTimeInterval LINGYAOVoiceCueCompletionGrace = 0.5;
@interface LINGYAOVoiceCuePlayer () <NSSoundDelegate>
@end
@implementation LINGYAOVoiceCuePlayer {
    void (^_startCompletion)(void);
    NSUInteger _startPlayback;
}
- (instancetype)init { return [self initWithBundle:NSBundle.mainBundle]; }
- (instancetype)initWithBundle:(NSBundle *)bundle {
    self = [super init];
    if (self) {
        // Loaded once, as the Windows CuePlayer does in init, so a cue never waits on decoding at the moment recording starts.
        _startSound = LINGYAOVoiceCueSound(bundle, YES, &_startCueIsBundled);
        _stopSound = LINGYAOVoiceCueSound(bundle, NO, &_stopCueIsBundled);
        _startSound.delegate = self;
    }
    return self;
}
- (void)playStartCue { [self playStartCueThen:nil]; }
- (void)playStartCueThen:(void (^)(void))completion {
    // Clear before stopping: the interrupted playback must not release the new cue's completion.
    _startCompletion = nil;
    const NSUInteger playback = ++_startPlayback;
    [_startSound stop];
    _startCompletion = [completion copy];
    if (![_startSound play]) { [self finishStartPlayback:playback]; return; }
    if (!completion) return;
    __weak LINGYAOVoiceCuePlayer *weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((_startSound.duration + LINGYAOVoiceCueCompletionGrace) * NSEC_PER_SEC)),
        dispatch_get_main_queue(), ^{ [weakSelf finishStartPlayback:playback]; });
}
- (void)finishStartPlayback:(NSUInteger)playback {
    if (playback != _startPlayback || !_startCompletion) return;
    void (^completion)(void) = _startCompletion;
    _startCompletion = nil;
    completion();
}
- (void)sound:(NSSound *)sound didFinishPlaying:(BOOL)finished {
    // A stop issued by a restart reports NO and is not the end of the cue that replaced it.
    if (sound == _startSound && finished) [self finishStartPlayback:_startPlayback];
}
- (void)playStopCue { LINGYAOVoiceCueRestart(_stopSound); }
@end
