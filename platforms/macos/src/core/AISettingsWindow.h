#import <AppKit/AppKit.h>
@interface LINGYAOAISettingsWindow : NSWindowController
- (instancetype)initWithDirectory:(NSString *)directory saved:(void (^)(NSDictionary *))saved;
@end
