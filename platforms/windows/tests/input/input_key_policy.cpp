#include "input/InputKeyPolicy.h"
#include <cassert>

int main() {
  using lingyao::windows::should_learn_entered_english_word;
  using lingyao::windows::normalize_numpad_digit_key;
  using lingyao::windows::is_backend_independent_reset_key;
  assert(normalize_numpad_digit_key(0x60) == '0');
  assert(normalize_numpad_digit_key(0x69) == '9');
  assert(normalize_numpad_digit_key(0x41) == 0x41);
  assert(is_backend_independent_reset_key(0x1B));
  assert(is_backend_independent_reset_key(0xA1));
  assert(!is_backend_independent_reset_key(0xA2));
  using lingyao::windows::is_segment_backspace_key;
  using lingyao::windows::is_segment_caret_key;
  using lingyao::windows::kModifierControl;
  using lingyao::windows::kModifierShift;
  using lingyao::windows::kVirtualKeyBackspace;
  using lingyao::windows::kVirtualKeyLeft;
  using lingyao::windows::kVirtualKeyRight;
  assert(is_segment_backspace_key(kVirtualKeyBackspace, kModifierControl));
  assert(!is_segment_backspace_key(kVirtualKeyBackspace,
                                   kModifierControl | kModifierShift));
  assert(is_segment_caret_key(kVirtualKeyLeft, kModifierControl));
  assert(is_segment_caret_key(kVirtualKeyRight, kModifierControl));
  assert(!is_segment_caret_key(kVirtualKeyRight, kModifierControl | kModifierShift));
  using lingyao::windows::should_send_composition_reply;
  assert(should_send_composition_reply(false, false, false, false, false,
                                        true));
  assert(!should_send_composition_reply(false, false, false, false, false,
                                         false));
  using lingyao::windows::is_english_mode_toggle_key;
  using lingyao::windows::kModifierAlt;
  assert(is_english_mode_toggle_key('E', kModifierControl | kModifierShift));
  assert(!is_english_mode_toggle_key('E', kModifierControl | kModifierShift | kModifierAlt));
  assert(!is_english_mode_toggle_key('E', kModifierControl));
  assert(!is_english_mode_toggle_key('E', kModifierShift));
  assert(!is_english_mode_toggle_key('F', kModifierControl | kModifierShift));
  assert(should_learn_entered_english_word(false, false, true, false));
  assert(should_learn_entered_english_word(true, false, true, true));
  assert(should_learn_entered_english_word(false, true, true, true));
  assert(should_learn_entered_english_word(false, true, false, true));
  assert(!should_learn_entered_english_word(false, false, true, true));
  assert(!should_learn_entered_english_word(false, false, false, false));
}
