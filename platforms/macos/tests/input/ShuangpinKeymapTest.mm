#import "../../src/settings/ShuangpinKeymapPanel.h"
#include <cassert>
int main() {
    @autoreleasepool {
        [NSApplication sharedApplication];
        for (NSString *profile in @[@"xiaohe", @"ziranma", @"shoudao", @"microsoft"]) {
            NSArray *rows = LingyaoShuangpinKeymapRows(profile);
            assert(rows.count == 3);
            assert([rows[0] count] == 10);
            assert(LingyaoShuangpinZeroInitialText(profile).length > 8);
            LingyaoShuangpinKeymapPanel *panel = [LingyaoShuangpinKeymapPanel new];
            [panel setProfileName:profile];
            assert(panel.styleMask & NSWindowStyleMaskNonactivatingPanel);
            assert(panel.ignoresMouseEvents);
            NSString *before = panel.contentView.accessibilityValue;
            [panel updateHighlightedKey:@"q"];
            assert(![panel.contentView.accessibilityValue isEqual:before]);
            [panel updateHighlightedKey:@""];
            assert([panel.contentView.accessibilityValue isEqual:before]);
            [panel close];
        }
        assert([LingyaoShuangpinKeymapRows(@"invalid") isEqual:LingyaoShuangpinKeymapRows(@"xiaohe")]);
        assert(![LingyaoShuangpinKeymapRows(@"microsoft") isEqual:LingyaoShuangpinKeymapRows(@"xiaohe")]);
        NSRect screen = NSMakeRect(-1440, 0, 1440, 900);
        NSRect frame = LingyaoShuangpinKeymapPanelFrame(NSMakeRect(-10, 1, 1, 20), NSMakeSize(620, 203), 80, screen);
        assert(NSContainsRect(screen, frame));
        assert(LingyaoShouldShowShuangpinKeymap(YES, YES, YES));
        assert(!LingyaoShouldShowShuangpinKeymap(NO, YES, YES));
        assert(!LingyaoShouldShowShuangpinKeymap(YES, YES, NO));
    }
}
