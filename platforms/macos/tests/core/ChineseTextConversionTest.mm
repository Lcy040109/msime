#import "../../src/core/ChineseTextConversion.h"

#import <Foundation/Foundation.h>

#include <stdexcept>

namespace
{
void require(bool condition, const char *message)
{
    if (!condition)
    {
        throw std::runtime_error(message);
    }
}
} // namespace

int main()
{
    @autoreleasepool
    {
        NSString *simplified = @"开发软件，后台里面";
        require([[LingyaoChineseOutputString(simplified, YES) description] isEqualToString:@"開發軟件，後臺裏面"],
                "Traditional output did not convert the visible Chinese text.");
        require(LingyaoChineseOutputString(simplified, NO) == simplified,
                "Simplified output unnecessarily copied or transformed its text.");
        require([LingyaoChineseOutputString(@"LINGYAO 123 😀", YES) isEqualToString:@"LINGYAO 123 😀"],
                "Traditional output changed non-Chinese text.");
        require([LingyaoChineseOutputString(@"", YES) isEqualToString:@""],
                "Traditional output did not preserve an empty string.");
        NSString *convertedSimplifiedGan = LingyaoChineseOutputString(@"干", YES);
        NSString *convertedTraditionalGan = LingyaoChineseOutputString(@"乾", YES);
        require([convertedSimplifiedGan isEqualToString:@"幹"] && [convertedTraditionalGan isEqualToString:@"乾"],
                "The OpenCC s2t 干/乾 fixture changed: standalone 干 is 幹 and 乾 stays 乾.");
        NSDictionary<NSString *, NSString *> *phrases = @{
            @"头发" : @"頭髮",
            @"蓬松" : @"蓬鬆",
            @"余下" : @"餘下",
            @"答复" : @"答覆",
            @"凭借" : @"憑藉",
        };
        for (NSString *source in phrases)
        {
            require([LingyaoChineseOutputString(source, YES) isEqualToString:phrases[source]],
                    "Traditional output did not use the OpenCC s2t phrase tables.");
        }
        // Mirrors the reference server's test_candidate_text_policy.cpp: word-to-character takes the first or last Han character, skipping everything else.
        require([LingyaoEdgeHanCharacter(@"中文", YES) isEqualToString:@"中"] &&
                    [LingyaoEdgeHanCharacter(@"中文", NO) isEqualToString:@"文"],
                "Edge extraction did not take the first and last Han characters.");
        require([LingyaoEdgeHanCharacter(@"a1中b2文c", YES) isEqualToString:@"中"] &&
                    [LingyaoEdgeHanCharacter(@"a1中b2文c", NO) isEqualToString:@"文"],
                "Edge extraction did not skip non-Han characters.");
        require([LingyaoEdgeHanCharacter(@"\U00020000x", YES) isEqualToString:@"\U00020000"] &&
                    [LingyaoEdgeHanCharacter(@"x中\U00020000", NO) isEqualToString:@"\U00020000"],
                "Edge extraction split a non-BMP Han character.");
        require([LingyaoEdgeHanCharacter(@"〇", YES) isEqualToString:@"〇"] &&
                    [LingyaoEdgeHanCharacter(@"\U000323AF", NO) isEqualToString:@"\U000323AF"],
                "Edge extraction missed a Han range the reference counts.");
        require(LingyaoEdgeHanCharacter(@"abc 123 😀，", YES) == nil && LingyaoEdgeHanCharacter(@"", NO) == nil &&
                    LingyaoEdgeHanCharacter(nil, YES) == nil,
                "Edge extraction returned a character from text without Han.");
        require([LingyaoEdgeHanCharacter(LingyaoChineseOutputString(@"头发", YES), NO) isEqualToString:@"髮"] &&
                    [LingyaoEdgeHanCharacter(LingyaoChineseOutputString(@"皇后", YES), NO) isEqualToString:@"后"],
                "Edge extraction over the converted phrase lost the phrase-level character.");
    }
    return 0;
}
