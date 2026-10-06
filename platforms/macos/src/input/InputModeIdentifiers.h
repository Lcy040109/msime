#pragma once
#import <Foundation/Foundation.h>
#include "../core/SystemPathAlias.h"

#include "../core/EditionIdentity.h"

// Info.plist.in 声明的十一个输入模式。每个模式的图标是铺满图块的一个大字：中、双、五、粤、注、日、한、越、ཀ、笔或英；选中的那条在输入菜单里打勾，并在输入源列表里列出名称。模式标识符是本版本输入法的 bundle id 加上模式后缀：full 是 `app.lingyao.inputmethod.LingyaoIME.Hans` 这些，info-plist-names 对照 plist 检查它们；其他版本只声明自己的方案对应的模式和「英」，见 scripts/edition_bundle.py。进程里 bundle id 不会变，所以每个后缀只拼一次。
static inline NSString *LINGYAOInputModeIdentifier(NSString *suffix) {
    static NSDictionary<NSString *, NSString *> *identifiers;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        NSString *bundle = LINGYAOInputMethodBundleIdentifier();
        NSMutableDictionary<NSString *, NSString *> *all = [NSMutableDictionary dictionary];
        for (NSString *mode in @[ @"Hans", @"Shuangpin", @"Wubi", @"Roman", @"Japanese", @"Korean", @"Cantonese", @"Zhuyin", @"Vietnamese", @"Tibetan", @"Stroke" ])
            all[mode] = [NSString stringWithFormat:@"%@.%@", bundle, mode];
        identifiers = all;
    });
    return identifiers[suffix];
}
#define LINGYAOChineseInputModeID LINGYAOInputModeIdentifier(@"Hans")
#define LINGYAOShuangpinInputModeID LINGYAOInputModeIdentifier(@"Shuangpin")
#define LINGYAOWubiInputModeID LINGYAOInputModeIdentifier(@"Wubi")
#define LINGYAOEnglishInputModeID LINGYAOInputModeIdentifier(@"Roman")
#define LINGYAOJapaneseInputModeID LINGYAOInputModeIdentifier(@"Japanese")
#define LINGYAOKoreanInputModeID LINGYAOInputModeIdentifier(@"Korean")
#define LINGYAOCantoneseInputModeID LINGYAOInputModeIdentifier(@"Cantonese")
#define LINGYAOZhuyinInputModeID LINGYAOInputModeIdentifier(@"Zhuyin")
#define LINGYAOVietnameseInputModeID LINGYAOInputModeIdentifier(@"Vietnamese")
#define LINGYAOTibetanInputModeID LINGYAOInputModeIdentifier(@"Tibetan")
#define LINGYAOStrokeInputModeID LINGYAOInputModeIdentifier(@"Stroke")

// 等用户选中对应方案才打开的模式。安装和更新都不启用它们：登记时跳过，LINGYAOEnableNewInputModes 只记录不启用，免得从没用过粤拼、注音、越南文、藏文或笔画的人输入菜单里平白多出五项。选中方案时请求启用对应模式（LINGYAOOptInInputModeToEnable），切走方案也不关掉它。macOS 27 不允许进程启用键盘输入模式，这个请求在那里不生效，只能由用户在系统设置里添加，设置页的「菜单栏入口」告诉用户去哪里加。
static inline NSArray<NSString *> *LINGYAOOptInInputModeIDs(void) {
    return @[ LINGYAOCantoneseInputModeID, LINGYAOZhuyinInputModeID, LINGYAOVietnameseInputModeID, LINGYAOTibetanInputModeID, LINGYAOStrokeInputModeID ];
}

static inline BOOL LINGYAOIsOptInInputModeID(NSString *identifier) {
    return identifier != nil && [LINGYAOOptInInputModeIDs() containsObject:identifier];
}

// 按引擎线上顺序（0-9）排列的全部方案名：下标就是视图在 `scheme` 里报告的数字。
static inline NSArray<NSString *> *LINGYAOInputSchemeNames(void) {
    return @[ @"quanpin", @"shuangpin", @"wubi", @"japanese", @"korean", @"cantonese", @"zhuyin", @"vietnamese", @"tibetan", @"stroke" ];
}

// 方案名是否是本版本提供的方案：引擎认识它，并且在本版本的方案列表里（full 不限制）。偏好里存着别的方案时按本版本的默认方案读。
static inline BOOL LINGYAOEditionOffersScheme(NSString *scheme) {
    NSArray<NSString *> *offered = LINGYAOEditionInputSchemes();
    return [LINGYAOInputSchemeNames() containsObject:scheme] && (!offered || [offered containsObject:scheme]);
}

