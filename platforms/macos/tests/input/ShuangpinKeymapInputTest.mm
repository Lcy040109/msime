#import "../../src/settings/ShuangpinKeymapPanel.h"
#include <cassert>

int main() {
    @autoreleasepool {
        [NSApplication sharedApplication];
        LINGYAOShuangpinKeymapPanel *panel = [LINGYAOShuangpinKeymapPanel new];
        panel.releasedWhenClosed = NO;
        [panel setProfileName:@"xiaohe"];
        for (NSString *preedit in @[@"hk", @"hao", @"hao ", @""]) {
            NSDictionary *view = @{@"editing_text": @"hk", @"preedit": preedit};
            assert([LINGYAOShuangpinKeymapEditingText(view) isEqual:@"hk"]);
            assert([LINGYAOShuangpinKeymapHighlightedKey(view) isEqual:@"k"]);
            [panel updateHighlightedKey:LINGYAOShuangpinKeymapHighlightedKey(view)];
            assert([panel.contentView.accessibilityValue containsString:@"当前按键 K"]);
        }
        [panel setProfileName:@"microsoft"];
        NSDictionary *semicolon = @{@"editing_text": @"b;", @"preedit": @"bing"};
        [panel updateHighlightedKey:LINGYAOShuangpinKeymapHighlightedKey(semicolon)];
        assert([panel.contentView.accessibilityValue containsString:@"当前按键 ;"]);
        assert([LINGYAOShuangpinKeymapHighlightedKey(@{@"editing_text": @"H"}) isEqual:@"H"]);
        for (id raw in @[@"", NSNull.null, @42, @[]]) {
            NSDictionary *view = @{@"editing_text": raw, @"preedit": @"hao"};
            assert(LINGYAOShuangpinKeymapEditingText(view).length == 0);
            assert(!LINGYAOShouldShowShuangpinKeymap(YES, YES, LINGYAOShuangpinKeymapEditingText(view).length > 0));
            assert(LINGYAOShuangpinKeymapHighlightedKey(view).length == 0);
        }
        assert(LINGYAOShuangpinKeymapEditingText(nil).length == 0);
        assert(LINGYAOShuangpinKeymapHighlightedKey(@{@"preedit": @"hao"}).length == 0);
        for (NSString *raw in @[@"hk1", @"hk'", @"hk ", @"🙂"]) {
            [panel updateHighlightedKey:LINGYAOShuangpinKeymapHighlightedKey(@{@"editing_text": raw})];
            assert(![panel.contentView.accessibilityValue containsString:@"当前按键"]);
        }
        // The highlighted key takes the theme accent the controller hands over, and keeps it across profile changes.
        assert(panel.accentColor != nil);
        NSColor *accent = [NSColor colorWithSRGBRed:0.36 green:0.61 blue:1.0 alpha:1.0];
        [panel setAccentColor:accent];
        assert([panel.accentColor isEqual:accent]);
        [panel setProfileName:@"ziranma"];
        assert([panel.accentColor isEqual:accent]);
        [panel close];
    }
}
