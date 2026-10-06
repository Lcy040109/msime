#include "FloatingToolbarVisibilityPolicy.h"

#include <cassert>

int main() {
  using lingyao::windows::ShouldDeferFloatingToolbarHide;
  using lingyao::windows::ShouldShowFloatingToolbar;

  assert(ShouldShowFloatingToolbar(true, false, true));
  assert(!ShouldShowFloatingToolbar(false, false, true));
  assert(!ShouldShowFloatingToolbar(true, true, true));
  assert(!ShouldShowFloatingToolbar(true, false, false));
  assert(ShouldDeferFloatingToolbarHide(true));
  assert(!ShouldDeferFloatingToolbarHide(false));
}
