#pragma once
#import <Foundation/Foundation.h>
#import "EditionIdentity.h"

// 钥匙串服务名随版本而变（full 是 com.lingyao.ime.account），同时安装的版本各自登录、各自退出，互不删对方的令牌。刷新令牌在它加 `.refresh` 的服务名下。
static inline NSString *LINGYAOKeychainRefreshService(void) { return [LINGYAOKeychainService() stringByAppendingString:@".refresh"]; }
FOUNDATION_EXPORT NSString *LINGYAOKeychainToken(NSString *accountID, NSError **error);
FOUNDATION_EXPORT BOOL LINGYAOStoreKeychainToken(NSString *accountID, NSString *token, NSError **error);
FOUNDATION_EXPORT BOOL LINGYAORemoveKeychainToken(NSString *accountID, NSError **error);
FOUNDATION_EXPORT NSString *LINGYAOKeychainRefreshToken(NSString *accountID, NSError **error);
FOUNDATION_EXPORT BOOL LINGYAOStoreKeychainRefreshToken(NSString *accountID, NSString *token, NSError **error);
