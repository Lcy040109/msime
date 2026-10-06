#pragma once
#import <Foundation/Foundation.h>
typedef void (^LINGYAOCloudClipboardCompletion)(NSData *data, NSInteger status, NSError *error);
FOUNDATION_EXPORT void LINGYAOFetchCloudClipboard(NSString *search, NSString *token, LINGYAOCloudClipboardCompletion completion);
FOUNDATION_EXPORT void LINGYAOSetCloudClipboardEnabled(BOOL enabled, NSString *token, LINGYAOCloudClipboardCompletion completion);
FOUNDATION_EXPORT void LINGYAOAddCloudClipboard(NSString *text, NSString *token, LINGYAOCloudClipboardCompletion completion);
FOUNDATION_EXPORT void LINGYAORemoveCloudClipboard(NSString *itemID, NSString *token, LINGYAOCloudClipboardCompletion completion);
