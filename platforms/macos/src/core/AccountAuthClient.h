#pragma once
#import <Foundation/Foundation.h>
typedef void (^LINGYAOAuthCompletion)(NSData *data, NSInteger status, NSError *error);
FOUNDATION_EXPORT void LINGYAOAuthChallenge(NSString *linkToken, LINGYAOAuthCompletion completion);
FOUNDATION_EXPORT void LINGYAOAuthLogin(NSString *challenge, NSString *credential, NSString *linkToken, LINGYAOAuthCompletion completion);
FOUNDATION_EXPORT void LINGYAOAuthRefresh(NSString *refreshToken, LINGYAOAuthCompletion completion);
