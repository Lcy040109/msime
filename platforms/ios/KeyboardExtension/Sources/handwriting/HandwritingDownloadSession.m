#import "HandwritingDownloadSession.h"
#import <objc/runtime.h>

static NSString *LINGYAOBackgroundContainer;

@interface NSURLSessionConfiguration (LINGYAOHandwriting)
+ (NSURLSessionConfiguration *)lingyao_handwritingBackgroundWithIdentifier:(NSString *)identifier;
@end

@implementation NSURLSessionConfiguration (LINGYAOHandwriting)
+ (NSURLSessionConfiguration *)lingyao_handwritingBackgroundWithIdentifier:(NSString *)identifier {
  NSURLSessionConfiguration *configuration =
      [self lingyao_handwritingBackgroundWithIdentifier:identifier];
  if (configuration.sharedContainerIdentifier == nil) {
    configuration.sharedContainerIdentifier = LINGYAOBackgroundContainer;
  }
  return configuration;
}
@end

@implementation HandwritingDownloadSession
+ (BOOL)configureSharedContainer:(NSString *)identifier {
  if (NSBundle.mainBundle.infoDictionary[@"NSExtension"] == nil) return YES;
  if ([NSFileManager.defaultManager
          containerURLForSecurityApplicationGroupIdentifier:identifier] == nil) return NO;
  static dispatch_once_t once;
  static BOOL installed;
  dispatch_once(&once, ^{
    Method original = class_getClassMethod(
        NSURLSessionConfiguration.class,
        @selector(backgroundSessionConfigurationWithIdentifier:));
    Method replacement = class_getClassMethod(
        NSURLSessionConfiguration.class,
        @selector(lingyao_handwritingBackgroundWithIdentifier:));
    if (original != NULL && replacement != NULL) {
      LINGYAOBackgroundContainer = identifier.copy;
      method_exchangeImplementations(original, replacement);
      installed = YES;
    }
  });
  return installed;
}
@end
