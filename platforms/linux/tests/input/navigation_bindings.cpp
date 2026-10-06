#include "../src/core/HelpcodeDefaults.h"
#include "../src/core/NavigationBindings.h"
#include "../src/core/WordCharacterBinding.h"

#include <cassert>

int main() {
  assert(lingyao::linux_host::default_helpcode_schema("quanpin") == "ziranma");
  assert(!lingyao::linux_host::default_show_helpcode("quanpin"));
  assert(lingyao::linux_host::default_helpcode_schema("shuangpin") == "lantian");
  assert(lingyao::linux_host::default_show_helpcode("shuangpin"));

  auto word_character =
      lingyao::linux_host::WordCharacterBinding::read(nlohmann::json::object());
  assert(word_character.enabled);
  assert(word_character.edge(IBUS_bracketleft, false) == LINGYAO_FIRST_HAN);
  assert(word_character.edge(IBUS_bracketright, false) == LINGYAO_LAST_HAN);
  assert(!word_character.edge(IBUS_minus, false));

  lingyao::linux_host::NavigationBindings bindings;
  assert(bindings.command(lingyao::linux_host::kTouchKeyboardNextPage, false) ==
         LINGYAO_NEXT_PAGE);
  assert(bindings.command(lingyao::linux_host::kTouchKeyboardPreviousPage, false) ==
         LINGYAO_PREVIOUS_PAGE);

  bindings.tab = false;
  bindings.page_up_down = false;
  bindings.brackets = false;
  assert(!bindings.wheel_command(4));
  bindings.mouse_wheel = true;
  assert(bindings.wheel_command(4) == LINGYAO_PREVIOUS_PAGE);
  assert(bindings.wheel_command(5) == LINGYAO_NEXT_PAGE);
  assert(!bindings.wheel_command(1));
  assert(bindings.command(lingyao::linux_host::kTouchKeyboardNextPage, true) ==
         LINGYAO_NEXT_PAGE);
  assert(bindings.command(lingyao::linux_host::kTouchKeyboardPreviousPage, true) ==
         LINGYAO_PREVIOUS_PAGE);

  const auto malformed_array = nlohmann::json{
      {"navigation", nlohmann::json::array({"invalid"})}};
  const auto fallback_array =
      lingyao::linux_host::NavigationBindings::read(malformed_array);
  assert(fallback_array.tab && fallback_array.page_up_down &&
         fallback_array.arrows && !fallback_array.mouse_wheel);
  const auto malformed_scalar =
      nlohmann::json{{"navigation", nlohmann::json("invalid")}};
  const auto fallback_scalar =
      lingyao::linux_host::NavigationBindings::read(malformed_scalar);
  assert(fallback_scalar.minus_equal && fallback_scalar.comma_period &&
         !fallback_scalar.brackets);
  return 0;
}