// 路径上是否是指定类型的真实条目：attributesOfItemAtPath: 不跟随符号链接，符号链接本身的类型是 NSFileTypeSymbolicLink，因此会被拒绝，与 host-api 的 resource_packs::installed_file 一致。
static inline BOOL LINGYAOItemHasFileType(NSString *path, NSFileAttributeType type) {
    return [[NSFileManager.defaultManager attributesOfItemAtPath:path error:nil][NSFileType] isEqualToString:type];
}

// 资源包路径的每一层都必须是真实目录。`attributesOfItemAtPath:` 会跟随父目录的符号链接，所以这里交给 `StoragePathIsSafe` 逐层 `lstat`；只有目标核对过的 macOS `/var`、`/tmp` 系统别名可以经过，规则与 `crates/path-trust` 相同。
static inline BOOL LINGYAOPathAncestorsAreReal(NSString *path) {
    if (![path isKindOfClass:NSString.class] || !path.isAbsolutePath) return NO;
    return lingyao::mac::StoragePathIsSafe(path.stringByStandardizingPath.fileSystemRepresentation, true);
}

// 某个方案此处能否真正运行。粤拼、注音和笔画需要各自的词典（lingyao-cantonese.db、lingyao-zhuyin.db、lingyao-stroke.db）：按 host-api 的顺序，先找设置应用按需下载到 `<preferences_directory>/resource-packs/language-dictionaries/` 的副本（preferences_directory 须为绝对路径，资源包目录须是真实目录且带 lingyao-model.json，词典须是普通文件，符号链接一律不认），再找 HostOptions 的 `language_dictionaries` 目录；两处都没有时 host-api 会回退，此时提供该方案只会选中一个永远不生效的方案。其余方案（包括缺少日文词典时退化为纯假名的日文）不需要资源集之外的数据。输入法自身从不下载，下载只在设置应用里进行。
//
// 本版本不提供的方案在这里不存在：不出现在菜单和设置窗口里，偏好里写着它也会回退（LINGYAOEditionInputSchemes，full 不限制）。
static inline BOOL LINGYAOInputSchemeAvailable(NSString *scheme, NSDictionary *hostOptions) {
    NSArray<NSString *> *offered = LINGYAOEditionInputSchemes();
    if (offered && ![offered containsObject:scheme]) return NO;
    NSDictionary<NSString *, NSString *> *files = @{@"cantonese": @"lingyao-cantonese.db", @"zhuyin": @"lingyao-zhuyin.db", @"stroke": @"lingyao-stroke.db"};
    NSString *file = [scheme isKindOfClass:NSString.class] ? files[scheme] : nil;
    if (!file) return [LINGYAOInputSchemeNames() containsObject:scheme];
    id stateRoot = hostOptions[@"preferences_directory"];
    if ([stateRoot isKindOfClass:NSString.class] && [stateRoot length] && [stateRoot isAbsolutePath]) {
        NSString *pack = [[stateRoot stringByAppendingPathComponent:@"resource-packs"] stringByAppendingPathComponent:@"language-dictionaries"];
        if (LINGYAOPathAncestorsAreReal(pack) && LINGYAOItemHasFileType(pack, NSFileTypeDirectory) &&
            LINGYAOItemHasFileType([pack stringByAppendingPathComponent:@"lingyao-model.json"], NSFileTypeRegular) &&
            LINGYAOItemHasFileType([pack stringByAppendingPathComponent:file], NSFileTypeRegular))
            return YES;
    }
    id directory = hostOptions[@"language_dictionaries"];
    if (![directory isKindOfClass:NSString.class] || ![directory length]) return NO;
    BOOL isDirectory = NO;
    return [NSFileManager.defaultManager fileExistsAtPath:[directory stringByAppendingPathComponent:file] isDirectory:&isDirectory] && !isDirectory;
}

// 引擎按这些偏好实际运行的方案，与 host-api 的 effective_scheme 一致：此处跑不起来的方案让位给进入它之前的中文方案，再不行就是本版本的默认方案（full 是全拼）。输入菜单勾选的是它，菜单栏显示的也是它的模式，所以两处都不会声称一个用户并没有在用的方案。
static inline NSString *LINGYAOEffectiveInputScheme(NSString *scheme, NSString *lastChineseScheme, NSDictionary *hostOptions) {
    if (LINGYAOInputSchemeAvailable(scheme, hostOptions)) return scheme;
    return LINGYAOInputSchemeAvailable(lastChineseScheme, hostOptions) ? lastChineseScheme : LINGYAOEditionDefaultScheme();
}

