#import "../../src/cloud/CloudClipboardClient.h"
#include <cassert>
int main() {
    @autoreleasepool {
        for (id itemID in @[@"", @".", @"..", NSNull.null, @42]) {
            __block BOOL completed = NO;
            LINGYAORemoveCloudClipboard(itemID, @"synthetic-session", ^(NSData *data, NSInteger status, NSError *error) {
                assert(data == nil && status == 400 && error == nil);
                completed = YES;
            });
            assert(completed);
        }
        LINGYAORemoveCloudClipboard(nil, @"synthetic-session", nil);
        // Invalid input is a synchronous no-op when the caller does not need a result.
        LINGYAOFetchCloudClipboard([@"x" stringByPaddingToLength:1025 withString:@"x" startingAtIndex:0],
                                  @"synthetic-session", nil);
        LINGYAOAddCloudClipboard([@"x" stringByPaddingToLength:4001 withString:@"x" startingAtIndex:0],
                               @"synthetic-session", nil);
        __block BOOL fetchCompleted = NO;
        LINGYAOFetchCloudClipboard([@"x" stringByPaddingToLength:1025 withString:@"x" startingAtIndex:0],
                                  @"synthetic-session", ^(NSData *data, NSInteger status, NSError *error) {
            assert(data == nil && status == 400 && error == nil);
            fetchCompleted = YES;
        });
        assert(fetchCompleted);
        __block BOOL addCompleted = NO;
        LINGYAOAddCloudClipboard(@"", @"synthetic-session", ^(NSData *data, NSInteger status, NSError *error) {
            assert(data == nil && status == 400 && error == nil);
            addCompleted = YES;
        });
        assert(addCompleted);
    }
}
