#import "../../src/voice/VoiceWaveOverlay.h"
#include <cassert>
#include <algorithm>
#include <cmath>

@interface BriefFailureOverlay : LINGYAOVoiceWaveOverlay
@end
@implementation BriefFailureOverlay
- (NSTimeInterval)failureDisplayDuration { return 0.02; }
@end

int main(int argc, char **argv) {
    @autoreleasepool {
        [NSApplication sharedApplication];
        const NSRect syntheticFullScreen = NSMakeRect(-1440, 0, 1440, 900);
        const NSRect syntheticWorkArea = NSMakeRect(-1360, 40, 1360, 860);
        const NSPoint centered = LINGYAOVoiceWaveOverlayOriginForFrames(syntheticFullScreen, syntheticWorkArea, NSMakeSize(220, 44));
        assert(std::abs(centered.x - (-830.0)) < 0.01);
        assert(std::abs(centered.y - 50.0) < 0.01); // 10 points above the work area, as the source's rcWork.bottom - height - 10.
        // A left-side Dock narrows the work area but must not move the
        // horizontal center away from the physical monitor center.
        const NSPoint rightDock = LINGYAOVoiceWaveOverlayOriginForFrames(
            NSMakeRect(0, 0, 1440, 900), NSMakeRect(0, 0, 1360, 900), NSMakeSize(220, 44));
        assert(std::abs(rightDock.x - 610.0) < 0.01);
        const NSPoint oversized = LINGYAOVoiceWaveOverlayOriginForFrames(syntheticFullScreen, syntheticWorkArea, NSMakeSize(1800, 1000));
        assert(std::abs(oversized.x - NSMinX(syntheticFullScreen)) < 0.01);
        assert(std::abs(oversized.y - NSMinY(syntheticWorkArea)) < 0.01);
        // Layout precedence and sizes follow wave_overlay.cpp: actions, then the status label, then the transcript.
        assert(LINGYAOVoiceWaveOverlayLayoutFor(NO, NO, NO) == LINGYAOVoiceWaveOverlayLayoutCompact);
        assert(LINGYAOVoiceWaveOverlayLayoutFor(NO, NO, YES) == LINGYAOVoiceWaveOverlayLayoutTranscript);
        assert(LINGYAOVoiceWaveOverlayLayoutFor(NO, YES, YES) == LINGYAOVoiceWaveOverlayLayoutProcessing);
        assert(LINGYAOVoiceWaveOverlayLayoutFor(YES, YES, YES) == LINGYAOVoiceWaveOverlayLayoutAction);
        assert(LINGYAOVoiceWaveOverlayLayoutFor(YES, NO, NO) == LINGYAOVoiceWaveOverlayLayoutAction);
        assert(NSEqualSizes(LINGYAOVoiceWaveOverlaySizeForLayout(LINGYAOVoiceWaveOverlayLayoutCompact), NSMakeSize(78, 32)));
        assert(NSEqualSizes(LINGYAOVoiceWaveOverlaySizeForLayout(LINGYAOVoiceWaveOverlayLayoutProcessing), NSMakeSize(112, 40)));
        assert(NSEqualSizes(LINGYAOVoiceWaveOverlaySizeForLayout(LINGYAOVoiceWaveOverlayLayoutAction), NSMakeSize(142, 40)));
        assert(NSEqualSizes(LINGYAOVoiceWaveOverlaySizeForLayout(LINGYAOVoiceWaveOverlayLayoutTranscript), NSMakeSize(420, 112)));

        // Wave levels: silence keeps dots, speech raises every bar within 0...1 with the center bars taller, and the bars settle once listening stops.
        float levels[LINGYAOVoiceWaveBarCount] = {};
        for (int frame = 0; frame < 120; ++frame) LINGYAOVoiceWaveAdvanceLevels(levels, 0.0f, YES, 1000.0 + frame * 0.016);
        for (float level : levels) assert(level == 0.0f);
        float peak[LINGYAOVoiceWaveBarCount] = {};
        for (int frame = 0; frame < 240; ++frame) {
            LINGYAOVoiceWaveAdvanceLevels(levels, 1.0f, YES, 1000.0 + frame * 0.016);
            for (int i = 0; i < LINGYAOVoiceWaveBarCount; ++i) {
                assert(levels[i] >= 0.0f && levels[i] <= 1.0f);
                peak[i] = std::max(peak[i], levels[i]);
            }
        }
        for (float level : peak) assert(level > 0.06f);
        assert(peak[5] + peak[6] > peak[0] + peak[11]);
        float motion = 0.0f, previous = levels[3];
        for (int frame = 0; frame < 30; ++frame) {
            LINGYAOVoiceWaveAdvanceLevels(levels, 1.0f, YES, 2000.0 + frame * 0.016);
            motion += std::abs(levels[3] - previous); previous = levels[3];
        }
        assert(motion > 0.05f); // Multi-harmonic motion, not a static meter.
        LINGYAOVoiceWaveAdvanceLevels(levels, 5.0f, YES, 3000.0);
        for (float level : levels) assert(level <= 1.0f); // Out-of-range input is clamped.
        for (int frame = 0; frame < 120; ++frame) LINGYAOVoiceWaveAdvanceLevels(levels, 1.0f, NO, 3000.0 + frame * 0.016);
        for (float level : levels) assert(level < 0.06f); // Not listening: the bars return to dots.
        float first[LINGYAOVoiceWaveBarCount] = {}, second[LINGYAOVoiceWaveBarCount] = {};
        LINGYAOVoiceWaveAdvanceLevels(first, 0.7f, YES, 12.5); LINGYAOVoiceWaveAdvanceLevels(second, 0.7f, YES, 12.5);
        assert(std::equal(first, first + LINGYAOVoiceWaveBarCount, second));

        // Transcript: at most three lines, keeping the newest text behind a leading ellipsis.
        NSUInteger (^tenPerLine)(NSString *) = ^NSUInteger(NSString *candidate) { return (candidate.length + 9) / 10; };
        assert([LINGYAOVoiceTranscriptVisibleText(@"0123456789abcdefghij", 3, tenPerLine) isEqual:@"0123456789abcdefghij"]);
        NSString *thirtyFive = @"0123456789abcdefghijABCDEFGHIJvwxyz";
        NSString *cut = LINGYAOVoiceTranscriptVisibleText(thirtyFive, 3, tenPerLine);
        assert([cut isEqual:@"…6789abcdefghijABCDEFGHIJvwxyz"] && tenPerLine(cut) == 3);
        NSString *emoji = LINGYAOVoiceTranscriptVisibleText(@"🙂🙂🙂🙂🙂🙂", 1, tenPerLine); // Twelve UTF-16 units, surrogate pairs.
        assert([emoji isEqual:@"…🙂🙂🙂🙂"]);
        assert([LINGYAOVoiceTranscriptVisibleText(@"", 3, tenPerLine) isEqual:@""]);
        NSFont *transcriptFont = [NSFont systemFontOfSize:15];
        assert(LINGYAOVoiceTranscriptLineCount(@"合成", transcriptFont, 392) == 1);
        assert(LINGYAOVoiceTranscriptLineCount(@"合成\n预览\n文本\n", transcriptFont, 392) == 4);
        NSString *longSpeech = [@"" stringByPaddingToLength:600 withString:@"合成语音转写文本，最新的内容保留在末尾。" startingAtIndex:0];
        longSpeech = [longSpeech stringByAppendingString:@"最新一句"];
        NSString *shown = LINGYAOVoiceTranscriptVisibleText(longSpeech, 3, ^NSUInteger(NSString *candidate) { return LINGYAOVoiceTranscriptLineCount(candidate, transcriptFont, 392); });
        assert([shown hasPrefix:@"…"] && [shown hasSuffix:@"最新一句"] && LINGYAOVoiceTranscriptLineCount(shown, transcriptFont, 392) == 3);
        const NSUInteger kept = longSpeech.length - (shown.length - 1);
        assert(LINGYAOVoiceTranscriptLineCount([@"…" stringByAppendingString:[longSpeech substringFromIndex:kept - 1]], transcriptFont, 392) > 3); // As much of the newest text as fits.

        LINGYAOVoiceWaveOverlay *panel = [LINGYAOVoiceWaveOverlay new];
        assert(panel != nil);
        assert(panel.level == NSFloatingWindowLevel);
        assert(panel.ignoresMouseEvents);
        assert(!panel.isOpaque);
        assert(!panel.canBecomeKeyWindow);
        assert(!panel.canBecomeMainWindow);
        assert(panel.contentView != nil);
        assert(!panel.isVisible);
        panel.preferredScreen = NSScreen.mainScreen;
        assert(panel.preferredScreen == NSScreen.mainScreen);
        [panel applyThemePreferences:@{@"theme": @"light", @"voice_theme": @"dark"}];
        assert(!panel.isLightTheme && panel.appearance != nil);
        [panel applyThemePreferences:@{@"theme": @"dark", @"voice_theme": @"light"}];
        assert(panel.isLightTheme && panel.appearance != nil);
        [panel applyThemePreferences:@{@"theme": @"system", @"voice_theme": @"follow"}];
        assert(panel.appearance == nil);
        [panel applyThemePreferences:@{@"theme": @"dark", @"voice_theme": @"invalid"}];
        assert(!panel.isLightTheme && panel.appearance != nil);
        __block NSUInteger cancels = 0, confirms = 0;
        panel.actionHandler = ^(BOOL cancel) { if (cancel) ++cancels; else ++confirms; };
        [panel setListening:YES];
        NSButton *cancelButton = [panel valueForKey:@"cancelButton"];
        NSButton *confirmButton = [panel valueForKey:@"confirmButton"];
        // A plain hold shows only the compact wave: no actions until the recording is locked, as in the source.
        assert(cancelButton.hidden && confirmButton.hidden && panel.ignoresMouseEvents);
        assert(NSEqualSizes(panel.frame.size, NSMakeSize(78, 32)) && [panel valueForKey:@"waveTimer"] != nil);
        [cancelButton performClick:nil]; [confirmButton performClick:nil];
        assert(cancels == 0 && confirms == 0);
        [panel setRecordingLocked:YES];
        assert(!cancelButton.hidden && !confirmButton.hidden && !panel.ignoresMouseEvents);
        assert(NSEqualSizes(panel.frame.size, NSMakeSize(142, 40)));
        assert([cancelButton.accessibilityLabel isEqual:@"取消"] && [confirmButton.accessibilityLabel isEqual:@"确认"]);
        assert(std::abs(NSMidX(cancelButton.frame) - 18) < 0.01 && std::abs(NSMidX(confirmButton.frame) - 124) < 0.01);
        [cancelButton performClick:nil]; [confirmButton performClick:nil];
        assert(cancels == 1 && confirms == 1);
        assert(!panel.canBecomeKeyWindow && !panel.canBecomeMainWindow);
        [panel setProcessing:NO]; [panel dismissProcessing]; [panel setProcessing:YES];
        [panel setTranscript:@"synthetic dismissed preview"];
        assert(!panel.visible && !panel.transcriptText.length);
        [confirmButton performClick:nil]; assert(confirms == 1);
        [panel setListening:YES];
        assert(panel.visible && confirmButton.hidden); // A new recording starts unlocked.
        [panel setProcessing:NO];
        // Pending recognition keeps the actions, around the source's status label.
        assert(panel.visible && !confirmButton.hidden && [panel.statusText isEqual:@"识别中..."]);
        assert(NSEqualSizes(panel.frame.size, NSMakeSize(142, 40)) && [panel valueForKey:@"waveTimer"] == nil);
        [panel setRecordingLocked:YES]; // Not recording: ignored.
        [panel showFailure:LINGYAOVoiceFailureProvider];
        assert(cancelButton.hidden && confirmButton.hidden && !panel.actionHandler);
        [panel setListening:NO];
        assert(!panel.isVisible);
        // Synthetic levels exercise the main-queue update without microphone access.
        [panel setListening:YES];
        assert([panel.statusText isEqual:@"正在录音…"]);
        NSMutableString *preview = [@"合成预览文本，仅用于测试。\nEnglish preview · 日本語 · 🙂" mutableCopy];
        [panel setTranscript:preview];
        [preview appendString:@"changed outside the overlay"];
        assert(![panel.transcriptText containsString:@"changed outside"]);
        assert(NSEqualSizes(panel.frame.size, NSMakeSize(420, 112)));
        assert([[panel.contentView valueForKey:@"visibleTranscript"] isEqual:panel.transcriptText]);
        assert(panel.ignoresMouseEvents && !panel.canBecomeKeyWindow && !panel.canBecomeMainWindow);
        for (NSNumber *level in @[@0, @0.5, @1]) {
            [panel setInputLevel:level.floatValue];
        }
        // Wait for the queued updates rather than for a fixed 50 ms, which a loaded CI runner can spend before the main queue gets a turn.
        NSDate *until = [NSDate dateWithTimeIntervalSinceNow:2];
        while ([[panel.contentView valueForKey:@"level"] floatValue] != 1 && until.timeIntervalSinceNow > 0)
            [NSRunLoop.currentRunLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
        assert([[panel.contentView valueForKey:@"level"] floatValue] == 1);
        [panel setInputLevel:1]; // A queued meter update must not revive processing UI.
        [panel setProcessing:NO];
        assert(panel.visible && [panel.statusText isEqual:@"识别中..."]);
        // The status label replaces the transcript; without a handler there are no actions.
        assert(NSEqualSizes(panel.frame.size, NSMakeSize(112, 40)) && ![panel.contentView valueForKey:@"visibleTranscript"]);
        [NSRunLoop.currentRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.03]];
        assert([[panel.contentView valueForKey:@"level"] floatValue] == 0);
        [panel setProcessing:YES];
        assert(panel.visible && [panel.statusText isEqual:@"处理中..."]);
        assert([panel.transcriptText containsString:@"合成预览"]);
        assert([panel.contentView.accessibilityLabel isEqual:panel.statusText]);
        if (argc == 2) {
            panel.actionHandler = ^(BOOL) {};
            NSBitmapImageRep *bitmap = [panel.contentView bitmapImageRepForCachingDisplayInRect:panel.contentView.bounds];
            [panel.contentView cacheDisplayInRect:panel.contentView.bounds toBitmapImageRep:bitmap];
            assert([[bitmap representationUsingType:NSBitmapImageFileTypePNG properties:@{}] writeToFile:@(argv[1]) atomically:YES]);
            panel.actionHandler = nil;
        }
        assert(!panel.canBecomeKeyWindow && !panel.canBecomeMainWindow);
        [panel setListening:YES];
        NSString *longPreview = [[@"合成滚动文本\n" stringByPaddingToLength:5000 withString:@"合成滚动文本\n" startingAtIndex:0] stringByAppendingString:@"末尾"];
        [panel setTranscript:longPreview];
        NSString *visiblePreview = [panel.contentView valueForKey:@"visibleTranscript"];
        assert([panel.transcriptText isEqual:longPreview] && [visiblePreview hasPrefix:@"…"] && [visiblePreview hasSuffix:@"末尾"]);
        assert(LINGYAOVoiceTranscriptLineCount(visiblePreview, transcriptFont, 392) <= 3);
        [panel setTranscript:[@"x" stringByPaddingToLength:65537 withString:@"x" startingAtIndex:0]];
        assert([panel.transcriptText isEqual:longPreview]);
        [panel setListening:NO];
        assert(!panel.visible && !panel.statusText.length);
        assert(!panel.transcriptText.length && panel.ignoresMouseEvents && NSEqualSizes(panel.frame.size, NSMakeSize(78, 32)));
        assert([panel valueForKey:@"waveTimer"] == nil); // The animation stops with the panel.
        [panel setTranscript:@"late preview"];
        assert(!panel.visible && !panel.transcriptText.length);
        for (NSUInteger failure = LINGYAOVoiceFailureMicrophonePermission; failure <= LINGYAOVoiceFailureMissingLocalModel; ++failure) {
            [panel setListening:YES]; [panel setTranscript:@"synthetic discard on failure"];
            [panel showFailure:(LINGYAOVoiceFailure)failure];
            [panel setTranscript:@"late preview during failure"];
            assert(!panel.transcriptText.length);
            assert(panel.visible && panel.statusText.length);
            CGFloat textWidth = [panel.statusText sizeWithAttributes:@{NSFontAttributeName:[NSFont systemFontOfSize:14]}].width;
            assert(textWidth <= panel.contentView.bounds.size.width - 28 && panel.frame.size.height == 40);
            assert([panel.contentView.accessibilityLabel isEqual:panel.statusText]);
            [panel dismissFailure]; assert(!panel.visible);
        }
        [panel showFailure:LINGYAOVoiceFailureMissingToken];
        assert([panel.statusText isEqual:@"请先在设置的“语音输入”分区填写当前 ASR 提供商的 API Token。"]);
        [panel dismissFailure];
        [panel showFailure:LINGYAOVoiceFailureMissingLocalModel];
        assert([panel.statusText isEqual:@"请先在设置的“语音输入”分区下载或选择本地语音模型。"]);
        [panel dismissFailure];
        // The provider's own account of the failure takes the transcript area under the category's status line, and late previews still cannot replace it.
        [panel setListening:YES];
        [panel showFailure:LINGYAOVoiceFailureProvider detail:@"语音识别失败：synthetic provider message"];
        [panel setTranscript:@"late preview during failure"];
        assert(panel.visible && [panel.statusText isEqual:@"识别失败，请检查语音服务设置"]);
        assert([panel.transcriptText isEqual:@"语音识别失败：synthetic provider message"] && panel.frame.size.height == 112);
        [panel dismissFailure];
        assert(!panel.visible && !panel.transcriptText.length);
        [panel showFailure:LINGYAOVoiceFailureProvider detail:@""];
        assert(!panel.transcriptText.length && panel.frame.size.height == 40);
        [panel dismissFailure];
        BriefFailureOverlay *brief = [BriefFailureOverlay new];
        [brief showFailure:LINGYAOVoiceFailureCapture];
        [NSRunLoop.currentRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.25]];
        assert(!brief.visible);
        [brief showFailure:LINGYAOVoiceFailureProvider];
        [brief setListening:YES];
        [NSRunLoop.currentRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.05]];
        assert(brief.visible && [brief.statusText isEqual:@"正在录音…"]);
        [brief dismissFailure]; assert(brief.visible);
        [brief setListening:NO];
        [panel setListening:YES];
        assert([panel.statusText isEqual:@"正在录音…"]);
        [panel setListening:NO];
    }
    return 0;
}