// The mode the menu bar shows. English is the controller passing keys through; the others follow the scheme behind it.
enum class LINGYAOInputMode { Chinese, Shuangpin, Wubi, English, Japanese, Korean, Cantonese, Zhuyin, Vietnamese, Tibetan, Stroke };

// English mode wins over the scheme: 英 is shown whenever the controller passes keys through, whatever scheme is behind it. Otherwise each scheme with a mode of its own shows that mode, and quanpin shows 中. A mode the system does not offer falls back to 中 in LINGYAOSelectSystemInputMode.
static inline LINGYAOInputMode LINGYAOInputModeFor(BOOL english, NSString *scheme) {
    if (english) return LINGYAOInputMode::English;
    if ([scheme isEqualToString:@"shuangpin"]) return LINGYAOInputMode::Shuangpin;
    if ([scheme isEqualToString:@"wubi"]) return LINGYAOInputMode::Wubi;
    if ([scheme isEqualToString:@"japanese"]) return LINGYAOInputMode::Japanese;
    if ([scheme isEqualToString:@"korean"]) return LINGYAOInputMode::Korean;
    if ([scheme isEqualToString:@"cantonese"]) return LINGYAOInputMode::Cantonese;
    if ([scheme isEqualToString:@"zhuyin"]) return LINGYAOInputMode::Zhuyin;
    if ([scheme isEqualToString:@"vietnamese"]) return LINGYAOInputMode::Vietnamese;
    if ([scheme isEqualToString:@"tibetan"]) return LINGYAOInputMode::Tibetan;
    if ([scheme isEqualToString:@"stroke"]) return LINGYAOInputMode::Stroke;
    return LINGYAOInputMode::Chinese;
}

static inline NSString *LINGYAOInputModeID(LINGYAOInputMode mode) {
    switch (mode) {
    case LINGYAOInputMode::Shuangpin: return LINGYAOShuangpinInputModeID;
    case LINGYAOInputMode::Wubi: return LINGYAOWubiInputModeID;
    case LINGYAOInputMode::English: return LINGYAOEnglishInputModeID;
    case LINGYAOInputMode::Japanese: return LINGYAOJapaneseInputModeID;
    case LINGYAOInputMode::Korean: return LINGYAOKoreanInputModeID;
    case LINGYAOInputMode::Cantonese: return LINGYAOCantoneseInputModeID;
    case LINGYAOInputMode::Zhuyin: return LINGYAOZhuyinInputModeID;
    case LINGYAOInputMode::Vietnamese: return LINGYAOVietnameseInputModeID;
    case LINGYAOInputMode::Tibetan: return LINGYAOTibetanInputModeID;
    case LINGYAOInputMode::Stroke: return LINGYAOStrokeInputModeID;
    case LINGYAOInputMode::Chinese: break;
    }
    return LINGYAOChineseInputModeID;
}

// 本版本的 bundle 是否声明了这个模式。full 声明全部十一个；其他版本只声明 scripts/edition_bundle.py 的 mode_plan 给出的那几个，例如五笔版把五笔的名字和图标放在 .Hans 上，不声明 .Wubi。
static inline BOOL LINGYAOInputModeDeclaredIn(NSDictionary *info, NSString *identifier) {
    if (LINGYAOEditionIsFullIn(info)) return YES;
    id component = info[@"ComponentInputModeDict"];
    id modes = [component isKindOfClass:NSDictionary.class] ? component[@"tsInputModeListKey"] : nil;
    return identifier && [modes isKindOfClass:NSDictionary.class] && modes[identifier] != nil;
}

// 菜单栏里代表这个方案的模式：方案自己的模式，本版本没有声明它时是 中（.Hans），与 LINGYAOSelectSystemInputMode 的回退一致。设置窗口的「菜单栏入口」检查的就是它。
static inline NSString *LINGYAOInputModeIDForSchemeIn(NSDictionary *info, NSString *scheme) {
    NSString *mode = LINGYAOInputModeID(LINGYAOInputModeFor(NO, scheme));
    return LINGYAOInputModeDeclaredIn(info, mode) ? mode : LINGYAOChineseInputModeID;
}

