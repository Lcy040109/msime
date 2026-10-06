#pragma once
#import <AppKit/AppKit.h>
#import <Carbon/Carbon.h>
#import <Foundation/Foundation.h>

using LINGYAOInputSourceRegistrar = OSStatus (*)(CFURLRef);
using LINGYAOInputSourceLister = CFArrayRef (*)(CFDictionaryRef, Boolean);
using LINGYAOInputSourcePropertyGetter = void *(*)(TISInputSourceRef, CFStringRef);
using LINGYAOInputSourceEnabler = OSStatus (*)(TISInputSourceRef);
using LINGYAOInputSourceCopier = TISInputSourceRef (*)(void);

@interface LINGYAOInputSourceMonitor : NSObject
- (instancetype)initWithCenter:(NSNotificationCenter *)center bundleIdentifier:(NSString *)identifier
                    copySource:(LINGYAOInputSourceCopier)copier propertyGetter:(LINGYAOInputSourcePropertyGetter)getter
                    switchedAway:(void (^)(void))action;
- (void)stop;
@end

bool LINGYAOShouldRegisterInputSource(int argc, const char *argv[]);
OSStatus LINGYAORegisterInputSource(NSURL *bundleURL, LINGYAOInputSourceRegistrar registrar);
OSStatus LINGYAORegisterAndEnableInputSources(NSURL *bundleURL, NSString *bundleIdentifier,
                                            LINGYAOInputSourceRegistrar registrar,
                                            LINGYAOInputSourceLister lister,
                                            LINGYAOInputSourcePropertyGetter propertyGetter,
                                            LINGYAOInputSourceEnabler enabler);
/// 把 bundle 里 `offered` 还没列出的输入模式各启用一次，返回加上这些模式后的 `offered`，由调用方持久化。经更新只替换 bundle 时不会重新登记，新版本加的模式会一直关着，除非用户自己去系统设置的「添加」对话框里找——而那里按每个模式声明的语言分组，新模式不一定和其它模式排在一起。已经记录的模式不再动，用户移除的模式保持移除。`offered` 为 nil 时，从此前每次安装都会启用的那几个模式开始。按需模式（LINGYAOOptInInputModeIDs）只记录不启用；如果系统无视声明自行启用了，第一次记录时由 `disabler` 关掉一次。
NSArray<NSString *> *LINGYAOEnableNewInputModes(NSString *bundleIdentifier, NSArray<NSString *> *offered,
                                              LINGYAOInputSourceLister lister,
                                              LINGYAOInputSourcePropertyGetter propertyGetter,
                                              LINGYAOInputSourceEnabler enabler,
                                              LINGYAOInputSourceEnabler disabler);
/// 启用这个标识符对应的已安装输入源，不论它当前是否启用。用户选中粤拼、注音、越南文、藏文或笔画时就靠它打开对应的按需模式，用户不必去系统设置「添加」对话框的「粤语」「繁体中文」「越南语」「藏语」或「简体中文」下面找。
OSStatus LINGYAOEnableInputMode(NSString *identifier, LINGYAOInputSourceLister lister, LINGYAOInputSourceEnabler enabler);
/// Whether the input source with this identifier is enabled, so the system can select it.
BOOL LINGYAOInputSourceIsEnabled(NSString *identifier);
/// Starts a separate non-activating helper instance of the current input method
/// to re-register its source. Completion is always delivered on the main thread.
void LINGYAOLaunchInputSourceReregistration(NSURL *bundleURL, NSWorkspace *workspace,
                                          void (^completion)(BOOL launched));
