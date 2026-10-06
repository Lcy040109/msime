#pragma once

#import <Foundation/Foundation.h>
#import "../settings/RuntimeOptions.h"

// Keep the provider selection contract shared with the Tauri shell: an
// absolute socket in runtime-options.json wins, then the process environment
// is used as the compatibility fallback.  Invalid or missing paths are not
// advertised as a live provider, so native Speech remains the safe fallback.
static inline NSString *LINGYAOVoiceProviderSocketFromConfiguration(NSDictionary *options,
                                                                   NSDictionary *environment,
                                                                   NSFileManager *fileManager) {
    NSArray *values = @[
        ([options isKindOfClass:NSDictionary.class] ? options[@"voice_provider_socket"] : nil) ?: NSNull.null,
        ([environment isKindOfClass:NSDictionary.class] ? environment[@"LINGYAO_VOICE_PROVIDER_SOCKET"] : nil) ?: NSNull.null,
    ];
    for (id value in values) {
        if (![value isKindOfClass:NSString.class]) continue;
        NSString *path = [(NSString *)value stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
        if (!path.length || !path.isAbsolutePath || path.length >= 104 ||
            [path rangeOfCharacterFromSet:NSCharacterSet.controlCharacterSet].location != NSNotFound) continue;
        if ([fileManager fileExistsAtPath:path]) return path;
    }
    return nil;
}

static inline NSString *LINGYAOVoiceProviderSocketFromOptionsPath(NSString *optionsPath,
                                                                NSDictionary *environment,
                                                                NSFileManager *fileManager) {
    if (!optionsPath) optionsPath = LINGYAODefaultRuntimeOptionsPath(fileManager);
    NSData *data = LINGYAOReadRuntimeOptionsData(optionsPath);
    NSDictionary *options = data ? [NSJSONSerialization JSONObjectWithData:data options:0 error:nil] : nil;
    return LINGYAOVoiceProviderSocketFromConfiguration(options, environment, fileManager);
}

static inline NSString *LINGYAOVoiceProviderSocket(void) {
    NSString *optionsPath = NSProcessInfo.processInfo.environment[@"LINGYAO_CLIENT_HOST_OPTIONS"];
    if (![optionsPath isKindOfClass:NSString.class] || !optionsPath.isAbsolutePath)
        optionsPath = [[NSBundle.mainBundle pathForResource:@"runtime-options" ofType:@"json"] copy];
    return LINGYAOVoiceProviderSocketFromOptionsPath(optionsPath, NSProcessInfo.processInfo.environment,
                                                   NSFileManager.defaultManager);
}