// 一个模式在输入法菜单里的名字（与 InfoPlist.strings 一致），以及系统设置「添加」对话框把它归在哪个语言下（对应 Info.plist.in 的 TISIntendedLanguage）。macOS 27 不允许进程启用键盘输入模式，设置窗口靠这两项告诉用户去哪里自己添加；共享设置页 `macos-input-mode-entries-section.tsx` 里有同一张表。不是 full 的版本名字随版本而变，直接读 bundle 里 zh-Hans 的 InfoPlist.strings。
static inline NSString *LINGYAOInputModeMenuName(NSString *identifier) {
    if (!LINGYAOEditionIsFull()) {
        NSString *path = [NSBundle.mainBundle pathForResource:@"InfoPlist" ofType:@"strings" inDirectory:nil forLocalization:@"zh-Hans"];
        NSDictionary *names = path ? [NSDictionary dictionaryWithContentsOfFile:path] : nil;
        id name = identifier ? names[identifier] : nil;
        return [name isKindOfClass:NSString.class] ? name : nil;
    }
    NSDictionary<NSString *, NSString *> *names = @{
        LINGYAOChineseInputModeID: @"灵耀输入法 · 中", LINGYAOShuangpinInputModeID: @"灵耀输入法 · 双",
        LINGYAOWubiInputModeID: @"灵耀输入法 · 五", LINGYAOCantoneseInputModeID: @"灵耀输入法 · 粤",
        LINGYAOZhuyinInputModeID: @"灵耀输入法 · 注", LINGYAOJapaneseInputModeID: @"灵耀输入法 · 日",
        LINGYAOKoreanInputModeID: @"灵耀输入法 · 韩", LINGYAOVietnameseInputModeID: @"灵耀输入法 · 越",
        LINGYAOTibetanInputModeID: @"灵耀输入法 · 藏", LINGYAOStrokeInputModeID: @"灵耀输入法 · 笔",
        LINGYAOEnglishInputModeID: @"灵耀输入法 · 英",
    };
    return identifier ? names[identifier] : nil;
}
// 不是 full 的版本按 bundle 里这个模式的 TISIntendedLanguage 说语言：日文、越南文、藏文版的主模式和「英」登记在 ja、vi、bo 下（scripts/edition_bundle.py），模式标识符本身看不出来。
static inline NSString *LINGYAOInputModeAddDialogLanguageIn(NSDictionary *info, NSString *identifier) {
    if (!LINGYAOEditionIsFullIn(info)) {
        id component = info[@"ComponentInputModeDict"];
        id modes = [component isKindOfClass:NSDictionary.class] ? component[@"tsInputModeListKey"] : nil;
        id mode = identifier && [modes isKindOfClass:NSDictionary.class] ? modes[identifier] : nil;
        id language = [mode isKindOfClass:NSDictionary.class] ? mode[@"TISIntendedLanguage"] : nil;
        NSDictionary<NSString *, NSString *> *names = @{
            @"zh-Hans": @"简体中文", @"zh-Hant": @"繁体中文", @"yue-Hant": @"粤语", @"ja": @"日语",
            @"ko": @"韩语", @"vi": @"越南语", @"bo": @"藏语",
        };
        NSString *name = [language isKindOfClass:NSString.class] ? names[language] : nil;
        if (name) return name;
    }
    if ([identifier isEqualToString:LINGYAOCantoneseInputModeID]) return @"粤语";
    if ([identifier isEqualToString:LINGYAOZhuyinInputModeID]) return @"繁体中文";
    if ([identifier isEqualToString:LINGYAOJapaneseInputModeID]) return @"日语";
    if ([identifier isEqualToString:LINGYAOKoreanInputModeID]) return @"韩语";
    if ([identifier isEqualToString:LINGYAOVietnameseInputModeID]) return @"越南语";
    if ([identifier isEqualToString:LINGYAOTibetanInputModeID]) return @"藏语";
    return @"简体中文";
}
static inline NSString *LINGYAOInputModeAddDialogLanguage(NSString *identifier) { return LINGYAOInputModeAddDialogLanguageIn(LINGYAOEditionInfo(), identifier); }

