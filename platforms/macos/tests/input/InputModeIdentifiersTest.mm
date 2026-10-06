#import "../../src/input/InputModeIdentifiers.h"

#include <cstdio>
#include <cstdlib>

// Stands in for the client: records every selectInputMode: and, like the system, can report the new mode back from inside the call.
@interface InputModeRecordingClient : NSObject
@property(nonatomic, strong) NSMutableArray<NSString *> *selected;
@property(nonatomic) LINGYAOSystemInputModeState *state;
@property(nonatomic) BOOL echoes;
@property(nonatomic) BOOL echoAdopted;
- (void)selectInputMode:(NSString *)identifier;
@end

@implementation InputModeRecordingClient
- (instancetype)init {
    if ((self = [super init])) _selected = [NSMutableArray array];
    return self;
}
- (void)selectInputMode:(NSString *)identifier {
    [self.selected addObject:identifier];
    if (self.echoes && self.state && LINGYAOAdoptReportedInputMode(*self.state, identifier)) self.echoAdopted = YES;
}
@end

namespace {
BOOL gEnglishModeEnabled = YES;
BOOL gJapaneseModeEnabled = YES;
BOOL gKoreanModeEnabled = YES;
BOOL gShuangpinModeEnabled = YES;
BOOL gWubiModeEnabled = YES;
BOOL Available(NSString *identifier) {
    if ([identifier isEqualToString:LINGYAOShuangpinInputModeID]) return gShuangpinModeEnabled;
    if ([identifier isEqualToString:LINGYAOWubiInputModeID]) return gWubiModeEnabled;
    if ([identifier isEqualToString:LINGYAOJapaneseInputModeID]) return gJapaneseModeEnabled;
    if ([identifier isEqualToString:LINGYAOKoreanInputModeID]) return gKoreanModeEnabled;
    return [identifier isEqualToString:LINGYAOChineseInputModeID] || gEnglishModeEnabled;
}

void require(bool condition, const char *message) {
    if (!condition) {
        std::fprintf(stderr, "%s\n", message);
        std::exit(1);
    }
}
} // namespace

