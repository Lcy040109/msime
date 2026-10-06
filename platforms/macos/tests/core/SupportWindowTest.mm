#import "../../src/core/SupportWindowController.h"

#include <cassert>

static NSView *FindView(NSView *view, NSString *identifier) {
    if ([view.accessibilityIdentifier isEqualToString:identifier]) return view;
    for (NSView *subview in view.subviews) {
        NSView *found = FindView(subview, identifier);
        if (found != nil) return found;
    }
    return nil;
}

int main() {
    @autoreleasepool {
        [NSApplication sharedApplication];
        LINGYAOSupportWindowController *controller = [LINGYAOSupportWindowController sharedController];
        assert(controller != nil && controller.window != nil);

        [controller showPage:LINGYAOSupportPageHelp];
        assert(controller.page == LINGYAOSupportPageHelp);
        assert([controller.window.title isEqualToString:@"灵耀输入法帮助"]);
        assert(FindView(controller.window.contentView, @"LINGYAOSupportPreferences") != nil);

        [controller showPage:LINGYAOSupportPageAbout];
        assert(controller.page == LINGYAOSupportPageAbout);
        assert([controller.window.title isEqualToString:@"关于灵耀输入法"]);
        assert(FindView(controller.window.contentView, @"LINGYAOSupportCheckForUpdates") != nil);
        assert(FindView(controller.window.contentView, @"LINGYAOSupportLicense") != nil);
        assert(FindView(controller.window.contentView, @"LINGYAOSupportPrivacy") != nil);

        [controller showPage:LINGYAOSupportPageFeedback];
        assert(controller.page == LINGYAOSupportPageFeedback);
        assert([controller.window.title isEqualToString:@"反馈与交流"]);
        assert(FindView(controller.window.contentView, @"LINGYAOSupportIssues") != nil);
        assert(FindView(controller.window.contentView, @"LINGYAOSupportQQ") != nil);
        assert(FindView(controller.window.contentView, @"LINGYAOSupportTelegram") != nil);
        [controller.window orderOut:nil];
    }
    return 0;
}
