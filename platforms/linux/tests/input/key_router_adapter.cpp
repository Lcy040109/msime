#include "../src/core/KeyRouterAdapter.h"
#include <cassert>

int main() {
  lingyao::linux_host::KeyRouterAdapter adapter;
  assert(lingyao::linux_host::KeyRouterAdapter::lease_token(1, 0) == 1);
  assert(lingyao::linux_host::KeyRouterAdapter::lease_token(1, 3) == 3);
  assert(lingyao::linux_host::KeyRouterAdapter::virtual_key(0x41) == 0x41);
  assert(lingyao::linux_host::KeyRouterAdapter::virtual_key(0xffe3) == 0);

  lingyao_client_key_event event{{1, 2, 3}, 0x41, 30, 0, 'a', false};
  assert(adapter.check(event) == LINGYAO_CLIENT_KEY_DEFINITELY_NOT_SENT);

  adapter.set_lease(event.lease);
  assert(adapter.check(event) == LINGYAO_CLIENT_KEY_SENT);
  // Ctrl+Shift+Super stays inside the ABI's four modifier bits, so the router still accepts it.
  auto super_chord = event;
  super_chord.modifiers = lingyao::linux_host::KeyRouterAdapter::modifiers(true, true, false, true);
  assert(super_chord.modifiers == 0x0b);
  assert(adapter.check(super_chord) == LINGYAO_CLIENT_KEY_SENT);
  assert(lingyao::linux_host::KeyRouterAdapter::modifiers(true, true, true, true) == 0x0f);

  auto stale = event;
  stale.lease.epoch++;
  assert(adapter.check(stale) == LINGYAO_CLIENT_KEY_DEFINITELY_NOT_SENT);
  assert(!adapter.cancel(stale.lease));
  assert(adapter.check(event) == LINGYAO_CLIENT_KEY_SENT);

  assert(adapter.cancel(event.lease));
  assert(adapter.check(event) == LINGYAO_CLIENT_KEY_DEFINITELY_NOT_SENT);
  assert(!adapter.cancel(event.lease));
  assert(!adapter.cancel({}));

  lingyao_client_key_event without_session{
      {7, 8, lingyao::linux_host::KeyRouterAdapter::lease_token(7, 0)},
      0x42,
      48,
      0,
      'b',
      false};
  adapter.set_lease(without_session.lease);
  assert(adapter.check(without_session) == LINGYAO_CLIENT_KEY_SENT);

  auto with_session = without_session;
  with_session.lease.token =
      lingyao::linux_host::KeyRouterAdapter::lease_token(7, 9);
  adapter.set_lease(with_session.lease);
  assert(adapter.check(without_session) == LINGYAO_CLIENT_KEY_DEFINITELY_NOT_SENT);
  assert(adapter.check(with_session) == LINGYAO_CLIENT_KEY_SENT);
  assert(!adapter.cancel({with_session.lease.client, with_session.lease.epoch, 0}));
  assert(adapter.check(with_session) == LINGYAO_CLIENT_KEY_SENT);
  assert(adapter.cancel(with_session.lease));
  assert(!adapter.cancel({}));
  return 0;
}
