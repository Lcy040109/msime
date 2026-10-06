#import "../../src/core/SharedVoicePreferences.h"
#import "../../src/voice/VoiceProviderOptions.h"
#include <cassert>
#import "../settings/TestPreferenceSuite.h"

int main() {
    @autoreleasepool {
        NSString *suite = [@"app.lingyao.test.provider." stringByAppendingString:NSUUID.UUID.UUIDString];
        NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:suite];
        // Every provider offered as an HTTPS multipart preset must use the batch request path.
        // Falling through starts macOS Speech and silently ignores the selected endpoint and token.
        for (NSString *provider in @[@"openai", @"groq", @"siliconflow", @"everyapi", @"mistral"])
            assert(LINGYAOVoiceUsesNativeHTTPProvider(provider, NO));
        for (NSString *provider in @[@"doubao", @"system", @"unknown", @"", @"local", @"cloud"])
            assert(!LINGYAOVoiceUsesNativeHTTPProvider(provider, NO));
        assert(!LINGYAOVoiceUsesNativeHTTPProvider(@"everyapi", YES));
        // An installed model directory streams through the helper; any other local path, another provider or an external socket does not.
        assert(LINGYAOVoiceUsesLocalModelHelper(@"local", NO, YES) && LINGYAOVoiceUsesLocalModelHelper(@"Local", NO, YES));
        assert(!LINGYAOVoiceUsesLocalModelHelper(@"local", NO, NO) && !LINGYAOVoiceUsesLocalModelHelper(@"local", YES, YES));
        for (NSString *provider in @[@"doubao", @"system", @"openai", @""])
            assert(!LINGYAOVoiceUsesLocalModelHelper(provider, NO, YES));
        // `local` naming no installed model directory (a Whisper .bin from before the model catalog, say) refuses to record instead of reaching a network or system recognizer; a model directory or an external socket does not.
        assert(LINGYAOVoiceLocalModelMissing(@"local", NO, NO) && LINGYAOVoiceLocalModelMissing(@"Local", NO, NO));
        assert(!LINGYAOVoiceLocalModelMissing(@"local", NO, YES) && !LINGYAOVoiceLocalModelMissing(@"local", YES, NO));
        for (NSString *provider in @[@"doubao", @"system", @"openai", @""])
            assert(!LINGYAOVoiceLocalModelMissing(provider, NO, NO));
        assert(!LINGYAOVoiceUsesNativeHTTPProvider(@"local", NO) && !LINGYAOVoiceUsesLocalModelHelper(@"local", NO, NO));
        // Every provider this host calls with the stored token asks for one before recording; an unset provider preference means Doubao.
        for (NSString *provider in @[@"openai", @"groq", @"siliconflow", @"everyapi", @"mistral", @"doubao", @"Doubao"]) {
            assert(LINGYAOVoiceASRTokenMissing(provider, nil, NO) && LINGYAOVoiceASRTokenMissing(provider, @"", NO));
            assert(!LINGYAOVoiceASRTokenMissing(provider, @"synthetic-token", NO));
            assert(!LINGYAOVoiceASRTokenMissing(provider, nil, YES));
        }
        assert(LINGYAOVoiceASRTokenMissing(nil, nil, NO));
        for (NSString *provider in @[@"local", @"system", @"", @"unknown"])
            assert(!LINGYAOVoiceASRTokenMissing(provider, nil, NO));
        NSDictionary *base = @{@"generation": @42, @"language": @"en-us", @"asr_provider": @"doubao"};
        NSDictionary *query = LINGYAOVoiceProviderOptions(base, defaults);
        assert([query[@"commit_mode"] isEqual:@"tsf"]);
        for (NSString *mode in @[@"tsf", @"sendinput", @"ctrl_v"]) {
            LINGYAOApplySharedVoicePreferences(@{@"commit_mode": mode}, defaults);
            assert([LINGYAOVoiceProviderOptions(base, defaults)[@"commit_mode"] isEqual:mode]);
        }
        for (id invalid in @[@"unknown", @42, @[]]) {
            [defaults setObject:invalid forKey:@"LINGYAOClientVoiceCommitMode"];
            assert([LINGYAOVoiceProviderOptions(base, defaults)[@"commit_mode"] isEqual:@"tsf"]);
        }
        assert([query[@"polish_text"] isEqual:@YES]);
        assert(!query[@"doubao_auth_mode"]);
        assert([query[@"doubao_enable_itn"] isEqual:@YES]);
        assert([query[@"doubao_enable_punc"] isEqual:@YES]);
        assert([query[@"doubao_enable_ddc"] isEqual:@YES]);
        assert(LINGYAOVoiceMuteSystemAudioEnabled(defaults));
        LINGYAOApplySharedVoicePreferences(@{@"mute_system_audio": @NO}, defaults);
        assert(!LINGYAOVoiceMuteSystemAudioEnabled(defaults));
        // Test the actual shared-settings -> native preferences -> request path.
        LINGYAOApplySharedVoicePreferences(@{@"doubao_auth_mode": @"api_key",
            @"doubao_enable_itn": @NO, @"doubao_enable_punc": @NO, @"doubao_enable_ddc": @NO}, defaults);
        query = LINGYAOVoiceProviderOptions(base, defaults);
        assert([query[@"doubao_auth_mode"] isEqual:@"api_key"]);
        assert([query[@"doubao_enable_itn"] isEqual:@NO]);
        assert([query[@"doubao_enable_punc"] isEqual:@NO]);
        assert([query[@"doubao_enable_ddc"] isEqual:@NO]);
        for (NSString *key in base) assert([query[key] isEqual:base[key]]);
        assert(base.count == 3 && [NSJSONSerialization isValidJSONObject:query]);
        LINGYAOApplySharedVoicePreferences(@{@"polish_text": @YES, @"polish_enabled": @NO}, defaults);
        assert([LINGYAOVoiceProviderOptions(base, defaults)[@"polish_text"] isEqual:@YES]);
        LINGYAOApplySharedVoicePreferences(@{@"polish_text": @NO}, defaults);
        assert([LINGYAOVoiceProviderOptions(base, defaults)[@"polish_text"] isEqual:@NO]);
        LINGYAOApplySharedVoicePreferences(@{@"doubao_auth_mode": @"legacy"}, defaults);
        assert([LINGYAOVoiceProviderOptions(base, defaults)[@"doubao_auth_mode"] isEqual:@"legacy"]);
        for (id invalid in @[@"", @"unknown", @42, @[]]) {
            [defaults setObject:invalid forKey:@"LINGYAOClientVoiceDoubaoAuthMode"];
            assert(!LINGYAOVoiceProviderOptions(base, defaults)[@"doubao_auth_mode"]);
        }
        [defaults setObject:@"false" forKey:@"LINGYAOClientVoiceDoubaoEnableITN"];
        [defaults setObject:@[] forKey:@"LINGYAOClientVoiceDoubaoEnablePunctuation"];
        [defaults setObject:@"false" forKey:@"LINGYAOClientVoiceDoubaoEnableDDC"];
        query = LINGYAOVoiceProviderOptions(base, defaults);
        assert([query[@"doubao_enable_itn"] isEqual:@YES]);
        assert([query[@"doubao_enable_punc"] isEqual:@YES]);
        assert([query[@"doubao_enable_ddc"] isEqual:@YES]);
        LINGYAORemoveTestPreferenceSuite(defaults, suite);
    }
}
