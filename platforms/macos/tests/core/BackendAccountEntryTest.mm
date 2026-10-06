#import "../../src/backend/account/BackendAccountEntry.h"
#include <cassert>

@interface RecordingAccountWindow : NSObject <LINGYAOBackendAccountEntry>
@property(nonatomic) NSUInteger presentations;
@property(nonatomic) NSUInteger clipboards;
@end
@implementation RecordingAccountWindow
+ (id)shared {
    static RecordingAccountWindow *window = [RecordingAccountWindow new];
    return window;
}
- (void)showAccount { self.presentations += 1; }
- (void)showCloudClipboard { self.clipboards += 1; }
@end

@interface InvalidAccountWindow : NSObject
@end
@implementation InvalidAccountWindow
+ (id)shared { return [NSObject new]; }
@end

int main() {
    @autoreleasepool {
        assert(!LINGYAOOpenBackendAccount(Nil));
        assert(!LINGYAOOpenBackendClipboard(Nil));
        assert(!LINGYAOOpenBackendClipboard(NSObject.class));
        assert(!LINGYAOOpenBackendClipboard(InvalidAccountWindow.class));
        assert(LINGYAOOpenBackendClipboard(RecordingAccountWindow.class));
        assert(((RecordingAccountWindow *)[RecordingAccountWindow shared]).clipboards == 1);
        assert(!LINGYAOOpenBackendAccount(NSObject.class));
        assert(!LINGYAOOpenBackendAccount(InvalidAccountWindow.class));
        assert(LINGYAOOpenBackendAccount(RecordingAccountWindow.class));
        assert(LINGYAOOpenBackendAccount(RecordingAccountWindow.class));
        assert(((RecordingAccountWindow *)[RecordingAccountWindow shared]).presentations == 2);
    }
}