static inline BOOL LINGYAOIsInputModeID(id value) {
    return [value isKindOfClass:NSString.class] &&
           ([value isEqualToString:LINGYAOChineseInputModeID] || [value isEqualToString:LINGYAOShuangpinInputModeID] ||
            [value isEqualToString:LINGYAOWubiInputModeID] || [value isEqualToString:LINGYAOEnglishInputModeID] ||
            [value isEqualToString:LINGYAOJapaneseInputModeID] || [value isEqualToString:LINGYAOKoreanInputModeID] ||
            [value isEqualToString:LINGYAOCantoneseInputModeID] || [value isEqualToString:LINGYAOZhuyinInputModeID] ||
            [value isEqualToString:LINGYAOVietnameseInputModeID] || [value isEqualToString:LINGYAOTibetanInputModeID] ||
            [value isEqualToString:LINGYAOStrokeInputModeID]);
}

// The mode an identifier names. Anything that is not one of this bundle's modes reads as Chinese; callers check LINGYAOIsInputModeID first when that matters.
static inline LINGYAOInputMode LINGYAOInputModeForID(NSString *identifier) {
    if ([identifier isEqualToString:LINGYAOShuangpinInputModeID]) return LINGYAOInputMode::Shuangpin;
    if ([identifier isEqualToString:LINGYAOWubiInputModeID]) return LINGYAOInputMode::Wubi;
    if ([identifier isEqualToString:LINGYAOEnglishInputModeID]) return LINGYAOInputMode::English;
    if ([identifier isEqualToString:LINGYAOJapaneseInputModeID]) return LINGYAOInputMode::Japanese;
    if ([identifier isEqualToString:LINGYAOKoreanInputModeID]) return LINGYAOInputMode::Korean;
    if ([identifier isEqualToString:LINGYAOCantoneseInputModeID]) return LINGYAOInputMode::Cantonese;
    if ([identifier isEqualToString:LINGYAOZhuyinInputModeID]) return LINGYAOInputMode::Zhuyin;
    if ([identifier isEqualToString:LINGYAOVietnameseInputModeID]) return LINGYAOInputMode::Vietnamese;
    if ([identifier isEqualToString:LINGYAOTibetanInputModeID]) return LINGYAOInputMode::Tibetan;
    if ([identifier isEqualToString:LINGYAOStrokeInputModeID]) return LINGYAOInputMode::Stroke;
    return LINGYAOInputMode::Chinese;
}

// The scheme a mode selects, or nil for English, which leaves the scheme alone. 中 has no scheme of its own: it goes back to the Chinese scheme the user left, which only the preferences know - see LINGYAOSchemeForReportedInputMode.
static inline NSString *LINGYAOSchemeForInputMode(LINGYAOInputMode mode) {
    switch (mode) {
    case LINGYAOInputMode::Shuangpin: return @"shuangpin";
    case LINGYAOInputMode::Wubi: return @"wubi";
    case LINGYAOInputMode::Japanese: return @"japanese";
    case LINGYAOInputMode::Korean: return @"korean";
    case LINGYAOInputMode::Cantonese: return @"cantonese";
    case LINGYAOInputMode::Zhuyin: return @"zhuyin";
    case LINGYAOInputMode::Vietnamese: return @"vietnamese";
    case LINGYAOInputMode::Tibetan: return @"tibetan";
    case LINGYAOInputMode::Stroke: return @"stroke";
    case LINGYAOInputMode::Chinese:
    case LINGYAOInputMode::English: break;
    }
    return nil;
}

// Keeps the system's selected input mode and the controller's Chinese/English state and scheme in step without either side echoing the other. The selected mode is global to the login session, so one state serves every controller instance.
//
// `current` is the mode last reported by the system or last requested by the controller; a report that repeats it is the system confirming what is already shown, not a user choice, so it does not flip the controller's state. `selecting` is set while the controller is asking the client to switch, so a report delivered synchronously from inside that call is not treated as a new choice either.
struct LINGYAOSystemInputModeState {
    NSString *current = nil;
    bool selecting = false;
};

// The system's selected input mode is global to the login session, so every controller instance shares one record of it. Leaving the input method clears it, so the first report after coming back is adopted even if it names the mode shown before leaving.
inline LINGYAOSystemInputModeState &LINGYAOSharedSystemInputModeState() {
    static LINGYAOSystemInputModeState state;
    return state;
}

static inline void LINGYAOResetSystemInputModeState(LINGYAOSystemInputModeState &state) { state = LINGYAOSystemInputModeState{}; }

// Records a mode the system reported through setValue:forTag:client:. Returns YES when the controller should adopt it: a known mode that differs from the one already shown and that the controller did not just request itself.
static inline BOOL LINGYAOAdoptReportedInputMode(LINGYAOSystemInputModeState &state, id value) {
    if (!LINGYAOIsInputModeID(value)) return NO;
    const BOOL changed = ![value isEqualToString:state.current];
    state.current = [value copy];
    return changed && !state.selecting;
}

