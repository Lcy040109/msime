#import "../../src/core/SharedVoicePreferences.h"
#include <cassert>
#import "../settings/TestPreferenceSuite.h"

int main() {
    @autoreleasepool {
        NSString *suite = [@"app.lingyao.test.voice." stringByAppendingString:NSUUID.UUID.UUIDString];
        NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:suite];
        assert(LINGYAOVoiceInputEnabled(defaults));
        assert(LINGYAOVoiceCueEnabled(defaults, YES) && LINGYAOVoiceCueEnabled(defaults, NO));
        NSDictionary *voice = @{
            @"enabled": @NO, @"hotkey_rctrl_ralt": @YES,
            @"language": @"en-US", @"asr_provider": @"openai",
            @"asr_endpoint": @"https://example.invalid/asr", @"asr_model": @"fixture-model",
            @"asr_model_path": @"/Users/fixture/Library/Application Support/app.lingyao/voice-models/x-asr-zh-en-streaming",
            @"asr_token": @"fixture-only", @"capture_backend": @"macos",
            @"capture_device": @"fixture-device",
            @"asr_app_key": @"fixture-app", @"asr_resource_id": @"fixture-resource",
            @"doubao_boosting_table_id": @"fixture-table", @"polish_provider": @"groq",
            @"polish_endpoint": @"https://example.invalid/polish", @"polish_model": @"fixture-polish",
            @"polish_token": @"fixture-only", @"polish_prompt_id": @"custom1",
            @"polish_prompt_custom_1": @"one",
            @"polish_prompt_custom_2": @"two", @"polish_prompt_custom_3": @"three",
            @"sound_enabled": @NO, @"mute_system_audio": @YES, @"stream_inline_preedit": @NO,
            @"polish_enabled": @YES, @"polish_text": @YES, @"hotkey_ctrl_f9": @NO,
            @"hotkey_hold_space_lock": @NO, @"hotkey_ralt": @YES, @"hotkey_ctrl_win": @YES
        };
        assert(LINGYAOApplySharedVoicePreferences(voice, defaults));
        assert(!LINGYAOVoiceInputEnabled(defaults));
        assert([defaults boolForKey:@"LINGYAOClientVoiceHotkeyCtrlOption"]);
        assert([[defaults stringForKey:@"LINGYAOClientVoiceCaptureBackend"] isEqual:@"macos"]);
        assert(LINGYAOVoiceCaptureBackendSupported([defaults objectForKey:@"LINGYAOClientVoiceCaptureBackend"]));
        assert([[defaults stringForKey:@"LINGYAOClientVoiceCaptureDevice"] isEqual:@"fixture-device"]);
        assert([[defaults stringForKey:@"LINGYAOClientVoiceASRProvider"] isEqual:@"openai"]);
        assert([[defaults stringForKey:@"LINGYAOClientVoiceASREndpoint"] isEqual:voice[@"asr_endpoint"]]);
        // The model the settings page picks is what the IMK's local recognizer loads.
        assert([[defaults stringForKey:@"LINGYAOClientVoiceASRModelPath"] isEqual:voice[@"asr_model_path"]]);
        assert([[defaults stringForKey:@"LINGYAOClientVoicePolishPromptCustom3"] isEqual:@"three"]);
        assert([defaults boolForKey:@"LINGYAOClientVoicePolish"]);
        assert([defaults boolForKey:@"LINGYAOClientVoicePolishText"]);
        assert([defaults boolForKey:@"LINGYAOClientVoiceHotkeyCtrlCommand"]);
        assert(![defaults boolForKey:@"LINGYAOClientVoiceSoundEnabled"]);
        NSDictionary *captured = LINGYAOVoicePreferencesFromDefaults(defaults);
        assert([captured[@"asr_provider"] isEqual:@"openai"]);
        assert([captured[@"capture_backend"] isEqual:@"macos"]);
        assert([captured[@"asr_model_path"] isEqual:voice[@"asr_model_path"]]);
        assert([captured[@"capture_device"] isEqual:@"fixture-device"]);
        assert([captured[@"hotkey_ctrl_win"] isEqual:@YES]);
        assert([captured[@"polish_prompt_custom_3"] isEqual:@"three"]);
        assert([LINGYAOVoicePreferencesFromDefaults(nil) isEqual:@{}]);
        NSDictionary *saved = [defaults persistentDomainForName:suite];
        assert(saved.count == voice.count);
        assert(!LINGYAOApplySharedVoicePreferences(voice, defaults));
        assert(!LINGYAOApplySharedVoicePreferences(nil, defaults));
        assert(!LINGYAOApplySharedVoicePreferences(NSNull.null, defaults));
        assert(!LINGYAOApplySharedVoicePreferences(@[], defaults));
        LINGYAOApplySharedVoicePreferences(@{@"asr_token": NSNull.null, @"capture_backend": @42,
                                           @"capture_device": @42,
                                           @"polish_enabled": @0, @"polish_text": @1, @"sound_enabled": @"true",
                                           @"enabled": @"true", @"hotkey_rctrl_ralt": @0}, defaults);
        assert([[defaults persistentDomainForName:suite] isEqual:saved]);
        for (id supported in @[@"", @"auto", @"AUTO", @"macos", @"MACOS"])
            assert(LINGYAOVoiceCaptureBackendSupported(supported));
        for (id unsupported in @[@"windows", @"pulse", @"pipewire", @"alsa", @42, @[]])
            assert(!LINGYAOVoiceCaptureBackendSupported(unsupported));
        LINGYAOApplySharedVoicePreferences(@{@"capture_device": @"", @"asr_token": @"",
                                           @"polish_enabled": @NO, @"polish_text": @NO}, defaults);
        assert([[defaults stringForKey:@"LINGYAOClientVoiceCaptureDevice"] isEqual:@""]);
        assert([[defaults stringForKey:@"LINGYAOClientVoiceASRToken"] isEqual:@""]);
        assert(![defaults boolForKey:@"LINGYAOClientVoicePolish"]);
        assert(![defaults boolForKey:@"LINGYAOClientVoicePolishText"]);
        LINGYAOApplySharedVoicePreferences(@{@"enabled": @YES, @"hotkey_rctrl_ralt": @NO}, defaults);
        assert(LINGYAOVoiceInputEnabled(defaults));
        assert(![defaults boolForKey:@"LINGYAOClientVoiceHotkeyCtrlOption"]);
        NSDictionary *providerSlots = @{
            @"asr_provider": @"openai",
            @"asr_tokens": @{@"openai": @"slot-asr"},
            @"polish_provider": @"groq",
            @"polish_tokens": @{@"groq": @"slot-polish"}
        };
        assert(LINGYAOApplySharedVoicePreferences(providerSlots, defaults));
        assert([[defaults stringForKey:@"LINGYAOClientVoiceASRToken"] isEqual:@"slot-asr"]);
        assert([[defaults stringForKey:@"LINGYAOClientVoicePolishToken"] isEqual:@"slot-polish"]);
        NSDictionary *capturedSlots = LINGYAOVoicePreferencesFromDefaults(defaults);
        assert([capturedSlots[@"asr_tokens"][@"openai"] isEqual:@"slot-asr"]);
        assert([capturedSlots[@"polish_tokens"][@"groq"] isEqual:@"slot-polish"]);
        assert([LINGYAOVoiceTokenForProvider(defaults, @"LINGYAOClientVoiceASRTokens",
                                           @"openai", @"legacy") isEqual:@"slot-asr"]);
        assert([LINGYAOVoiceTokenForProvider(defaults, @"LINGYAOClientVoiceASRTokens",
                                           @"groq", @"legacy") isEqual:@""]);
        assert(LINGYAOSaveVoiceTokenSlot(defaults, @"LINGYAOClientVoiceASRTokens",
                                       @"groq", @"slot-groq"));
        assert([LINGYAOVoiceTokenForProvider(defaults, @"LINGYAOClientVoiceASRTokens",
                                           @"groq", @"legacy") isEqual:@"slot-groq"]);

        for (NSNumber *master in @[@NO, @YES]) {
            for (NSNumber *start in @[@NO, @YES]) {
                for (NSNumber *end in @[@NO, @YES]) {
                    LINGYAOApplySharedVoicePreferences(@{@"sound_enabled": master, @"start_sound": start, @"end_sound": end}, defaults);
                    assert(LINGYAOVoiceCueEnabled(defaults, YES) == (master.boolValue && start.boolValue));
                    assert(LINGYAOVoiceCueEnabled(defaults, NO) == (master.boolValue && end.boolValue));
                }
            }
        }
        LINGYAOApplySharedVoicePreferences(@{@"start_sound": @NO, @"end_sound": @NO}, defaults);
        LINGYAOApplySharedVoicePreferences(@{@"start_sound": @"true", @"end_sound": @1}, defaults);
        assert(!LINGYAOVoiceCueEnabled(defaults, YES) && !LINGYAOVoiceCueEnabled(defaults, NO));
        LINGYAORemoveTestPreferenceSuite(defaults, suite);
    }
}
