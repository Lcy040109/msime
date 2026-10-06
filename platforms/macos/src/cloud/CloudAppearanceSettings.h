#pragma once
#import <Foundation/Foundation.h>
#include "../candidate/CandidateSkin.h"
#include "../candidate/CandidatePageSize.h"
#import "../core/EditionIdentity.h"

static inline BOOL LINGYAOCloudAppearanceIntegerInRange(id value, NSInteger minimum, NSInteger maximum) {
    if (![value isKindOfClass:NSNumber.class] ||
        CFGetTypeID((__bridge CFTypeRef)value) == CFBooleanGetTypeID()) return NO;
    if (CFNumberIsFloatType((__bridge CFNumberRef)value)) return NO;
    NSInteger integer = [value integerValue];
    return integer >= minimum && integer <= maximum;
}

// The whole range the shared preferences accept, not the three sizes this platform's window used to
// offer: a cloud snapshot written by any other host carries the size that host allowed, and rejecting
// it here would drop the user's appearance on the way in.
static inline BOOL LINGYAOCloudAppearanceCandidatePageSize(id value) {
    return LINGYAOCloudAppearanceIntegerInRange(value, (NSInteger)lingyao::mac::kMinimumCandidatePageSize,
                                              (NSInteger)lingyao::mac::kMaximumCandidatePageSize);
}

static inline NSArray<NSString *> *LINGYAOCloudHelpcodeSchemas() {
    return @[@"lantian", @"ziranma", @"shouyou2_0", @"shouyouplus", @"xiaohe", @"jiajia"];
}

static inline NSInteger LINGYAOCloudHelpcodeSchemaIndex(NSUserDefaults *defaults, NSString *scheme) {
    NSString *fallback = [scheme isEqual:@"shuangpin"] ? @"lantian" : @"ziranma";
    NSDictionary *all = [defaults dictionaryForKey:@"LINGYAOClientHelpcodeOptions"];
    NSDictionary *stored = [all isKindOfClass:NSDictionary.class] && [all[scheme] isKindOfClass:NSDictionary.class] ? all[scheme] : nil;
    NSString *schema = [stored[@"schema"] isKindOfClass:NSString.class] ? stored[@"schema"] : fallback;
    NSUInteger index = [LINGYAOCloudHelpcodeSchemas() indexOfObject:schema];
    return index == NSNotFound ? (NSInteger)[LINGYAOCloudHelpcodeSchemas() indexOfObject:fallback] : (NSInteger)index;
}

static inline NSArray<NSString *> *LINGYAOCloudLocalModeKeys() {
    return @[@"quick_phrase", @"date_time", @"unicode", @"emoji", @"kaomoji", @"super_jianpin", @"temporary_english", @"temporary_japanese"];
}

static inline BOOL LINGYAOCloudLocalInputModesEnabled(NSUserDefaults *defaults) {
    NSDictionary *stored = [defaults dictionaryForKey:@"LINGYAOClientLocalModes"];
    if (![stored isKindOfClass:NSDictionary.class]) return YES;
    for (NSString *key in LINGYAOCloudLocalModeKeys()) {
        id value = stored[key];
        if ([value isKindOfClass:NSNumber.class] && CFGetTypeID((__bridge CFTypeRef)value) == CFBooleanGetTypeID() && ![value boolValue]) return NO;
    }
    return YES;
}

// Cloud names follow LINGYAO-Apple develop 2b0250f4dd7012520392b310dfcc0288c3208a75.
// Defaults and storage keys follow the active client host, not the retained Apple host.
static inline NSDictionary *LINGYAOCloudBooleanPreferences() {
    return @{@"autocorrect": @[@"LINGYAOClientAutocorrect", @YES],
             @"helpcode": @[@"LINGYAOClientHelpcodeEnabled", @YES],
             @"chinese_punctuation": @[@"LINGYAOClientChinesePunctuation", @YES],
             @"smart_punctuation": @[@"LINGYAOClientSmartPunctuation", @NO],
             @"smart_punctuation_repeat": @[@"LINGYAOClientSmartPunctuationRepeatToChinese", @NO],
             @"english_input_mode": @[@"LINGYAOClientEnglishInputMode", @NO],
             @"input_mode_shortcut": @[@"LINGYAOClientInputModeShortcut", @YES],
             @"full_width_input": @[@"LINGYAOClientFullWidthInput", @NO],
             @"floating_toolbar": @[@"LINGYAOClientFloatingToolbarEnabled", @YES],
             @"traditional_chinese_output": @[@"LINGYAOClientTraditionalOutput", @NO],
             @"wubi_auto_commit_unique": @[@"LINGYAOClientWubiAutoCommitUnique", @NO],
             @"candidate_learning": @[@"LINGYAOClientCandidateLearning", @YES],
             @"shuangpin_keymap": @[@"LINGYAOClientShuangpinKeymap", @NO],
             @"shuangpin_preedit_uses_raw": @[@"LINGYAOClientShuangpinPreeditUsesRaw", @YES]};
}

