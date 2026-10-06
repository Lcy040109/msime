#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN
typedef void (^LINGYAODictionaryPrepareCompletion)(NSDictionary *_Nullable options, NSError *_Nullable error);

/// Paths copied from validated LINGYAOClientSession host options; never accepts UI paths.
@interface LINGYAODictionaryRuntime : NSObject
- (nullable instancetype)initWithHostOptions:(NSDictionary<NSString *, id> *)options error:(NSError **)error;
/// Runs prepare_host off the main thread and delivers the validated HostOptions on the main thread.
+ (void)prepareResourcesDirectory:(NSString *)resourcesDirectory stateRoot:(NSString *)stateRoot completion:(LINGYAODictionaryPrepareCompletion)completion;
@property(nonatomic, readonly) NSURL *resourcesDirectory;
@property(nonatomic, readonly) NSURL *userDataDirectory;
@property(nonatomic, readonly) NSURL *cacheDirectory;
@property(nonatomic, readonly) NSURL *dictionariesDirectory;
@end
NS_ASSUME_NONNULL_END
