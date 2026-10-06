#include "../../../platforms/macos/src/voice/VoiceCaptureDevice.h"

#include <cstddef>

extern "C" {
typedef void (*LINGYAOVoiceCaptureDeviceCallback)(const char *uid, const char *name,
                                                bool is_default, void *context);

void lingyao_macos_list_voice_capture_devices(LINGYAOVoiceCaptureDeviceCallback callback,
                                             void *context) {
    if (!callback) return;
    @autoreleasepool {
        for (NSDictionary *device in LINGYAOListVoiceCaptureDevices()) {
            NSString *uid = device[@"uid"];
            NSString *name = device[@"name"];
            if (![uid isKindOfClass:NSString.class] ||
                ![name isKindOfClass:NSString.class] ||
                !uid.length || !name.length)
                continue;
            callback(uid.UTF8String, name.UTF8String,
                     [device[@"default"] boolValue], context);
        }
    }
}
}