// 版本与账号同步：几个版本同时登录同一个账号，云端只有一份 macOS 设置。规则与 client-core 的 `filter_uploaded_account_settings` / `filter_downloaded_account_settings` 相同——只有一个方案的版本既不上传也不应用 `input_scheme`；有几个方案的版本只认自己有的方案；只属于某个方案的字段，本版本没有那个方案时不上传也不应用，免得一个版本拿本机缺省值盖掉另一个版本在云端的选择。`offered` 是 LINGYAOEditionInputSchemes()，nil 表示 full，什么也不去掉。
static inline NSArray<NSString *> *LINGYAOCloudInputSchemes() { return @[@"quanpin", @"shuangpin", @"wubi"]; }

static inline NSDictionary<NSString *, NSString *> *LINGYAOCloudSchemeScopedKeys() {
    return @{@"platform.macos.quanpin_helpcode_schema": @"quanpin",
             @"platform.macos.shuangpin_helpcode_schema": @"shuangpin",
             @"platform.macos.shuangpin_keymap": @"shuangpin",
             @"platform.macos.shuangpin_preedit_uses_raw": @"shuangpin",
             @"platform.macos.wubi_auto_commit_unique": @"wubi"};
}

static inline BOOL LINGYAOCloudSyncsInputScheme(NSArray<NSString *> *offered) { return !offered || offered.count > 1; }

// 本版本的快照里不带的键。
static inline BOOL LINGYAOCloudKeyOmitted(NSString *key, NSArray<NSString *> *offered) {
    if (!offered) return NO;
    if ([key isEqualToString:@"platform.macos.input_scheme"]) return !LINGYAOCloudSyncsInputScheme(offered);
    NSString *scheme = LINGYAOCloudSchemeScopedKeys()[key];
    return scheme && ![offered containsObject:scheme];
}

// `input_scheme` 可以取的值：云端契约里本版本有的那几个方案的编号。
static inline NSArray<NSNumber *> *LINGYAOCloudInputSchemeValues(NSArray<NSString *> *offered) {
    NSMutableArray<NSNumber *> *values = [NSMutableArray array];
    NSArray<NSString *> *schemes = LINGYAOCloudInputSchemes();
    for (NSUInteger index = 0; index < schemes.count; ++index)
        if (!offered || [offered containsObject:schemes[index]]) [values addObject:@(index)];
    return values;
}

// 去掉本版本不带的键。full 原样返回。
static inline NSDictionary *LINGYAONarrowCloudAppearance(NSDictionary *values, NSArray<NSString *> *offered) {
    if (!offered) return values;
    NSMutableDictionary *narrowed = [values mutableCopy];
    for (NSString *key in values)
        if (LINGYAOCloudKeyOmitted(key, offered)) [narrowed removeObjectForKey:key];
    return narrowed;
}

// 别处来的快照（另一个版本导出的设置文件）收窄到本版本：去掉本版本不带的键；`input_scheme` 是本版本没有的方案时保留本机的选择 `local`。full 原样返回。
static inline NSDictionary *LINGYAOAdoptCloudAppearance(NSDictionary *values, NSDictionary *local, NSArray<NSString *> *offered) {
    if (!offered || ![values isKindOfClass:NSDictionary.class]) return values;
    NSMutableDictionary *adopted = [LINGYAONarrowCloudAppearance(values, offered) mutableCopy];
    id scheme = adopted[@"platform.macos.input_scheme"];
    if (scheme && ![LINGYAOCloudInputSchemeValues(offered) containsObject:scheme]) adopted[@"platform.macos.input_scheme"] = local[@"platform.macos.input_scheme"];
    return adopted;
}

// The global theme replaced the per-host candidate skin: `global_theme` is one of the catalog ids, and the custom theme's base and package travel beside it. The package is "" for none.
static inline BOOL LINGYAOCloudCustomCandidateSkin(id value) {
    if (![value isKindOfClass:NSString.class] || [value length] > 64) return NO;
    return [value length] == 0 || (lingyao::mac::IsSafeSkinId([value UTF8String]) && !lingyao::mac::IsGlobalThemeId([value UTF8String]));
}

