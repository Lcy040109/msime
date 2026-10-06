#include "../../src/input/NavigationPolicy.h"
#include <cassert>
int main() {
  FanyImeNamedpipeData packet{};
  packet.event_type = FanyImePipeEventType::KeyEvent;
  packet.keycode = 0xBD;
  lingyao::windows::NavigationBindings bindings{true, false, false, false, false, false, false};
  assert(lingyao::windows::navigation_action(packet, bindings, false).has_value());
  assert(!lingyao::windows::navigation_action(packet, bindings, false, true).has_value());

  lingyao::windows::NavigationBindings tab_bindings{};
  tab_bindings.tab = true;
  packet.keycode = 0x09;
  packet.modifiers_down = 0;
  const auto next = lingyao::windows::navigation_action(packet, tab_bindings, false);
  assert(next && next->reply == lingyao::windows::NavigationReply::NextPage);
  packet.modifiers_down = 1;
  const auto previous = lingyao::windows::navigation_action(packet, tab_bindings, false);
  assert(previous && previous->reply == lingyao::windows::NavigationReply::PreviousPage);
  packet.modifiers_down = 2;
  assert(!lingyao::windows::navigation_action(packet, tab_bindings, false));
  packet.modifiers_down = 4;
  assert(!lingyao::windows::navigation_action(packet, tab_bindings, false));
}
