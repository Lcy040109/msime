#include "PrepareHost.h"
#include "lingyao_client.h"
#include <iostream>
#include <memory>

int wmain(int argc, wchar_t **argv) {
  if (argc == 2 && std::wstring(argv[1]) == L"--help") {
    std::cout << "Usage: lingyao-client-prepare <absolute-resource-directory> "
                 "<absolute-new-state-directory>\n"
                 "Run as the input-method user before starting Server or TSF.\n"
                 "The state directory must not exist; its parent must exist.\n";
    return 0;
  }
  if (argc != 3) {
    std::cerr << "Expected absolute resource and new state directories\n";
    return 2;
  }
  try {
    lingyao::windows::prepare_host_state(argv[1], argv[2], [](const std::string &request) {
      std::unique_ptr<char, decltype(&lingyao_client_string_free)> response(
          lingyao_client_prepare_host(
              reinterpret_cast<const uint8_t *>(request.data()), request.size()),
          lingyao_client_string_free);
      if (!response)
        throw std::runtime_error("Shared host preparation failed");
      return std::string(response.get());
    });
    std::cout << "Prepared runtime-options.json successfully\n";
    return 0;
  } catch (...) {
    // Host errors may contain private paths. Never forward their raw contents.
    std::cerr << "Preparation failed; existing and partially prepared data retained\n";
    return 1;
  }
}