static inline NSDictionary *LINGYAOCloudAppearanceSnapshot(NSUserDefaults *defaults) {
    id font = [defaults objectForKey:@"LINGYAOClientCandidateFontSize"];
    id page = [defaults objectForKey:@"LINGYAOClientCandidatePageSize"];
    NSString *theme = [defaults stringForKey:@"LINGYAOClientGlobalTheme"];
    NSString *base = [defaults stringForKey:@"LINGYAOClientCustomThemeBase"];
    NSString *package = [defaults stringForKey:@"LINGYAOClientCustomCandidateSkin"];
    NSMutableDictionary *snapshot = [@{@"platform.macos.global_theme": lingyao::mac::IsGlobalThemeId(theme.UTF8String ?: "") ? theme : @"system",
             @"platform.macos.custom_theme_base": lingyao::mac::IsThemeBaseId(base.UTF8String ?: "") ? base : @"system",
             @"platform.macos.custom_candidate_skin": LINGYAOCloudCustomCandidateSkin(package) ? package : @"",
             @"platform.macos.candidate_panel_style": @([defaults integerForKey:@"LINGYAOClientCandidatePanelStyle"] == 1 ? 1 : 0),
             @"platform.macos.candidate_font_size": LINGYAOCloudAppearanceIntegerInRange(font, 12, 32) ? font : @18,
             @"platform.macos.candidate_page_size": LINGYAOCloudAppearanceCandidatePageSize(page) ? page : @9} mutableCopy];
    NSInteger shortcut = [defaults integerForKey:@"LINGYAOClientCandidatePageShortcut"];
    snapshot[@"platform.macos.candidate_page_shortcut"] = @(shortcut == 1 || shortcut == 2 ? shortcut : 0);
    NSArray *schemes = @[@"quanpin", @"shuangpin", @"wubi"];
    NSUInteger scheme = [schemes indexOfObject:[defaults stringForKey:@"LINGYAOClientInputScheme"] ?: @""];
    snapshot[@"platform.macos.input_scheme"] = @(scheme == NSNotFound ? 0 : scheme);
    snapshot[@"platform.macos.quanpin_helpcode_schema"] = @(LINGYAOCloudHelpcodeSchemaIndex(defaults, @"quanpin"));
    snapshot[@"platform.macos.shuangpin_helpcode_schema"] = @(LINGYAOCloudHelpcodeSchemaIndex(defaults, @"shuangpin"));
    snapshot[@"platform.macos.local_input_modes"] = @(LINGYAOCloudLocalInputModesEnabled(defaults));
    NSDictionary *booleans = LINGYAOCloudBooleanPreferences();
    for (NSString *key in booleans) {
        NSArray *field = booleans[key];
        snapshot[[@"platform.macos." stringByAppendingString:key]] =
            [defaults objectForKey:field[0]] == nil ? field[1] : @([defaults boolForKey:field[0]]);
    }
    return LINGYAONarrowCloudAppearance(snapshot, LINGYAOEditionInputSchemes());
}

static inline BOOL LINGYAOValidateCloudAppearanceForSchemes(NSDictionary *values, NSArray<NSString *> *offered) {
    NSUInteger omitted = 0;
    for (NSString *key in [@[@"platform.macos.input_scheme"] arrayByAddingObjectsFromArray:LINGYAOCloudSchemeScopedKeys().allKeys])
        if (LINGYAOCloudKeyOmitted(key, offered)) {
            if (values[key]) return NO;
            ++omitted;
        }
    if (![values isKindOfClass:NSDictionary.class] || values.count != 11 + LINGYAOCloudBooleanPreferences().count - omitted) return NO;
    id theme = values[@"platform.macos.global_theme"];
    if (![theme isKindOfClass:NSString.class] || !lingyao::mac::IsGlobalThemeId([theme UTF8String])) return NO;
    id base = values[@"platform.macos.custom_theme_base"];
    if (![base isKindOfClass:NSString.class] || !lingyao::mac::IsThemeBaseId([base UTF8String])) return NO;
    if (!LINGYAOCloudCustomCandidateSkin(values[@"platform.macos.custom_candidate_skin"])) return NO;
    if (!LINGYAOCloudAppearanceIntegerInRange(values[@"platform.macos.candidate_font_size"], 12, 32) ||
        !LINGYAOCloudAppearanceCandidatePageSize(values[@"platform.macos.candidate_page_size"])) return NO;
    // 校验与导出、应用共用方案目录，新增方案时不会漏掉允许的编号。
    NSMutableArray<NSNumber *> *helpcodeValues = [NSMutableArray array];
    for (NSUInteger index = 0; index < LINGYAOCloudHelpcodeSchemas().count; ++index)
        [helpcodeValues addObject:@(index)];
    NSDictionary *options = @{@"platform.macos.quanpin_helpcode_schema": helpcodeValues,
                              @"platform.macos.shuangpin_helpcode_schema": helpcodeValues,
                              @"platform.macos.candidate_panel_style": @[@0,@1],
                              @"platform.macos.input_scheme": LINGYAOCloudInputSchemeValues(offered),
                              @"platform.macos.candidate_page_shortcut": @[@0,@1,@2]};
    for (NSString *key in options) {
        if (LINGYAOCloudKeyOmitted(key, offered)) continue;
        id value = values[key];
        if (![value isKindOfClass:NSNumber.class] || CFGetTypeID((__bridge CFTypeRef)value) == CFBooleanGetTypeID() ||
            ![options[key] containsObject:value]) return NO;
    }
    for (NSString *key in LINGYAOCloudBooleanPreferences()) {
        if (LINGYAOCloudKeyOmitted([@"platform.macos." stringByAppendingString:key], offered)) continue;
        id value = values[[@"platform.macos." stringByAppendingString:key]];
        if (![value isKindOfClass:NSNumber.class] || CFGetTypeID((__bridge CFTypeRef)value) != CFBooleanGetTypeID()) return NO;
    }
    id localModes = values[@"platform.macos.local_input_modes"];
    if (![localModes isKindOfClass:NSNumber.class] || CFGetTypeID((__bridge CFTypeRef)localModes) != CFBooleanGetTypeID()) return NO;
    return YES;
}

