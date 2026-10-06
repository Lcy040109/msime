#import "../../src/input/InputModeRouting.h"
#import <AppKit/AppKit.h>
#include <cassert>
int main(){assert(lingyao::mac::ShouldToggleInputMode(true,kVK_Space,NSEventModifierFlagShift)); assert(!lingyao::mac::ShouldToggleInputMode(false,kVK_Space,NSEventModifierFlagShift)); assert(!lingyao::mac::ShouldToggleInputMode(true,kVK_Space,NSEventModifierFlagShift|NSEventModifierFlagCommand)); assert(lingyao::mac::ShouldPrepareInputSession(false)); assert(!lingyao::mac::ShouldPrepareInputSession(true));}
