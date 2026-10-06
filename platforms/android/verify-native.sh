#!/usr/bin/env bash
set -euo pipefail
readelf_tool=${1:?usage: verify-native.sh <llvm-readelf> <library-directory> <abi>}
library_dir=${2:?library directory required}
abi=${3:?ABI required}
case "$abi" in
  arm64-v8a) machine=AArch64 ;;
  x86_64) machine='Advanced Micro Devices X86-64' ;;
  *) echo "Unsupported ABI" >&2; exit 1 ;;
esac
# The two speech runtime libraries are prebuilt upstream (pinned in resources/voice-runtime.lock.json) and link libc++ statically; they are held to the same architecture and 16KB alignment, with an allowlist that adds only what sherpa-onnx itself needs.
for name in liblingyao_host_api.so liblingyao_android.so libc++_shared.so libsherpa-onnx-c-api.so libonnxruntime.so; do
  library="$library_dir/$name"
  header=$("$readelf_tool" -h "$library")
  [[ "$header" == *ELF64* && "$header" == *"$machine"* ]] || { echo "Wrong ELF architecture: $name" >&2; exit 1; }
  segments=$("$readelf_tool" -l --wide "$library" | awk '$1 == "LOAD" {print $NF}')
  [[ -n "$segments" ]] || exit 1
  while IFS= read -r alignment; do
    [[ "$alignment" =~ ^0x[[:xdigit:]]+$ ]] && (( alignment >= 16384 )) || { echo "LOAD alignment below 16KB: $name" >&2; exit 1; }
  done <<< "$segments"
  dependencies=$("$readelf_tool" -d "$library" | awk '/NEEDED/ {gsub(/[][]/, "", $NF); print $NF}')
  while IFS= read -r dependency; do
    case "$dependency" in
      libc.so|libm.so|libdl.so|liblog.so|libc++_shared.so|liblingyao_host_api.so|'') ;;
      libandroid.so|libonnxruntime.so) [[ "$name" == libsherpa-onnx-c-api.so ]] || { echo "Unexpected dynamic dependency: $name -> $dependency" >&2; exit 1; } ;;
      # Microphone capture in host-api goes through cpal, which links AAudio where the Engine's miniaudio used to dlopen it. AAudio is a public NDK library from API 26, below this host's minSdk 28.
      libaaudio.so) [[ "$name" == liblingyao_host_api.so ]] || { echo "Unexpected dynamic dependency: $name -> $dependency" >&2; exit 1; } ;;
      *) echo "Unexpected dynamic dependency: $name -> $dependency" >&2; exit 1 ;;
    esac
  done <<< "$dependencies"
  echo "$name: $abi ELF, 16KB LOAD alignment and dependency allowlist passed"
done
symbols=$("$readelf_tool" --dyn-syms --wide "$library_dir/liblingyao_host_api.so")
for symbol in lingyao_client_prepare_host lingyao_client_refresh_host lingyao_client_create lingyao_client_snapshot_version lingyao_client_snapshot_prepare lingyao_client_snapshot_discard lingyao_client_snapshot_activate lingyao_client_character lingyao_client_punctuation_with_context lingyao_client_load_preferences lingyao_client_save_preferences lingyao_client_theme_catalog lingyao_client_resolve_theme lingyao_client_update_preferences lingyao_client_set_nine_key_mode lingyao_client_set_private_session lingyao_client_mobile_voice_configuration lingyao_client_simplified_to_traditional lingyao_client_reset_cache lingyao_client_mobile_clipboard_history lingyao_client_set_chinese_punctuation lingyao_client_set_character_width lingyao_client_select_edge lingyao_client_doubao_start_frame lingyao_client_doubao_audio_frame lingyao_client_doubao_decode_frame lingyao_client_choose_nine_key_spelling lingyao_client_pin_candidate lingyao_client_fix_candidate_position lingyao_client_clear_candidate_position lingyao_client_remove_candidate lingyao_client_emoji_catalog_request lingyao_client_candidate_gloss_request lingyao_client_apply_translations lingyao_client_online_query lingyao_client_cloud_request_url lingyao_client_ai_request_for_query lingyao_client_apply_cloud_response lingyao_client_apply_online_candidates lingyao_client_vocabulary_review lingyao_client_voice_hotwords lingyao_client_voice_hotword_correct lingyao_client_telemetry_begin lingyao_client_telemetry_end lingyao_client_telemetry_flush lingyao_client_telemetry_clear lingyao_client_notices lingyao_client_notice_dismiss lingyao_client_app_theme_catalog lingyao_client_resolve_app_theme lingyao_client_restore_default_preferences lingyao_client_default_preferences lingyao_client_host_capabilities lingyao_client_dictionary lingyao_client_personal_dictionary_request lingyao_client_dictionary_hans_entries lingyao_client_dictionary_import_entries lingyao_client_dictionary_manifest lingyao_client_plugins lingyao_client_community_resource_library lingyao_client_ai_skin_plan lingyao_client_keyboard_skin_trial lingyao_client_community_skin_install lingyao_client_key_sound_pack lingyao_client_common_phrases lingyao_client_dictionary_collections lingyao_client_diagnostic_bundle lingyao_client_account_settings_export lingyao_client_account_settings_apply lingyao_client_string_free; do
  grep -Eq "GLOBAL +DEFAULT +[0-9]+ +${symbol}$" <<< "$symbols" || { echo "Missing host export: $symbol" >&2; exit 1; }
