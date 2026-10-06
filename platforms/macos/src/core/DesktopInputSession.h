#pragma once
#import <AppKit/AppKit.h>

typedef void (^LINGYAOPanelTextCompletion)(BOOL committed);
typedef void (^LINGYAOPanelTextHandler)(NSString *text, double deadline, LINGYAOPanelTextCompletion completion);

// One menu presentation, one confirmed submission. Never persists input.
@interface LINGYAODesktopInputSession : NSObject
- (instancetype)initWithTargetPID:(pid_t)pid launchTime:(double)launched handler:(LINGYAOPanelTextHandler)handler;
- (instancetype)initWithTargetPID:(pid_t)pid launchTime:(double)launched clipboard:(BOOL)clipboard handler:(LINGYAOPanelTextHandler)handler;
@property(nonatomic, readonly, copy) NSDictionary<NSString *, NSString *> *launchEnvironment;
- (void)authorizePID:(pid_t)pid stillValid:(BOOL (^)(void))valid;
- (BOOL)isAuthorizedPeerAlive;
- (void)stop;
@end
