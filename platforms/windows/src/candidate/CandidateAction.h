#pragma once

#include <cstdint>

namespace lingyao::windows {
enum class CandidateAction : uint8_t {
  Select,
  Pin,
  Remove,
  FixPosition,
  ClearPosition,
};
} // namespace lingyao::windows