done
symbols=$("$readelf_tool" --dyn-syms --wide "$library_dir/liblingyao_android.so")
for method in prepareHostRaw refreshHostRaw snapshotVersionRaw snapshotPrepareRaw snapshotDiscardRaw snapshotActivateRaw loadPreferencesRaw savePreferencesRaw themeCatalogRaw resolveThemeRaw createRaw characterRaw punctuationWithContextRaw setNineKeyModeRaw setPrivateSessionRaw mobileVoiceConfigurationRaw simplifiedToTraditionalRaw resetCacheRaw mobileClipboardHistoryRaw setChinesePunctuationRaw setCharacterWidthRaw selectEdgeRaw doubaoStartFrameRaw doubaoAudioFrameRaw doubaoDecodeFrameRaw chooseNineKeySpellingRaw updatePreferencesRaw pinCandidateRaw fixCandidatePositionRaw clearCandidatePositionRaw removeCandidateRaw emojiCatalogRaw candidateGlossesRaw applyTranslationsRaw onlineQueryRaw cloudRequestUrlRaw aiRequestForQueryRaw applyCloudResponseRaw applyOnlineCandidatesRaw vocabularyReviewRaw voiceHotwordsRaw voiceHotwordCorrectRaw localSpeechAvailableRaw localSpeechCreateRaw localSpeechStartRaw localSpeechAcceptRaw localSpeechFinishRaw localSpeechCancelRaw localSpeechDestroyRaw localSpeechReleaseRaw telemetryBeginRaw telemetryEndRaw telemetryFlushRaw telemetryClearRaw noticesRaw noticeDismissRaw destroyRaw aiSkinPlanRaw allCandidatesRaw appThemeCatalogRaw commandRaw communityResourceLibraryRaw communitySkinInstallRaw defaultPreferencesRaw dictionaryHansEntriesRaw dictionaryImportEntriesRaw dictionaryManifestRaw dictionaryRaw englishCompletionsRaw focusRaw hostCapabilitiesRaw keyboardSkinTrialRaw keySoundPackRaw personalDictionaryRequestRaw personalDictionarySyncRaw pluginsRaw polishPromptRaw resolveAppThemeRaw restoreDefaultPreferencesRaw selectAnyCandidateRaw selectRaw setEnglishModeRaw shuangpinKeyHintsRaw smartPunctuationArmRaw smartPunctuationDecideRaw typingStatisticsEnabledRaw typingStatisticsRaw viewRaw commonPhrasesRaw dictionaryCollectionsRaw diagnosticBundleRaw accountSettingsExportRaw accountSettingsApplyRaw; do
  grep -Eq "GLOBAL +DEFAULT +[0-9]+ +Java_app_lingyao_android_NativeClient_${method}$" <<< "$symbols" || { echo "Missing JNI export: $method" >&2; exit 1; }
done
nm_tool="${readelf_tool%/llvm-readelf}/llvm-nm"
[[ -x "$nm_tool" ]] || { echo "llvm-nm is required beside llvm-readelf" >&2; exit 1; }
host_symbols=$("$nm_tool" -C --defined-only "$library_dir/liblingyao_host_api.so")
# The candidate ordering policy of lingyao-engine's handwriting module is shared with Android; the model-backed recognizer and its zinnia port (the recognizer, model and features submodules) are compiled out there. The ordering policy has to be present, or the symbols were stripped and the exclusion below would prove nothing.
if ! grep -q 'lingyao_engine::handwriting::order_handwriting_candidates' <<< "$host_symbols"; then
  echo "liblingyao_host_api.so carries no lingyao-engine symbol names; the recognizer exclusion cannot be checked" >&2; exit 1
fi
if grep -Eq 'handwriting_recognize|lingyao_engine::handwriting::(recognizer|model|features)::' <<< "$host_symbols"; then
  echo "Android host unexpectedly contains the Engine handwriting recognizer" >&2; exit 1
fi
echo "liblingyao_host_api.so: Engine handwriting recognizer excluded for Android"
