#pragma once

#include <string>

namespace lingyao::windows {
void configure_audio_mute_state_path(std::wstring path);
void mute_other_system_audio();
void restore_other_system_audio();
} // namespace lingyao::windows
