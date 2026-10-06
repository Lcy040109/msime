#pragma once

#include <filesystem>
#include <string>

#include "LinuxEdition.h"

namespace lingyao_linux {

#ifndef LINGYAO_INSTALLED_RESOURCE_RELATIVE_DIR
#define LINGYAO_INSTALLED_RESOURCE_RELATIVE_DIR "../share/" LINGYAO_EDITION_CLIENT_DIRECTORY "/resources"
#endif
#ifndef LINGYAO_INSTALLED_SOUND_PACKS_RELATIVE_DIR
#define LINGYAO_INSTALLED_SOUND_PACKS_RELATIVE_DIR "../share/" LINGYAO_EDITION_CLIENT_DIRECTORY "/sound-packs"
#endif

// Resolve the resource bundle installed beside the executable.  The bundle is
// deliberately derived from /proc/self/exe (the caller supplies that resolved
// path), so daemon working directories and PATH lookups cannot change it.
inline std::string installed_resource_directory(
    const std::filesystem::path &executable,
    const std::filesystem::path &relative = LINGYAO_INSTALLED_RESOURCE_RELATIVE_DIR) {
  if (!executable.is_absolute()) return {};
  if (relative.empty() || relative.is_absolute()) return {};
  const auto candidate =
      (executable.lexically_normal().parent_path() / relative).lexically_normal();
  std::error_code error;
  if (!std::filesystem::is_directory(candidate, error) || error) return {};
  const auto resolved = std::filesystem::canonical(candidate, error);
  if (error || !resolved.is_absolute()) return {};
  return resolved.string();
}

// The built-in sound packs installed beside the resource bundle. The IBus host names them to the Host API as sound_packs: the library's own fallback looks beside the configured resource directory, and that is no longer the installed one once the user has downloaded a newer dictionary into their own data directory.
inline std::string installed_sound_pack_directory(const std::filesystem::path &executable) {
  return installed_resource_directory(executable, LINGYAO_INSTALLED_SOUND_PACKS_RELATIVE_DIR);
}

} // namespace lingyao_linux
