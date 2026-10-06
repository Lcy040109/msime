#import "../../src/voice/VoiceTextCommit.h"
#include <cassert>

int main() {
    assert(LINGYAOVoiceCommitRoute::kEventChunkUnits == 16);
    @autoreleasepool {
        LINGYAOVoiceCommitRoute route;
        route.mode = @"sendinput"; route.pid = 12345;
        bool focused = true; route.current = [&] { return focused; };
        LINGYAOVoiceCommitIO io;
        io.permitted = [] { return true; };
        NSUInteger posts = 0, copies = 0;
        NSMutableString *reconstructed = [NSMutableString new];
        NSString *text = @"synthetic-123456😀汉字-text";
        io.post = [&](pid_t pid, CGEventRef event) {
            assert(pid == 12345);
            assert(CGEventGetIntegerValueField(event, kCGEventSourceUserData) == LINGYAOVoiceCommitEventTag);
            assert(CGEventGetFlags(event) == 0);
            if (CGEventGetType(event) == kCGEventKeyDown) {
                UniChar units[16]; UniCharCount count = 0;
                CGEventKeyboardGetUnicodeString(event, 16, &count, units);
                assert(count && count <= 16 && !CFStringIsSurrogateHighCharacter(units[count - 1]));
                [reconstructed appendString:[[NSString alloc] initWithCharacters:units length:count]];
            }
            ++posts;
        };
        io.clipboard = [&](NSString *value) { assert([value isEqual:text]); ++copies; return true; };
        assert(route.deliver(text, io) == LINGYAOVoiceCommitOutcome::posted);
        assert([reconstructed isEqual:text] && posts == 4 && !copies);
        io.permitted = [] { return false; };
        assert(route.deliver(text, io) == LINGYAOVoiceCommitOutcome::unavailable && posts == 4);
        focused = false;
        assert(route.deliver(text, io) == LINGYAOVoiceCommitOutcome::stale);
        focused = true; io.permitted = [] { return true; };
        route.mode = @"ctrl_v";
        io.post = [&](pid_t pid, CGEventRef event) {
            assert(pid == 12345 && CGEventGetIntegerValueField(event, kCGKeyboardEventKeycode) == 9);
            assert(CGEventGetFlags(event) == kCGEventFlagMaskCommand);
            assert(CGEventGetIntegerValueField(event, kCGEventSourceUserData) == LINGYAOVoiceCommitEventTag);
            ++posts;
        };
        assert(route.deliver(text, io) == LINGYAOVoiceCommitOutcome::posted && posts == 6 && copies == 1);
        io.clipboard = [](NSString *) { return false; };
        assert(route.deliver(text, io) == LINGYAOVoiceCommitOutcome::unavailable && posts == 6);
        io.clipboard = [&](NSString *) { focused = false; return true; };
        assert(route.deliver(text, io) == LINGYAOVoiceCommitOutcome::stale && posts == 6);
        focused = true;
        auto create = io.create;
        io.create = [](CGKeyCode, bool) -> CGEventRef { return nullptr; };
        assert(route.deliver(text, io) == LINGYAOVoiceCommitOutcome::unavailable && posts == 6);
        io.create = create; route.mode = @"sendinput";
        io.post = [&](pid_t, CGEventRef) { ++posts; focused = false; };
        assert(route.deliver(text, io) == LINGYAOVoiceCommitOutcome::posted && posts == 8);
        // Finish the first key pair, but do not duplicate a partially posted result via IMK.
        for (id value in @[@"tsf", @"unknown", @42, @[]]) assert([LINGYAOVoiceCommitMode(value) isEqual:@"tsf"]);
        assert([LINGYAOVoiceCommitMode(@"ctrl_v") isEqual:@"ctrl_v"]);
        assert([LINGYAOVoiceCommitMode(@"sendinput") isEqual:@"sendinput"]);
        assert(LINGYAOCaptureVoiceCommit(@"ctrl_v", [NSObject new]).deliver(text, io) == LINGYAOVoiceCommitOutcome::unavailable);
        assert(route.deliver(@"", io) == LINGYAOVoiceCommitOutcome::unavailable);
        assert(route.deliver([@"x" stringByPaddingToLength:65537 withString:@"x" startingAtIndex:0], io) == LINGYAOVoiceCommitOutcome::unavailable);
    }
}
