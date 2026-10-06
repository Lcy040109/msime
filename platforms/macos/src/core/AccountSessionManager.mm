#import "AccountSessionManager.h"
#import "AccountKeychain.h"
#import <Security/Security.h>
@implementation LINGYAOAccountSessionManager
+ (instancetype)sharedManager { static LINGYAOAccountSessionManager *m; static dispatch_once_t once; dispatch_once(&once, ^{ m=[self new]; }); return m; }
- (NSString *)accessTokenForAccountID:(NSString *)accountID { return LINGYAOKeychainToken(accountID, nil); }
- (NSString *)refreshTokenForAccountID:(NSString *)accountID { return LINGYAOKeychainRefreshToken(accountID, nil); }
- (BOOL)clearAccount:(NSString *)accountID error:(NSError **)error { if (!LINGYAORemoveKeychainToken(accountID, error)) return NO; NSDictionary *q=@{(__bridge id)kSecClass:(__bridge id)kSecClassGenericPassword,(__bridge id)kSecAttrService:LINGYAOKeychainRefreshService(),(__bridge id)kSecAttrAccount:accountID}; OSStatus s=SecItemDelete((__bridge CFDictionaryRef)q); if(s!=errSecSuccess&&s!=errSecItemNotFound){if(error)*error=[NSError errorWithDomain:@"LINGYAOAccount" code:s userInfo:nil];return NO;} return YES; }
@end
