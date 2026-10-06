#pragma once

#import <AppKit/AppKit.h>

// The preferences window nests its controls in toolbar pages and cards, and the arrangement is
// presentation, not behaviour. Tests locate a control by what identifies it — its action or its
// accessibility label — so that regrouping the window does not rewrite every assertion.
//
// The search walks hidden pages too: only the selected page is visible at any time, and a test
// asserting on a control has no reason to care which page currently shows.

static inline NSView *LINGYAOFindPreferenceView(NSView *root, BOOL (^match)(NSView *view)) {
    for (NSView *view in root.subviews) {
        if (match(view)) return view;
        NSView *found = LINGYAOFindPreferenceView(view, match);
        if (found != nil) return found;
    }
    return nil;
}

static inline NSControl *LINGYAOFindPreferenceControl(NSView *root, SEL action) {
    return (NSControl *)LINGYAOFindPreferenceView(root, ^BOOL(NSView *view) {
        return [view isKindOfClass:NSControl.class] && ((NSControl *)view).action == action;
    });
}

/// Every control carrying the action, for settings a scheme pair shares (one per scheme).
static inline NSArray<NSControl *> *LINGYAOFindPreferenceControls(NSView *root, SEL action) {
    NSMutableArray<NSControl *> *found = [NSMutableArray array];
    for (NSView *view in root.subviews) {
        if ([view isKindOfClass:NSControl.class] && ((NSControl *)view).action == action)
            [found addObject:(NSControl *)view];
        [found addObjectsFromArray:LINGYAOFindPreferenceControls(view, action)];
    }
    return found;
}

static inline NSView *LINGYAOFindPreferenceViewOfClass(NSView *root, Class viewClass) {
    return LINGYAOFindPreferenceView(root, ^BOOL(NSView *view) { return [view isKindOfClass:viewClass]; });
}
