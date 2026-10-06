#pragma once
#import <Foundation/Foundation.h>
typedef void (^LINGYAOCloudDictionaryCompletion)(NSData *data, NSInteger status, NSError *error);
FOUNDATION_EXPORT void LINGYAOFetchCloudDictionary(NSString *kind, NSString *search, NSUInteger offset, NSString *bearerToken, LINGYAOCloudDictionaryCompletion completion);
FOUNDATION_EXPORT void LINGYAOMutateCloudDictionary(NSString *method, NSString *kind, NSString *entryID, NSData *body, NSString *bearerToken, LINGYAOCloudDictionaryCompletion completion);
FOUNDATION_EXPORT NSString *LINGYAOReadDictionaryImportFile(NSURL *url, NSError **error);
FOUNDATION_EXPORT BOOL LINGYAOSaveDictionaryExportFile(NSData *data, NSURL *url, NSError **error);
FOUNDATION_EXPORT void LINGYAOImportCloudDictionary(NSString *kind, NSString *format, NSData *body, NSString *bearerToken, LINGYAOCloudDictionaryCompletion completion);
FOUNDATION_EXPORT void LINGYAOExportCloudDictionary(NSString *kind, NSString *format, NSString *bearerToken, LINGYAOCloudDictionaryCompletion completion);
FOUNDATION_EXPORT void LINGYAOFetchCloudDictionaryCatalog(NSString *kind, NSString *code, NSUInteger offset, NSString *scheme, NSString *profile, NSString *bearerToken, LINGYAOCloudDictionaryCompletion completion);
FOUNDATION_EXPORT void LINGYAOEditCloudDictionaryCatalog(NSString *kind, NSData *body, NSString *bearerToken, LINGYAOCloudDictionaryCompletion completion);
FOUNDATION_EXPORT void LINGYAOFetchCloudDictionaryChanges(long long after, NSUInteger limit, NSString *bearerToken, LINGYAOCloudDictionaryCompletion completion);
FOUNDATION_EXPORT void LINGYAOSendCloudCandidateRequest(NSString *path, NSData *body, NSString *bearerToken, LINGYAOCloudDictionaryCompletion completion);
FOUNDATION_EXPORT void LINGYAOListCloudFixedPositions(NSString *context, NSUInteger offset, NSString *bearerToken, LINGYAOCloudDictionaryCompletion completion);
FOUNDATION_EXPORT void LINGYAOMutateCloudFixedPosition(NSString *method, NSData *body, NSString *bearerToken, LINGYAOCloudDictionaryCompletion completion);
FOUNDATION_EXPORT void LINGYAOFetchCloudDictionarySnapshot(NSString *bearerToken, LINGYAOCloudDictionaryCompletion completion);
FOUNDATION_EXPORT void LINGYAORestoreCloudDictionarySnapshot(NSURL *file, long long revision, NSString *expectedSHA256, NSString *bearerToken, LINGYAOCloudDictionaryCompletion completion);
