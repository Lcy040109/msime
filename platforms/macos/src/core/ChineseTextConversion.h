#pragma once
#import <Foundation/Foundation.h>
FOUNDATION_EXPORT NSString *LingyaoChineseOutputString(NSString *text, BOOL traditionalOutput);
#define MSIMEChineseOutputString LingyaoChineseOutputString
// The first or last Han character of text, or nil when it has none. Non-Han characters are skipped and a non-BMP character is returned whole. The Han ranges are the reference server's IsHanCodePoint (candidate_text_policy.h), which word-to-character ([ ]) applies to the phrase after output conversion.
FOUNDATION_EXPORT NSString *LingyaoEdgeHanCharacter(NSString *text, BOOL first);
#define MSIMEEdgeHanCharacter LingyaoEdgeHanCharacter
