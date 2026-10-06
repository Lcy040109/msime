#include "lingyao_client.h"
#include "../core/LocalResourcePaths.h"
#include "provider_socket_cli.h"

#include <array>
#include <cstdlib>
#include <filesystem>
#include <iostream>
#include <memory>
#include <nlohmann/json.hpp>
#include <string>

// 我们自己发布的 deb/rpm 不带手写模型，由设置应用下载到默认数据目录 $XDG_CONFIG_HOME/<客户端目录>/resource-packs/handwriting/。安装前缀和环境变量里都找不到时，--local 再到这里找；用户把数据目录移到别处后，要用参数或 LINGYAO_HANDWRITING_MODEL 指定模型。
static std::string downloaded_handwriting_model() {
  std::filesystem::path root;
  if (const char *config = std::getenv("XDG_CONFIG_HOME"); config && *config && std::filesystem::path(config).is_absolute())
    root = config;
  else if (const char *home = std::getenv("HOME"); home && *home && std::filesystem::path(home).is_absolute())
    root = std::filesystem::path(home) / ".config";
  else
    return {};
  const auto model = root / LINGYAO_EDITION_CLIENT_DIRECTORY / "resource-packs/handwriting/handwriting-zh_CN.model";
  return lingyao_linux::resource_file(model) ? model.string() : std::string{};
}

int main(int argc, char **argv) {
  if (argc == 2 && std::string(argv[1]) == "--help") {
    std::cout << "Usage: lingyao-linux-handwriting [provider-socket] | --local [model]\n";
    return 0;
  }
  const bool local = argc >= 2 && std::string(argv[1]) == "--local";
  if (local && argc > 3)
    return 2;
  const std::string endpoint = local
      ? (argc == 3 ? argv[2] : [] {
          auto model = lingyao_linux::local_resource("LINGYAO_HANDWRITING_MODEL", LINGYAO_EDITION_CLIENT_DIRECTORY "/handwriting/handwriting-zh_CN.model");
          // 显式设置了 LINGYAO_HANDWRITING_MODEL 时不换用别的模型。
          if (model.empty() && !(std::getenv("LINGYAO_HANDWRITING_MODEL") && *std::getenv("LINGYAO_HANDWRITING_MODEL")))
            model = downloaded_handwriting_model();
          return model;
        }())
      : lingyao_cli_provider_socket(argc, argv, "LINGYAO_HANDWRITING_PROVIDER_SOCKET", "handwriting.sock");
  if (endpoint.empty() || endpoint[0] != '/')
    return 2;
  std::array<char, 262145> buffer;
  std::cin.read(buffer.data(), buffer.size());
  const auto length = static_cast<size_t>(std::cin.gcount());
  if (std::cin.bad() || length == 0 || length > 262144)
    return 2;
  std::unique_ptr<char, decltype(&lingyao_client_string_free)> result(
      local ? lingyao_client_handwriting_local_request(
                  reinterpret_cast<const uint8_t *>(buffer.data()), length,
                  reinterpret_cast<const uint8_t *>(endpoint.data()), endpoint.size())
            : lingyao_client_handwriting_provider_request(
                  reinterpret_cast<const uint8_t *>(buffer.data()), length,
                  reinterpret_cast<const uint8_t *>(endpoint.data()), endpoint.size()),
      lingyao_client_string_free);
  if (!result)
    return 1;
  try {
    auto document = nlohmann::json::parse(result.get());
    const bool ok = document.at("ok").get<bool>();
    std::cout << document.dump() << '\n';
    return std::cout ? (ok ? 0 : 1) : 1;
  } catch (...) {
    return 1;
  }
}