static inline BOOL LINGYAOValidateCloudAppearance(NSDictionary *values) {
    return LINGYAOValidateCloudAppearanceForSchemes(values, LINGYAOEditionInputSchemes());
}

static inline BOOL LINGYAOApplyCloudAppearanceForSchemes(NSDictionary *values, NSUserDefaults *defaults, NSArray<NSString *> *offered) {
    if (!LINGYAOValidateCloudAppearanceForSchemes(values, offered)) return NO;
    [defaults setObject:values[@"platform.macos.global_theme"] forKey:@"LINGYAOClientGlobalTheme"];
    [defaults setObject:values[@"platform.macos.custom_theme_base"] forKey:@"LINGYAOClientCustomThemeBase"];
    [defaults setObject:values[@"platform.macos.custom_candidate_skin"] forKey:@"LINGYAOClientCustomCandidateSkin"];
    [defaults setObject:values[@"platform.macos.candidate_panel_style"] forKey:@"LINGYAOClientCandidatePanelStyle"];
    [defaults setObject:values[@"platform.macos.candidate_font_size"] forKey:@"LINGYAOClientCandidateFontSize"];
    [defaults setObject:values[@"platform.macos.candidate_page_size"] forKey:@"LINGYAOClientCandidatePageSize"];
    [defaults setObject:values[@"platform.macos.candidate_page_shortcut"] forKey:@"LINGYAOClientCandidatePageShortcut"];
    if (values[@"platform.macos.input_scheme"])
        [defaults setObject:LINGYAOCloudInputSchemes()[[values[@"platform.macos.input_scheme"] unsignedIntegerValue]] forKey:@"LINGYAOClientInputScheme"];
    NSMutableDictionary *helpcode = [[defaults dictionaryForKey:@"LINGYAOClientHelpcodeOptions"] mutableCopy] ?: [NSMutableDictionary dictionary];
    for (NSString *scheme in @[@"quanpin", @"shuangpin"]) {
        NSMutableDictionary *options = [helpcode[scheme] isKindOfClass:NSDictionary.class] ? [helpcode[scheme] mutableCopy] : [NSMutableDictionary dictionary];
        NSString *key = [scheme isEqual:@"quanpin"] ? @"platform.macos.quanpin_helpcode_schema" : @"platform.macos.shuangpin_helpcode_schema";
        if (!values[key]) continue;
        options[@"schema"] = LINGYAOCloudHelpcodeSchemas()[[values[key] unsignedIntegerValue]];
        helpcode[scheme] = options;
    }
    [defaults setObject:helpcode forKey:@"LINGYAOClientHelpcodeOptions"];
    NSMutableDictionary *localModes = [[defaults dictionaryForKey:@"LINGYAOClientLocalModes"] mutableCopy] ?: [NSMutableDictionary dictionary];
    for (NSString *key in LINGYAOCloudLocalModeKeys()) localModes[key] = values[@"platform.macos.local_input_modes"];
    [defaults setObject:localModes forKey:@"LINGYAOClientLocalModes"];
    NSDictionary *booleans = LINGYAOCloudBooleanPreferences();
    for (NSString *key in booleans) {
        id value = values[[@"platform.macos." stringByAppendingString:key]];
        if (value) [defaults setObject:value forKey:booleans[key][0]];
    }
    return YES;
}

static inline BOOL LINGYAOApplyCloudAppearance(NSDictionary *values, NSUserDefaults *defaults) {
    return LINGYAOApplyCloudAppearanceForSchemes(values, defaults, LINGYAOEditionInputSchemes());
}
