#pragma once

#import <AppKit/AppKit.h>

// Windows candidate rendering uses a label font at 80% of the candidate font.
// Keep the scale in one place while letting AppKit retain the selected font's
// family and variation axes.
static const CGFloat LINGYAOCandidateNumberScale = 0.8;
static const CGFloat LINGYAOCandidateNumberGap = 1.5;
// The brand mark at the start of the top row, and the room between it and the reading.
static const CGFloat LINGYAOCandidateLogoSide = 16.0;
static const CGFloat LINGYAOCandidateLogoGap = 6.0;

static inline NSFont *LINGYAOCandidateNumberFont(NSFont *font)
{
    if (![font isKindOfClass:NSFont.class])
    {
        return [NSFont systemFontOfSize:14.4];
    }
    return [NSFont fontWithDescriptor:font.fontDescriptor size:font.pointSize * LINGYAOCandidateNumberScale] ?:
        [NSFont systemFontOfSize:font.pointSize * LINGYAOCandidateNumberScale];
}
