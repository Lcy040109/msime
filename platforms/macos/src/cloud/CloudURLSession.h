#pragma once

#import <Foundation/Foundation.h>

typedef void (^LINGYAOCloudDataCompletion)(NSData *data, NSURLResponse *response, NSError *error);

/// Starts a credential-bearing cloud request with a hard response-body bound.
FOUNDATION_EXPORT void LINGYAOStartCloudDataTask(NSURLRequest *request, NSUInteger maximumBytes,
                                                LINGYAOCloudDataCompletion completion);
