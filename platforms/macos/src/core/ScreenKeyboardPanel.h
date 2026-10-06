#import <AppKit/AppKit.h>
#include <sys/types.h>

typedef BOOL (^LINGYAOScreenKeyboardSender)(unsigned short keyCode, NSEventModifierFlags flags);
typedef pid_t (^LINGYAOScreenKeyboardTargetProvider)(void);

// The panel never becomes the input target. Tests supply a sender without posting events.
@interface LINGYAOScreenKeyboardPanel : NSPanel
+ (instancetype)sharedPanel;
- (instancetype)initWithKeySender:(LINGYAOScreenKeyboardSender)sender;
- (instancetype)initWithKeySender:(LINGYAOScreenKeyboardSender)sender
                    targetProvider:(LINGYAOScreenKeyboardTargetProvider)targetProvider;
- (void)showKeyboard;
- (void)applyThemePreferences:(NSDictionary *)preferences;
@end
