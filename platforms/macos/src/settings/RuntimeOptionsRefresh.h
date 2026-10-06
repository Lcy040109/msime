#pragma once

#import <Foundation/Foundation.h>

#include "lingyao_client.h"

#include <cstddef>
#include <cstdint>
#include <cstring>

typedef NS_ENUM(NSInteger, LINGYAORuntimeOptionsRefreshResult) {
    LINGYAORuntimeOptionsRefreshCurrent,
    LINGYAORuntimeOptionsRefreshUpdated,
    LINGYAORuntimeOptionsRefreshFailed,
};

// The Host API export, or a stand-in in tests; whatever it returns is released with lingyao_client_string_free.
typedef char *(*LINGYAORuntimeOptionsRefreshFunction)(const uint8_t *path, size_t length);

// Whether `path` names the bundle itself or anything inside it. The embedded development runtime-options.json lives in the signed, read-only bundle and is never rewritten.
static inline BOOL LINGYAOPathIsInsideBundle(NSString *path, NSString *bundlePath) {
    if (path.length == 0 || bundlePath.length == 0) return NO;
    NSString *candidate = path.stringByStandardizingPath.stringByResolvingSymlinksInPath;
    NSString *bundle = bundlePath.stringByStandardizingPath.stringByResolvingSymlinksInPath;
    return [candidate isEqualToString:bundle] || [candidate hasPrefix:[bundle stringByAppendingString:@"/"]];
}

// 把应用升级前写下的运行时配置带到已安装的词库代次：Host API 准备新代次、把用户词库日志回放进去，并原子改写 `resources` 与 `dictionaries`。不论代次是否变化，它还让 `language_dictionaries` 跟上资源目录旁实际安装的粤语、注音与笔画词库，所以只有输入法自己调用它：它认识自己写入的键，而设置应用升级后仍在运行的旧版输入法会拒绝这个键。已是当前代次、符号链接和不符合布局的文件由 Host API 原样保留并报告 Current；`bundlePath` 内的路径不调用 Host API，同样报告 Current。Failed 时 `resources` 与 `dictionaries` 保持原样，调用方继续用旧代次，下次启动再试；代次准备失败不影响 `language_dictionaries` 的更新。Host API 的错误不向外报告，因为其中可能有私人路径。
static inline LINGYAORuntimeOptionsRefreshResult LINGYAORefreshRuntimeOptionsWith(
    NSString *path, NSString *bundlePath, LINGYAORuntimeOptionsRefreshFunction refresh) {
    if (path.length == 0 || !path.isAbsolutePath) return LINGYAORuntimeOptionsRefreshFailed;
    if (LINGYAOPathIsInsideBundle(path, bundlePath)) return LINGYAORuntimeOptionsRefreshCurrent;
    const char *text = path.fileSystemRepresentation;
    char *raw = refresh(reinterpret_cast<const uint8_t *>(text), strlen(text));
    if (raw == nullptr) return LINGYAORuntimeOptionsRefreshFailed;
    NSData *data = [NSData dataWithBytes:raw length:strlen(raw)];
    lingyao_client_string_free(raw);
    id result = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    if (![result isKindOfClass:NSDictionary.class] || result[@"ok"] != (__bridge id)kCFBooleanTrue) return LINGYAORuntimeOptionsRefreshFailed;
    id value = result[@"value"];
    if (value == (__bridge id)kCFBooleanTrue) return LINGYAORuntimeOptionsRefreshUpdated;
    if (value == (__bridge id)kCFBooleanFalse) return LINGYAORuntimeOptionsRefreshCurrent;
    return LINGYAORuntimeOptionsRefreshFailed;
}

static inline LINGYAORuntimeOptionsRefreshResult LINGYAORefreshRuntimeOptions(NSString *path) {
    return LINGYAORefreshRuntimeOptionsWith(path, NSBundle.mainBundle.bundlePath, lingyao_client_refresh_host);
}
