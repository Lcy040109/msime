#include <cassert>
#include "../../src/core/PairedPunctuation.h"

int main() {
  lingyao::mac::PairedPunctuationTracker tracker;
  tracker.push("）");
  tracker.push("】");
  assert(tracker.size() == 2);
  assert(!lingyao::mac::paired_closing_should_skip(tracker, "】", "】", true, 1, 1, 2, 4));
  assert(tracker.size() == 2);
  assert(lingyao::mac::paired_closing_should_skip(tracker, "】", "】", true, 0, 1, 2, 4));
  assert(tracker.size() == 1);
  assert(!lingyao::mac::paired_closing_should_skip(tracker, "）", "", false, 0, 1, 2, 4));
  assert(tracker.empty());
}
