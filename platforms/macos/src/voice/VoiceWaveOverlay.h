#pragma once
#import <Cocoa/Cocoa.h>

/// Return a clamped origin that centers the overlay horizontally on the full screen and sits it 10 points above the bottom of the screen's visible work area, as LINGYAO-Windows `update_window_bounds` does. This is kept pure so the positioning contract can be tested without opening a real window.
FOUNDATION_EXPORT NSPoint LINGYAOVoiceWaveOverlayOriginForFrames(NSRect fullFrame, NSRect visibleFrame, NSSize panelSize);

/// The four presentations of LINGYAO-Windows `wave_overlay.cpp`, in its precedence order: the round actions win over a status label, which wins over the transcript.
typedef NS_ENUM(NSUInteger, LINGYAOVoiceWaveOverlayLayout) {
    LINGYAOVoiceWaveOverlayLayoutCompact = 0,
    LINGYAOVoiceWaveOverlayLayoutProcessing,
    LINGYAOVoiceWaveOverlayLayoutAction,
    LINGYAOVoiceWaveOverlayLayoutTranscript
};
FOUNDATION_EXPORT LINGYAOVoiceWaveOverlayLayout LINGYAOVoiceWaveOverlayLayoutFor(BOOL actionsVisible, BOOL hasStatusLabel, BOOL hasTranscript);
/// Sizes in points: compact 78x32, processing 112x40, action 142x40, transcript 420x112.
FOUNDATION_EXPORT NSSize LINGYAOVoiceWaveOverlaySizeForLayout(LINGYAOVoiceWaveOverlayLayout layout);

enum { LINGYAOVoiceWaveBarCount = 12 };
/// Advance the 12 bar levels by one 16 ms animation frame with the source's multi-harmonic motion. `seconds` is a monotonic clock; `inputLevel` is clamped to 0...1. Levels stay within 0...1 and settle back to 0 (dots) once `listening` is NO or the input is silent.
FOUNDATION_EXPORT void LINGYAOVoiceWaveAdvanceLevels(float levels[LINGYAOVoiceWaveBarCount], float inputLevel, BOOL listening, double seconds);

/// Keep the newest text that fits in `maxLines`: when the whole transcript does not fit, the oldest text is dropped behind a leading "…". `lineCount` measures a candidate string; the cut never splits a composed character sequence.
FOUNDATION_EXPORT NSString *LINGYAOVoiceTranscriptVisibleText(NSString *transcript, NSUInteger maxLines, NSUInteger (^lineCount)(NSString *candidate));
/// Number of wrapped lines `text` takes in `font` at `width` points.
FOUNDATION_EXPORT NSUInteger LINGYAOVoiceTranscriptLineCount(NSString *text, NSFont *font, CGFloat width);

typedef NS_ENUM(NSUInteger, LINGYAOVoiceFailure) {
    LINGYAOVoiceFailureMicrophonePermission = 1,
    LINGYAOVoiceFailureSpeechPermission,
    LINGYAOVoiceFailureCapture,
    LINGYAOVoiceFailureProvider,
    LINGYAOVoiceFailureNoSpeech,
    LINGYAOVoiceFailureTimeout,
    LINGYAOVoiceFailureSession,
    LINGYAOVoiceFailureMissingToken,
    LINGYAOVoiceFailureMissingLocalModel
};
@interface LINGYAOVoiceWaveOverlay : NSPanel
// Host presentation only; all calls are made on the main thread.
/// The round cancel and confirm buttons appear only while the recording is locked (`setRecordingLocked:`) or while recognition or polishing is pending, and only when a handler is set.
@property(nonatomic, copy) void (^actionHandler)(BOOL cancel);
/// The screen containing the active IMK caret.  A nil or detached screen
/// falls back to the current main screen; AppKit points already account for
/// that screen's scale factor.
@property(nonatomic, weak) NSScreen *preferredScreen;
- (void)applyThemePreferences:(NSDictionary *)preferences;
- (BOOL)isLightTheme;
- (void)dismissProcessing;
- (void)setListening:(BOOL)listening;
/// The hold shortcut was locked with Space: recording continues after release, so the actions are shown. Ignored unless recording; `setListening:` clears it.
- (void)setRecordingLocked:(BOOL)locked;
- (void)setProcessing:(BOOL)polishing;
- (void)showFailure:(LINGYAOVoiceFailure)failure;
/// `detail` is the provider's own account of the failure, as LINGYAO-Windows shows it: the status line keeps the category's fixed message and the detail takes the transcript area. Nil or empty shows the category alone.
- (void)showFailure:(LINGYAOVoiceFailure)failure detail:(NSString *)detail;
- (void)dismissFailure;
- (void)setInputLevel:(float)level;
- (void)setTranscript:(NSString *)text;
@property(nonatomic, readonly, copy) NSString *statusText;
@property(nonatomic, readonly, copy) NSString *transcriptText;
@end