// Whether the system offers a mode for selection. A mode the user removed in System Settings, or one an install from before the mode existed has not registered yet, cannot be selected, and asking for it would leave `current` naming a mode the menu bar does not show - the next report of the real one would then flip the controller's state back.
using LINGYAOInputModeAvailability = BOOL (*)(NSString *identifier);

// 用户选中某个模式后方案要切到哪里，返回 nil 表示不动方案。中 回到进入 japanese、korean、vietnamese 或 tibetan 之前的中文方案，或者保留已经在用的中文方案——除非那个方案有自己的、系统提供的模式：那说明用户是越过 双、五、粤、注 或 笔 选了 中，意思是本版本的默认方案（full 是全拼），保留方案会立刻又选回那个模式。
static inline NSString *LINGYAOSchemeForReportedInputMode(LINGYAOInputMode mode, NSString *scheme, NSString *lastChineseScheme,
                                                        LINGYAOInputModeAvailability available) {
    if (mode != LINGYAOInputMode::Chinese) return LINGYAOSchemeForInputMode(mode);
    const BOOL returning = [@[@"japanese", @"korean", @"vietnamese", @"tibetan"] containsObject:scheme];
    NSString *chinese = returning ? lastChineseScheme : scheme;
    const LINGYAOInputMode own = LINGYAOInputModeFor(NO, chinese);
    if (own != LINGYAOInputMode::Chinese && available && available(LINGYAOInputModeID(own))) return LINGYAOEditionDefaultScheme();
    return returning ? lastChineseScheme : nil;
}

// Asks the client to show `mode`, unless it already does or the system does not offer it. Returns whether a switch was requested. A scheme whose own mode is not offered falls back to 中: the controller is still composing through the Engine, and 中 is closer to that than an 英 left over from before. A mode the system has just reported as shown is offered by definition, so it is kept rather than second-guessed.
static inline BOOL LINGYAOSelectSystemInputMode(LINGYAOSystemInputModeState &state, NSString *mode, id client,
                                              LINGYAOInputModeAvailability available) {
    if (!available) return NO;
    if (![mode isEqualToString:LINGYAOChineseInputModeID] && ![mode isEqualToString:LINGYAOEnglishInputModeID] &&
        ![mode isEqualToString:state.current] && !available(mode))
        mode = LINGYAOChineseInputModeID;
    if (state.selecting || [mode isEqualToString:state.current] || ![client respondsToSelector:@selector(selectInputMode:)] ||
        !available(mode))
        return NO;
    state.current = mode;
    state.selecting = true;
    [client performSelector:@selector(selectInputMode:) withObject:mode];
    state.selecting = false;
    return YES;
}

// 方案从 `previous` 变成 `scheme` 时要启用的按需模式，没有则返回 nil。只有切到带按需模式的方案才算：模式在用户选中方案时启用——在菜单、任一设置窗口或经由它的模式——而不是每次输入法启动在这个方案上就启用，用户可能已经把它从输入菜单移除了。`previous` 为 nil 是第一次同步，同样算一次切换：这时用户正用着这个方案，而第一次同步只会发生一次，不会把用户之后移除的模式再加回来。在这台机器上跑不起来的方案（LINGYAOInputSchemeAvailable）不启用任何模式，所以输入菜单不会提供一个会退回其它方案的模式。
//
// 本版本的 bundle 没有声明这个模式时同样返回 nil：越南文、藏文版只有 .Hans 和「英」，方案自己的模式不存在，请求启用它只会失败（fnfErr），这次切换就永远记不下来，之后每次同步都再按全部已安装输入源查一遍。
static inline NSString *LINGYAOOptInInputModeToEnableIn(NSDictionary *info, NSString *previous, NSString *scheme, BOOL available) {
    if ([previous isEqualToString:scheme] || !available) return nil;
    NSString *mode = LINGYAOInputModeID(LINGYAOInputModeFor(NO, scheme));
    return LINGYAOIsOptInInputModeID(mode) && LINGYAOInputModeDeclaredIn(info, mode) ? mode : nil;
}
static inline NSString *LINGYAOOptInInputModeToEnable(NSString *previous, NSString *scheme, BOOL available) {
    return LINGYAOOptInInputModeToEnableIn(LINGYAOEditionInfo(), previous, scheme, available);
}