int main() {
    @autoreleasepool {
        // 版本身份：没有 LINGYAOEdition 的 Info.plist（full 的，以及不是 bundle 的测试进程）每个值都是 full 今天的那个；声明了版本的取 plist 里的值。
        NSDictionary *wubi = @{@"LINGYAOEdition": @"wubi", @"CFBundleIdentifier": @"app.lingyao.inputmethod.wubi",
                               @"LINGYAOInputSchemes": @[@"wubi"], @"LINGYAODefaultScheme": @"wubi",
                               @"LINGYAOSettingsBundleIdentifier": @"app.lingyao.macos.wubi",
                               @"LINGYAOKeychainService": @"com.lingyao.ime.wubi.account", @"LINGYAOWubiMixedPinyinDefault": @YES};
        require([LINGYAOEditionIdentifierIn(@{}) isEqualToString:@"full"] && LINGYAOEditionIsFullIn(@{@"CFBundleIdentifier": @"x"}) &&
                    [LINGYAOInputMethodBundleIdentifierIn(@{@"CFBundleIdentifier": @"x"}) isEqualToString:@"app.lingyao.inputmethod.LingyaoIME"] &&
                    [LINGYAOSettingsBundleIdentifierIn(@{}) isEqualToString:@"app.lingyao.macos"] &&
                    [LINGYAOKeychainServiceIn(@{}) isEqualToString:@"com.lingyao.ime.account"] &&
                    LINGYAOEditionInputSchemesIn(@{}) == nil && [LINGYAOEditionDefaultSchemeIn(@{}) isEqualToString:@"quanpin"] &&
                    !LINGYAOEditionWubiMixedPinyinDefaultIn(@{@"LINGYAOWubiMixedPinyinDefault": @YES}) &&
                    [LINGYAOEditionNotificationNameIn(@{}, @"N") isEqualToString:@"N"],
                "An Info.plist without an edition did not read as full.");
        require([LINGYAOEditionIdentifierIn(wubi) isEqualToString:@"wubi"] &&
                    [LINGYAOInputMethodBundleIdentifierIn(wubi) isEqualToString:@"app.lingyao.inputmethod.wubi"] &&
                    [LINGYAOSettingsBundleIdentifierIn(wubi) isEqualToString:@"app.lingyao.macos.wubi"] &&
                    [LINGYAOKeychainServiceIn(wubi) isEqualToString:@"com.lingyao.ime.wubi.account"] &&
                    [LINGYAOEditionInputSchemesIn(wubi) isEqualToArray:@[@"wubi"]] && [LINGYAOEditionDefaultSchemeIn(wubi) isEqualToString:@"wubi"] &&
                    LINGYAOEditionWubiMixedPinyinDefaultIn(wubi) && [LINGYAOEditionNotificationNameIn(wubi, @"N") isEqualToString:@"N.wubi"],
                "The wubi edition's Info.plist did not give the wubi identity.");
        // 手写：full 和没写 LINGYAOHandwriting 的版本都有；不提供中文方案的版本写了 false 就没有，full 不认这个键。
        require(LINGYAOEditionOffersHandwritingIn(@{}) && LINGYAOEditionOffersHandwritingIn(wubi) &&
                    LINGYAOEditionOffersHandwritingIn(@{@"LINGYAOHandwriting": @NO}) &&
                    !LINGYAOEditionOffersHandwritingIn(@{@"LINGYAOEdition": @"vietnamese", @"LINGYAOHandwriting": @NO}) &&
                    LINGYAOEditionOffersHandwritingIn(@{@"LINGYAOEdition": @"pinyin", @"LINGYAOHandwriting": @YES}),
                "Handwriting did not follow the edition's LINGYAOHandwriting declaration.");
        // 语音服务凭据和使用统计目录：full 沿用今天的名字，其他版本各有各的，语音服务名正是卸载时删掉的 `<bundle id>.voice`。
        require([LINGYAOVoiceProviderKeychainServiceIn(@{}) isEqualToString:@"app.lingyao.client.voice.providers"] &&
                    [LINGYAOVoiceProviderKeychainServiceIn(wubi) isEqualToString:[wubi[@"CFBundleIdentifier"] stringByAppendingString:@".voice"]] &&
                    [LINGYAOUsageReportingDirectoryNameIn(@{}) isEqualToString:@"LINGYAO/telemetry"] &&
                    [LINGYAOUsageReportingDirectoryNameIn(wubi) isEqualToString:@"LINGYAO/wubi/telemetry"],
                "The voice provider keychain service or the usage reporting directory did not follow the edition.");
        // 卸载按 bundle 文件名找要移走的 bundle：五笔版只能是它自己的，名字缺了时宁可不卸载也不退回 full 的。
        NSMutableDictionary *named = [wubi mutableCopy];
        named[@"CFBundleExecutable"] = @"灵耀五笔";
        named[@"CFBundleDisplayName"] = @"灵耀五笔";
        require([LINGYAOInputMethodBundleNameIn(@{}) isEqualToString:@"灵耀输入法.app"] &&
                    [LINGYAOInputMethodBundleNameIn(named) isEqualToString:@"灵耀五笔.app"] &&
                    LINGYAOInputMethodBundleNameIn(wubi) == nil &&
                    [LINGYAOEditionDisplayNameIn(@{}) isEqualToString:@"灵耀输入法"] &&
                    [LINGYAOEditionDisplayNameIn(named) isEqualToString:@"灵耀五笔"],
                "The bundle file name or the display name did not follow the edition.");
        require(LINGYAOEditionIsFull() && LINGYAOEditionOffersScheme(@"tibetan") && !LINGYAOEditionOffersScheme(@"klingon") &&
                    [LINGYAOEffectiveInputScheme(@"cantonese", @"klingon", @{}) isEqualToString:@"quanpin"],
                "The test process, which is full, did not offer every scheme or fall back to quanpin.");
        require([LINGYAOInputModeID(LINGYAOInputModeFor(NO, @"quanpin")) isEqualToString:@"app.lingyao.inputmethod.LingyaoIME.Hans"] &&
                    [LINGYAOInputModeID(LINGYAOInputModeFor(YES, @"quanpin")) isEqualToString:@"app.lingyao.inputmethod.LingyaoIME.Roman"] &&
                    [LINGYAOInputModeID(LINGYAOInputModeFor(NO, @"japanese")) isEqualToString:@"app.lingyao.inputmethod.LingyaoIME.Japanese"] &&
                    [LINGYAOInputModeID(LINGYAOInputModeFor(NO, @"korean")) isEqualToString:@"app.lingyao.inputmethod.LingyaoIME.Korean"],
                "The Chinese, English, Japanese and Korean states do not map to the modes Info.plist.in declares.");
        require([LINGYAOInputModeID(LINGYAOInputModeFor(NO, @"shuangpin")) isEqualToString:@"app.lingyao.inputmethod.LingyaoIME.Shuangpin"] &&
                    [LINGYAOInputModeID(LINGYAOInputModeFor(NO, @"wubi")) isEqualToString:@"app.lingyao.inputmethod.LingyaoIME.Wubi"],
                "The shuangpin and wubi schemes do not map to the modes Info.plist.in declares.");
        // 五笔版只声明 .Hans 和 .Roman，五笔的名字和图标在 .Hans 上：设置窗口检查菜单栏入口时不能去找一个不存在的 .Wubi，否则提示永远消不掉。full 每个方案仍是它自己的模式。
        NSDictionary *wubiModes = @{@"LINGYAOEdition": @"wubi", @"ComponentInputModeDict": @{@"tsInputModeListKey": @{
            LINGYAOChineseInputModeID: @{}, LINGYAOEnglishInputModeID: @{}}}};
        require(LINGYAOInputModeDeclaredIn(@{}, LINGYAOTibetanInputModeID) && LINGYAOInputModeDeclaredIn(wubiModes, LINGYAOChineseInputModeID) &&
                    !LINGYAOInputModeDeclaredIn(wubiModes, LINGYAOWubiInputModeID) && !LINGYAOInputModeDeclaredIn(@{@"LINGYAOEdition": @"wubi"}, LINGYAOChineseInputModeID) &&
                    [LINGYAOInputModeIDForSchemeIn(wubiModes, @"wubi") isEqualToString:LINGYAOChineseInputModeID] &&
                    [LINGYAOInputModeIDForSchemeIn(@{}, @"wubi") isEqualToString:LINGYAOWubiInputModeID] &&
                    [LINGYAOInputModeIDForSchemeIn(@{}, @"shuangpin") isEqualToString:LINGYAOShuangpinInputModeID],
                "The settings window would look for a mode the edition does not declare.");
        require(LINGYAOInputModeFor(NO, @"quanpin") == LINGYAOInputMode::Chinese && LINGYAOInputModeFor(NO, nil) == LINGYAOInputMode::Chinese,
                "Quanpin or an unset scheme did not show 中.");
        require(LINGYAOInputModeFor(YES, @"japanese") == LINGYAOInputMode::English && LINGYAOInputModeFor(YES, @"korean") == LINGYAOInputMode::English &&
                    LINGYAOInputModeFor(YES, @"wubi") == LINGYAOInputMode::English,
                "English mode over another scheme did not show 英.");
        for (NSString *identifier in @[LINGYAOChineseInputModeID, LINGYAOShuangpinInputModeID, LINGYAOWubiInputModeID, LINGYAOEnglishInputModeID,
                                       LINGYAOJapaneseInputModeID, LINGYAOKoreanInputModeID])
            require([LINGYAOInputModeID(LINGYAOInputModeForID(identifier)) isEqualToString:identifier],
                    "A mode identifier does not map back to the mode it names.");
        require(LINGYAOInputModeForID(@"com.apple.keylayout.ABC") == LINGYAOInputMode::Chinese,
                "An unknown identifier did not read as the Chinese mode.");
        require([LINGYAOSchemeForInputMode(LINGYAOInputMode::Shuangpin) isEqualToString:@"shuangpin"] &&
                    [LINGYAOSchemeForInputMode(LINGYAOInputMode::Wubi) isEqualToString:@"wubi"] &&
                    [LINGYAOSchemeForInputMode(LINGYAOInputMode::Japanese) isEqualToString:@"japanese"] &&
                    [LINGYAOSchemeForInputMode(LINGYAOInputMode::Korean) isEqualToString:@"korean"] &&
                    LINGYAOSchemeForInputMode(LINGYAOInputMode::Chinese) == nil && LINGYAOSchemeForInputMode(LINGYAOInputMode::English) == nil,
                "A mode selects the wrong scheme.");
        require(LINGYAOIsInputModeID(LINGYAOChineseInputModeID) && LINGYAOIsInputModeID(LINGYAOEnglishInputModeID) &&
                    LINGYAOIsInputModeID(LINGYAOJapaneseInputModeID) && LINGYAOIsInputModeID(LINGYAOKoreanInputModeID) &&
                    LINGYAOIsInputModeID(LINGYAOShuangpinInputModeID) && LINGYAOIsInputModeID(LINGYAOWubiInputModeID) &&
                    !LINGYAOIsInputModeID(@"com.apple.keylayout.ABC") && !LINGYAOIsInputModeID(@"app.lingyao.inputmethod.LingyaoIME") &&
                    !LINGYAOIsInputModeID(@42) && !LINGYAOIsInputModeID(nil),
                "Something other than this bundle's six modes was taken for one of them.");

        // 双, 五, 日 and 한 name their scheme and 英 leaves it alone, whatever scheme is behind them.
        require([LINGYAOSchemeForReportedInputMode(LINGYAOInputMode::Wubi, @"japanese", @"quanpin", Available) isEqualToString:@"wubi"] &&
                    [LINGYAOSchemeForReportedInputMode(LINGYAOInputMode::Shuangpin, @"quanpin", nil, Available) isEqualToString:@"shuangpin"] &&
                    LINGYAOSchemeForReportedInputMode(LINGYAOInputMode::English, @"wubi", nil, Available) == nil,
                "A mode other than 中 did not select its own scheme.");
        // 中 keeps quanpin, and returns from 日 or 한 to the Chinese scheme they were entered from.
        require(LINGYAOSchemeForReportedInputMode(LINGYAOInputMode::Chinese, @"quanpin", nil, Available) == nil &&
                    [LINGYAOSchemeForReportedInputMode(LINGYAOInputMode::Chinese, @"korean", @"quanpin", Available) isEqualToString:@"quanpin"],
                "中 did not keep quanpin or return to it.");
        // With 双 and 五 offered, 中 was picked over them and means quanpin, even when 日 was entered from shuangpin.
        require([LINGYAOSchemeForReportedInputMode(LINGYAOInputMode::Chinese, @"shuangpin", nil, Available) isEqualToString:@"quanpin"] &&
                    [LINGYAOSchemeForReportedInputMode(LINGYAOInputMode::Chinese, @"wubi", nil, Available) isEqualToString:@"quanpin"] &&
                    [LINGYAOSchemeForReportedInputMode(LINGYAOInputMode::Chinese, @"japanese", @"shuangpin", Available) isEqualToString:@"quanpin"],
                "中 picked over an offered 双 or 五 did not move to quanpin.");
        // Without them, 中 is what shuangpin and wubi show, so picking it keeps the scheme or returns to it.
        gShuangpinModeEnabled = NO;
        gWubiModeEnabled = NO;
        require(LINGYAOSchemeForReportedInputMode(LINGYAOInputMode::Chinese, @"shuangpin", nil, Available) == nil &&
                    LINGYAOSchemeForReportedInputMode(LINGYAOInputMode::Chinese, @"wubi", nil, Available) == nil &&
                    [LINGYAOSchemeForReportedInputMode(LINGYAOInputMode::Chinese, @"japanese", @"shuangpin", Available) isEqualToString:@"shuangpin"],
                "中 standing in for a Shuangpin or Wubi mode the user removed moved the scheme.");
        gShuangpinModeEnabled = YES;
        gWubiModeEnabled = YES;

        LINGYAOSystemInputModeState state;
        InputModeRecordingClient *client = [InputModeRecordingClient new];
        client.state = &state;
        client.echoes = YES;

        // Activation with nothing recorded selects the stored state, and the system's synchronous echo is not a new choice.
        require(LINGYAOSelectSystemInputMode(state, LINGYAOChineseInputModeID, client, Available) && [client.selected isEqualToArray:@[LINGYAOChineseInputModeID]],
                "The first alignment did not select the Chinese mode.");
        require(!client.echoAdopted && !state.selecting, "The echo of the controller's own selection was adopted.");
        require(!LINGYAOSelectSystemInputMode(state, LINGYAOChineseInputModeID, client, Available) && client.selected.count == 1,
                "Aligning to the mode already shown asked the client again.");

        // A Shift toggle into English selects the English mode once.
        require(LINGYAOSelectSystemInputMode(state, LINGYAOEnglishInputModeID, client, Available) &&
                    [client.selected.lastObject isEqualToString:LINGYAOEnglishInputModeID] && client.selected.count == 2,
                "Toggling into English did not select the English mode.");
        require(!client.echoAdopted, "The echo of the toggle flipped the state back.");
        require(!LINGYAOAdoptReportedInputMode(state, LINGYAOEnglishInputModeID),
                "A later report that only repeats the shown mode was adopted as a change.");

        // The user picks the Chinese entry from the input menu: adopt it, and the resulting state sync does not call back.
        require(LINGYAOAdoptReportedInputMode(state, LINGYAOChineseInputModeID), "A mode picked from the input menu was not adopted.");
        require(!LINGYAOSelectSystemInputMode(state, LINGYAOChineseInputModeID, client, Available) && client.selected.count == 2,
                "Adopting a system-reported mode echoed it back through selectInputMode:.");

        // setValue:forTag: with the English mode turns English on without selecting it back.
        require(LINGYAOAdoptReportedInputMode(state, LINGYAOEnglishInputModeID) &&
                    LINGYAOInputModeForID(LINGYAOEnglishInputModeID) == LINGYAOInputMode::English,
                "Reporting the English mode did not turn English on.");
        require(!LINGYAOSelectSystemInputMode(state, LINGYAOEnglishInputModeID, client, Available) && client.selected.count == 2,
                "Turning English on from a report called selectInputMode: back.");

        // An unknown identifier is ignored and leaves the record alone.
        require(!LINGYAOAdoptReportedInputMode(state, @"com.apple.keylayout.ABC") && !LINGYAOAdoptReportedInputMode(state, nil) &&
                    [state.current isEqualToString:LINGYAOEnglishInputModeID],
                "An unknown mode identifier was adopted or overwrote the record.");

        // A report delivered while the controller is itself selecting is recorded but not adopted.
        state.selecting = true;
        require(!LINGYAOAdoptReportedInputMode(state, LINGYAOChineseInputModeID) && [state.current isEqualToString:LINGYAOChineseInputModeID],
                "A report from inside the controller's own switch was adopted.");
        state.selecting = false;

        // When the English mode is not enabled - removed in System Settings, or not yet registered - nothing is requested and the record keeps naming the mode actually shown.
        gEnglishModeEnabled = NO;
        require(!LINGYAOSelectSystemInputMode(state, LINGYAOEnglishInputModeID, client, Available) && client.selected.count == 2 &&
                    [state.current isEqualToString:LINGYAOChineseInputModeID],
                "An unavailable mode was requested or recorded as shown.");
        require(!LINGYAOAdoptReportedInputMode(state, LINGYAOChineseInputModeID),
                "With the English mode unavailable, a report of the Chinese mode flipped English off.");
        gEnglishModeEnabled = YES;

        // The japanese scheme selects 日 once, and a later pick of 日 from the menu after 中 is adopted.
        require(LINGYAOSelectSystemInputMode(state, LINGYAOJapaneseInputModeID, client, Available) &&
                    [client.selected.lastObject isEqualToString:LINGYAOJapaneseInputModeID] && client.selected.count == 3 &&
                    !client.echoAdopted,
                "Switching to the japanese scheme did not select the Japanese mode, or its echo was adopted.");
        require(LINGYAOAdoptReportedInputMode(state, LINGYAOChineseInputModeID) && LINGYAOAdoptReportedInputMode(state, LINGYAOJapaneseInputModeID),
                "Picking 中 and then 日 from the input menu was not adopted.");
        require(!LINGYAOSelectSystemInputMode(state, LINGYAOJapaneseInputModeID, client, Available) && client.selected.count == 3,
                "Adopting a reported Japanese mode echoed it back through selectInputMode:.");
        LINGYAOAdoptReportedInputMode(state, LINGYAOEnglishInputModeID);

        // An install that has not registered the Japanese mode shows 中 for the japanese scheme rather than leaving 英 up.
        gJapaneseModeEnabled = NO;
        require(LINGYAOSelectSystemInputMode(state, LINGYAOJapaneseInputModeID, client, Available) &&
                    [client.selected.lastObject isEqualToString:LINGYAOChineseInputModeID] && client.selected.count == 4 &&
                    [state.current isEqualToString:LINGYAOChineseInputModeID],
                "An unavailable Japanese mode did not fall back to the Chinese mode.");
        require(!LINGYAOSelectSystemInputMode(state, LINGYAOJapaneseInputModeID, client, Available) && client.selected.count == 4,
                "The Chinese fallback for an unavailable Japanese mode asked the client again.");
        require(LINGYAOAdoptReportedInputMode(state, LINGYAOJapaneseInputModeID) &&
                    !LINGYAOSelectSystemInputMode(state, LINGYAOJapaneseInputModeID, client, Available) && client.selected.count == 4,
                "A Japanese mode the system reported as shown was replaced by the Chinese fallback.");
        gJapaneseModeEnabled = YES;
        LINGYAOAdoptReportedInputMode(state, LINGYAOChineseInputModeID);

        // The korean scheme selects 한 once, and an install that has not registered the Korean mode shows 中 for it, as for Japanese.
        const NSUInteger beforeKorean = client.selected.count;
        require(LINGYAOSelectSystemInputMode(state, LINGYAOKoreanInputModeID, client, Available) &&
                    [client.selected.lastObject isEqualToString:LINGYAOKoreanInputModeID] && client.selected.count == beforeKorean + 1 &&
                    !client.echoAdopted,
                "Switching to the korean scheme did not select the Korean mode, or its echo was adopted.");
        require(!LINGYAOSelectSystemInputMode(state, LINGYAOKoreanInputModeID, client, Available) && client.selected.count == beforeKorean + 1,
                "Aligning to the Korean mode already shown asked the client again.");
        LINGYAOAdoptReportedInputMode(state, LINGYAOEnglishInputModeID);
        gKoreanModeEnabled = NO;
        require(LINGYAOSelectSystemInputMode(state, LINGYAOKoreanInputModeID, client, Available) &&
                    [client.selected.lastObject isEqualToString:LINGYAOChineseInputModeID] && client.selected.count == beforeKorean + 2 &&
                    [state.current isEqualToString:LINGYAOChineseInputModeID],
                "An unavailable Korean mode did not fall back to the Chinese mode.");
        require(LINGYAOAdoptReportedInputMode(state, LINGYAOKoreanInputModeID) &&
                    !LINGYAOSelectSystemInputMode(state, LINGYAOKoreanInputModeID, client, Available) && client.selected.count == beforeKorean + 2,
                "A Korean mode the system reported as shown was replaced by the Chinese fallback.");
        gKoreanModeEnabled = YES;
        LINGYAOAdoptReportedInputMode(state, LINGYAOChineseInputModeID);

        // A Shuangpin or Wubi mode the user removed shows 中 for its scheme, and one still enabled is selected.
        const NSUInteger beforeShuangpin = client.selected.count;
        gShuangpinModeEnabled = NO;
        require(!LINGYAOSelectSystemInputMode(state, LINGYAOShuangpinInputModeID, client, Available) && client.selected.count == beforeShuangpin &&
                    [state.current isEqualToString:LINGYAOChineseInputModeID],
                "An unavailable Shuangpin mode did not stay on the Chinese mode.");
        gShuangpinModeEnabled = YES;
        require(LINGYAOSelectSystemInputMode(state, LINGYAOShuangpinInputModeID, client, Available) &&
                    [client.selected.lastObject isEqualToString:LINGYAOShuangpinInputModeID] && client.selected.count == beforeShuangpin + 1,
                "An added Shuangpin mode was not selected for the shuangpin scheme.");
        gWubiModeEnabled = NO;
        require(LINGYAOSelectSystemInputMode(state, LINGYAOWubiInputModeID, client, Available) &&
                    [client.selected.lastObject isEqualToString:LINGYAOChineseInputModeID] && client.selected.count == beforeShuangpin + 2,
                "An unavailable Wubi mode did not fall back to the Chinese mode.");
        gWubiModeEnabled = YES;

        // Leaving the input method clears the record, so picking the entry shown before leaving is adopted on the way back instead of being taken for an echo.
        require(LINGYAOAdoptReportedInputMode(state, LINGYAOEnglishInputModeID) && !LINGYAOAdoptReportedInputMode(state, LINGYAOEnglishInputModeID),
                "The English report before leaving was not recorded.");
        LINGYAOResetSystemInputModeState(state);
        require(state.current == nil && !state.selecting, "Resetting left the record naming a mode.");
        require(LINGYAOAdoptReportedInputMode(state, LINGYAOEnglishInputModeID) && [state.current isEqualToString:LINGYAOEnglishInputModeID],
                "A report after leaving the input method was not adopted.");
        LINGYAOResetSystemInputModeState(LINGYAOSharedSystemInputModeState());
        require(LINGYAOSharedSystemInputModeState().current == nil, "The shared record did not reset.");
        LINGYAOAdoptReportedInputMode(state, LINGYAOChineseInputModeID);

        // 粤拼、注音、越南文、藏文和笔画各有自己的模式，每个模式都映射回自己的方案。
        for (NSString *scheme in @[@"cantonese", @"zhuyin", @"vietnamese", @"tibetan", @"stroke"]) {
            NSString *identifier = LINGYAOInputModeID(LINGYAOInputModeFor(NO, scheme));
            require(LINGYAOIsInputModeID(identifier) && LINGYAOIsOptInInputModeID(identifier) &&
                        [LINGYAOSchemeForInputMode(LINGYAOInputModeForID(identifier)) isEqualToString:scheme] &&
                        LINGYAOInputModeFor(YES, scheme) == LINGYAOInputMode::English,
                    "A Cantonese, Zhuyin, Vietnamese, Tibetan or Stroke scheme does not round-trip through its opt-in mode.");
        }
        require([LINGYAOInputModeID(LINGYAOInputMode::Cantonese) isEqualToString:@"app.lingyao.inputmethod.LingyaoIME.Cantonese"] &&
                    [LINGYAOInputModeID(LINGYAOInputMode::Zhuyin) isEqualToString:@"app.lingyao.inputmethod.LingyaoIME.Zhuyin"] &&
                    [LINGYAOInputModeID(LINGYAOInputMode::Vietnamese) isEqualToString:@"app.lingyao.inputmethod.LingyaoIME.Vietnamese"] &&
                    [LINGYAOInputModeID(LINGYAOInputMode::Tibetan) isEqualToString:@"app.lingyao.inputmethod.LingyaoIME.Tibetan"] &&
                    [LINGYAOInputModeID(LINGYAOInputMode::Stroke) isEqualToString:@"app.lingyao.inputmethod.LingyaoIME.Stroke"],
                "The new modes do not use the identifiers Info.plist.in declares.");
        require(!LINGYAOIsOptInInputModeID(LINGYAOChineseInputModeID) && !LINGYAOIsOptInInputModeID(LINGYAOKoreanInputModeID) && !LINGYAOIsOptInInputModeID(nil),
                "A mode every install enables was treated as opt-in.");
        require([LINGYAOInputSchemeNames() isEqualToArray:@[@"quanpin", @"shuangpin", @"wubi", @"japanese", @"korean", @"cantonese", @"zhuyin", @"vietnamese", @"tibetan", @"stroke"]],
                "The scheme names are not in the Engine's wire order.");
        // 菜单名和「添加」对话框里的语言与 InfoPlist.strings、Info.plist.in 和共享设置页的表一致。
        require([LINGYAOInputModeMenuName(LINGYAOTibetanInputModeID) isEqualToString:@"灵耀输入法 · 藏"] &&
                    [LINGYAOInputModeAddDialogLanguage(LINGYAOTibetanInputModeID) isEqualToString:@"藏语"],
                "The Tibetan mode is named or grouped differently from the plist and the settings page.");
        // 笔画在输入菜单里叫「灵耀输入法 · 笔」，在系统设置「添加」对话框的「简体中文」下。
        require([LINGYAOInputModeMenuName(LINGYAOStrokeInputModeID) isEqualToString:@"灵耀输入法 · 笔"] &&
                    [LINGYAOInputModeAddDialogLanguage(LINGYAOStrokeInputModeID) isEqualToString:@"简体中文"],
                "The Stroke mode's menu name or Add dialog language is wrong.");
        // 日文、越南文、藏文版的 中（.Hans）和 英 登记在本版本的语言下，设置窗口按 bundle 里的 TISIntendedLanguage 说去哪个语言下添加；五笔版的仍在「简体中文」下。
        for (NSArray<NSString *> *edition in @[@[@"japanese", @"ja", @"日语"], @[@"vietnamese", @"vi", @"越南语"], @[@"tibetan", @"bo", @"藏语"],
                                               @[@"wubi", @"zh-Hans", @"简体中文"]]) {
            NSDictionary *info = @{@"LINGYAOEdition": edition[0], @"ComponentInputModeDict": @{@"tsInputModeListKey": @{
                LINGYAOChineseInputModeID: @{@"TISIntendedLanguage": edition[1]}, LINGYAOEnglishInputModeID: @{@"TISIntendedLanguage": edition[1]}}}};
            require([LINGYAOInputModeAddDialogLanguageIn(info, LINGYAOChineseInputModeID) isEqualToString:edition[2]] &&
                        [LINGYAOInputModeAddDialogLanguageIn(info, LINGYAOEnglishInputModeID) isEqualToString:edition[2]],
                    "A single-language edition's modes are not looked for under its own language.");
        }
        require([LINGYAOInputModeAddDialogLanguageIn(@{}, LINGYAOEnglishInputModeID) isEqualToString:@"简体中文"] &&
                    [LINGYAOInputModeAddDialogLanguageIn(@{}, LINGYAOJapaneseInputModeID) isEqualToString:@"日语"],
                "full's Add dialog languages changed.");
        // 只有一个语言方案的版本：中（.Hans）就是这个方案的模式，方案自己的模式不存在。选中 中 留在这个方案上，不会去找一个本版本没有的中文方案。
        gJapaneseModeEnabled = NO;
        gEnglishModeEnabled = NO;
        for (NSString *scheme in @[@"japanese", @"vietnamese", @"tibetan"])
            require([LINGYAOSchemeForReportedInputMode(LINGYAOInputMode::Chinese, scheme, scheme, Available) isEqualToString:scheme],
                    "中 in a single-language edition left its only scheme.");
        gJapaneseModeEnabled = YES;
        gEnglishModeEnabled = YES;

        // 中 from Vietnamese goes back to the Chinese scheme it was entered from, like Japanese and Korean; 中 picked over 粤, 注 or 笔 means quanpin, like over 双 or 五.
        require([LINGYAOSchemeForReportedInputMode(LINGYAOInputMode::Chinese, @"vietnamese", @"wubi", Available) isEqualToString:@"quanpin"] &&
                    [LINGYAOSchemeForReportedInputMode(LINGYAOInputMode::Chinese, @"vietnamese", @"quanpin", Available) isEqualToString:@"quanpin"],
                "中 from Vietnamese did not leave it.");
        gWubiModeEnabled = NO;
        require([LINGYAOSchemeForReportedInputMode(LINGYAOInputMode::Chinese, @"vietnamese", @"wubi", Available) isEqualToString:@"wubi"],
                "中 from Vietnamese did not return to the Chinese scheme it was entered from.");
        gWubiModeEnabled = YES;
        require([LINGYAOSchemeForReportedInputMode(LINGYAOInputMode::Chinese, @"cantonese", @"quanpin", Available) isEqualToString:@"quanpin"] &&
                    [LINGYAOSchemeForReportedInputMode(LINGYAOInputMode::Chinese, @"zhuyin", @"quanpin", Available) isEqualToString:@"quanpin"] &&
                    [LINGYAOSchemeForReportedInputMode(LINGYAOInputMode::Chinese, @"stroke", @"quanpin", Available) isEqualToString:@"quanpin"],
                "中 picked over 粤, 注 or 笔 did not move to quanpin.");
        require([LINGYAOSchemeForReportedInputMode(LINGYAOInputMode::Stroke, @"quanpin", @"quanpin", Available) isEqualToString:@"stroke"],
                "The Stroke mode did not select its scheme.");
        require([LINGYAOSchemeForReportedInputMode(LINGYAOInputMode::Vietnamese, @"quanpin", @"quanpin", Available) isEqualToString:@"vietnamese"],
                "The Vietnamese mode did not select its scheme.");
        // 藏文和越南文一样不是中文方案：从藏文选 中 回到进入前的中文方案，选 藏 切到藏文。
        gWubiModeEnabled = NO;
        require([LINGYAOSchemeForReportedInputMode(LINGYAOInputMode::Chinese, @"tibetan", @"wubi", Available) isEqualToString:@"wubi"] &&
                    [LINGYAOSchemeForReportedInputMode(LINGYAOInputMode::Chinese, @"tibetan", @"quanpin", Available) isEqualToString:@"quanpin"],
                "中 from Tibetan did not return to the Chinese scheme it was entered from.");
        gWubiModeEnabled = YES;
        require([LINGYAOSchemeForReportedInputMode(LINGYAOInputMode::Tibetan, @"quanpin", @"quanpin", Available) isEqualToString:@"tibetan"],
                "The Tibetan mode did not select its scheme.");

        // Cantonese, Zhuyin and Stroke are available only with their dictionary in the HostOptions language_dictionaries directory; everything else needs nothing more.
        NSString *directory = [NSTemporaryDirectory() stringByAppendingPathComponent:NSUUID.UUID.UUIDString];
        [NSFileManager.defaultManager createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:nil];
        [NSData.data writeToFile:[directory stringByAppendingPathComponent:@"lingyao-cantonese.db"] atomically:YES];
        [NSFileManager.defaultManager createDirectoryAtPath:[directory stringByAppendingPathComponent:@"lingyao-zhuyin.db"] withIntermediateDirectories:YES attributes:nil error:nil];
        NSDictionary *hostOptions = @{@"language_dictionaries": directory};
        require(!LINGYAOInputSchemeAvailable(@"stroke", hostOptions) && [LINGYAOEffectiveInputScheme(@"stroke", @"wubi", hostOptions) isEqualToString:@"wubi"],
                "Stroke was available without lingyao-stroke.db.");
        [NSData.data writeToFile:[directory stringByAppendingPathComponent:@"lingyao-stroke.db"] atomically:YES];
        require(LINGYAOInputSchemeAvailable(@"stroke", hostOptions) && [LINGYAOEffectiveInputScheme(@"stroke", @"wubi", hostOptions) isEqualToString:@"stroke"] &&
                    [LINGYAOEffectiveInputScheme(@"japanese", @"stroke", hostOptions) isEqualToString:@"japanese"] &&
                    [LINGYAOEffectiveInputScheme(@"stroke", @"zhuyin", @{}) isEqualToString:@"quanpin"],
                "lingyao-stroke.db in language_dictionaries did not make Stroke available.");
        require(LINGYAOInputSchemeAvailable(@"cantonese", hostOptions) && !LINGYAOInputSchemeAvailable(@"zhuyin", hostOptions) &&
                    !LINGYAOInputSchemeAvailable(@"cantonese", @{}) && !LINGYAOInputSchemeAvailable(@"cantonese", nil) &&
                    LINGYAOInputSchemeAvailable(@"vietnamese", nil) && LINGYAOInputSchemeAvailable(@"tibetan", nil) && LINGYAOInputSchemeAvailable(@"korean", @{}) &&
                    !LINGYAOInputSchemeAvailable(@"pinyin", hostOptions) && !LINGYAOInputSchemeAvailable(nil, hostOptions),
                "Scheme availability does not follow the installed language dictionaries.");
        require([LINGYAOEffectiveInputScheme(@"cantonese", @"wubi", hostOptions) isEqualToString:@"cantonese"] &&
                    [LINGYAOEffectiveInputScheme(@"zhuyin", @"wubi", hostOptions) isEqualToString:@"wubi"] &&
                    [LINGYAOEffectiveInputScheme(@"zhuyin", @"cantonese", @{}) isEqualToString:@"quanpin"] &&
                    [LINGYAOEffectiveInputScheme(@"zhuyin", nil, @{}) isEqualToString:@"quanpin"],
                "An unavailable scheme did not fall back the way host-api does.");
        [NSFileManager.defaultManager removeItemAtPath:directory error:nil];

        // 设置应用按需下载的语言词典包（<preferences_directory>/resource-packs/language-dictionaries）同样让方案可用：只认带 lingyao-model.json 的真实目录里的普通文件，preferences_directory 必须是绝对路径。
        NSFileManager *files = NSFileManager.defaultManager;
        NSString *stateRoot = [NSTemporaryDirectory() stringByAppendingPathComponent:NSUUID.UUID.UUIDString];
        NSString *pack = [stateRoot stringByAppendingPathComponent:@"resource-packs/language-dictionaries"];
        [files createDirectoryAtPath:pack withIntermediateDirectories:YES attributes:nil error:nil];
        [NSData.data writeToFile:[pack stringByAppendingPathComponent:@"lingyao-cantonese.db"] atomically:YES];
        NSDictionary *packOptions = @{@"preferences_directory": stateRoot};
        require(!LINGYAOInputSchemeAvailable(@"cantonese", packOptions),
                "A language dictionary pack without lingyao-model.json made Cantonese available.");
        [@"{}" writeToFile:[pack stringByAppendingPathComponent:@"lingyao-model.json"] atomically:YES encoding:NSUTF8StringEncoding error:nil];
        require(LINGYAOInputSchemeAvailable(@"cantonese", packOptions) && !LINGYAOInputSchemeAvailable(@"zhuyin", packOptions) &&
                    !LINGYAOInputSchemeAvailable(@"stroke", packOptions),
                "A downloaded language dictionary pack did not make exactly Cantonese available.");
        [NSData.data writeToFile:[pack stringByAppendingPathComponent:@"lingyao-stroke.db"] atomically:YES];
        require(LINGYAOInputSchemeAvailable(@"stroke", packOptions) && [LINGYAOEffectiveInputScheme(@"stroke", @"wubi", packOptions) isEqualToString:@"stroke"],
                "lingyao-stroke.db in the downloaded pack did not make Stroke available.");
        require([LINGYAOEffectiveInputScheme(@"cantonese", @"wubi", packOptions) isEqualToString:@"cantonese"] &&
                    [LINGYAOEffectiveInputScheme(@"cantonese", @"wubi", @{@"preferences_directory": stateRoot, @"language_dictionaries": @""}) isEqualToString:@"cantonese"],
                "The effective scheme ignored Cantonese from the downloaded pack.");
        // 相对路径即使能从当前目录解析到这个资源包也不认。
        NSString *previousDirectory = files.currentDirectoryPath;
        [files changeCurrentDirectoryPath:[stateRoot stringByDeletingLastPathComponent]];
        BOOL relativeAccepted = LINGYAOInputSchemeAvailable(@"cantonese", @{@"preferences_directory": [stateRoot lastPathComponent]});
        [files changeCurrentDirectoryPath:previousDirectory];
        require(!relativeAccepted && !LINGYAOInputSchemeAvailable(@"cantonese", @{@"preferences_directory": @""}) &&
                    !LINGYAOInputSchemeAvailable(@"cantonese", @{@"preferences_directory": @42}),
                "A relative, empty or non-string preferences_directory was used to find a pack.");
        NSString *target = [stateRoot stringByAppendingPathComponent:@"cantonese-target.db"];
        [files moveItemAtPath:[pack stringByAppendingPathComponent:@"lingyao-cantonese.db"] toPath:target error:nil];
        [files createSymbolicLinkAtPath:[pack stringByAppendingPathComponent:@"lingyao-cantonese.db"] withDestinationPath:target error:nil];
        require(!LINGYAOInputSchemeAvailable(@"cantonese", packOptions),
                "A symlinked lingyao-cantonese.db in the downloaded pack made Cantonese available.");
        [files removeItemAtPath:stateRoot error:nil];

        // 资源包父目录是符号链接时也不能把外部词库当作已安装资源。
        NSString *linkedStateRoot = [NSTemporaryDirectory() stringByAppendingPathComponent:NSUUID.UUID.UUIDString];
        NSString *linkedOutside = [NSTemporaryDirectory() stringByAppendingPathComponent:NSUUID.UUID.UUIDString];
        NSString *linkedOutsidePack = [linkedOutside stringByAppendingPathComponent:@"resource-packs/language-dictionaries"];
        [files createDirectoryAtPath:linkedOutsidePack withIntermediateDirectories:YES attributes:nil error:nil];
        [NSData.data writeToFile:[linkedOutsidePack stringByAppendingPathComponent:@"lingyao-cantonese.db"] atomically:YES];
        [@"{}" writeToFile:[linkedOutsidePack stringByAppendingPathComponent:@"lingyao-model.json"] atomically:YES encoding:NSUTF8StringEncoding error:nil];
        [files createDirectoryAtPath:linkedStateRoot withIntermediateDirectories:YES attributes:nil error:nil];
        [files createSymbolicLinkAtPath:[linkedStateRoot stringByAppendingPathComponent:@"resource-packs"]
                    withDestinationPath:[linkedOutside stringByAppendingPathComponent:@"resource-packs"] error:nil];
        require(!LINGYAOInputSchemeAvailable(@"cantonese", @{ @"preferences_directory": linkedStateRoot }),
                "A symlinked resource-packs parent made Cantonese available.");
        [files removeItemAtPath:linkedStateRoot error:nil];
        [files removeItemAtPath:linkedOutside error:nil];

        // 方案切到粤、注、越、藏、笔时启用对应模式，第一次同步就落在这类方案上也启用；方案没变、方案跑不起来、或方案没有按需模式时都不启用。
        require([LINGYAOOptInInputModeToEnable(@"quanpin", @"cantonese", YES) isEqualToString:LINGYAOCantoneseInputModeID] &&
                    [LINGYAOOptInInputModeToEnable(@"korean", @"vietnamese", YES) isEqualToString:LINGYAOVietnameseInputModeID] &&
                    [LINGYAOOptInInputModeToEnable(@"vietnamese", @"tibetan", YES) isEqualToString:LINGYAOTibetanInputModeID] &&
                    [LINGYAOOptInInputModeToEnable(nil, @"zhuyin", YES) isEqualToString:LINGYAOZhuyinInputModeID] &&
                    [LINGYAOOptInInputModeToEnable(@"wubi", @"stroke", YES) isEqualToString:LINGYAOStrokeInputModeID] &&
                    !LINGYAOOptInInputModeToEnable(@"wubi", @"stroke", NO) && !LINGYAOOptInInputModeToEnable(@"stroke", @"stroke", YES) &&
                    !LINGYAOOptInInputModeToEnable(nil, @"quanpin", YES) && !LINGYAOOptInInputModeToEnable(@"zhuyin", @"zhuyin", YES) &&
                    !LINGYAOOptInInputModeToEnable(@"quanpin", @"zhuyin", NO) && !LINGYAOOptInInputModeToEnable(@"quanpin", @"wubi", YES),
                "An opt-in mode was enabled at the wrong time.");
        // 越南文、藏文版的 bundle 只声明 中（.Hans）和 英：方案自己的按需模式不存在，不去启用，第一次同步就能记下这个方案。
        for (NSString *scheme in @[@"vietnamese", @"tibetan"]) {
            NSDictionary *info = @{@"LINGYAOEdition": scheme, @"ComponentInputModeDict": @{@"tsInputModeListKey": @{
                LINGYAOChineseInputModeID: @{}, LINGYAOEnglishInputModeID: @{}}}};
            require(!LINGYAOOptInInputModeToEnableIn(info, nil, scheme, YES) && !LINGYAOOptInInputModeToEnableIn(info, @"quanpin", scheme, YES),
                    "A single-language edition asked for an opt-in mode its bundle does not declare.");
        }

        // A client that cannot switch modes is left alone.
        require(!LINGYAOSelectSystemInputMode(state, LINGYAOEnglishInputModeID, [NSObject new], Available) && [state.current isEqualToString:LINGYAOChineseInputModeID],
                "A client without selectInputMode: was recorded as switched.");
        require(!LINGYAOSelectSystemInputMode(state, LINGYAOEnglishInputModeID, nil, Available), "A missing client was asked to switch.");
    }
    std::puts("input mode identifiers keep the menu bar mode and the Chinese/English state and scheme in step");
    return 0;
}
