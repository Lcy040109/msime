cmake_minimum_required(VERSION 3.25)
project(LINGYAOClientLinux LANGUAGES CXX)
find_package(CURL REQUIRED)
include(GNUInstallDirs)
include(cmake/Edition.cmake)
# The user units lingyao-linux-setup can enable. The CMake uninstall and the Debian maintainer scripts all stop them, so the list is defined once here; each socket precedes its service so stopping in this order does not activate the service again. The maintainer scripts restart only the services: sockets run no program.
# 单元名以版本的包名开头（full 是 lingyao-linux），几个版本的用户服务可以同时启用。
set(LINGYAO_USER_UNITS ${LINGYAO_EDITION_PACKAGE}-online.socket ${LINGYAO_EDITION_PACKAGE}-online.service ${LINGYAO_EDITION_PACKAGE}-voice.socket
    ${LINGYAO_EDITION_PACKAGE}-voice.service ${LINGYAO_EDITION_PACKAGE}-clipboard.service)
set(LINGYAO_USER_SERVICES ${LINGYAO_USER_UNITS})
list(FILTER LINGYAO_USER_SERVICES INCLUDE REGEX "\\.service$")
list(JOIN LINGYAO_USER_UNITS " " LINGYAO_USER_UNIT_LIST)
list(JOIN LINGYAO_USER_SERVICES " " LINGYAO_USER_SERVICE_LIST)
# Session managers read XDG autostart entries from $XDG_CONFIG_DIRS/autostart, /etc/xdg/autostart by default. GNUInstallDirs maps the system configuration directory of a /usr prefix to /etc, so only then is the entry installed there, as an absolute directory the CMake uninstall accepts as a second root. Every other prefix keeps the directory relative, so `cmake --install --prefix` relocates it with the rest of the installation; that includes /opt/<name>, whose /etc/opt/<name> no session manager reads.
# 装在 /opt/<package> 下的版本，GNUInstallDirs 给的系统配置目录是 /etc/opt/<package>，会话管理器不读那里，所以自启动项同样装进 /etc/xdg/autostart。
if(CMAKE_INSTALL_FULL_SYSCONFDIR STREQUAL "/etc" OR LINGYAO_EDITION_SYSTEM_PATHS)
  set(LINGYAO_XDG_AUTOSTART_DIR "/etc/xdg/autostart")
else()
  set(LINGYAO_XDG_AUTOSTART_DIR "${CMAKE_INSTALL_SYSCONFDIR}/xdg/autostart")
endif()
lingyao_edition_source(LINGYAO_UNINSTALL_SOURCE cmake/uninstall.cmake.in)
configure_file("${LINGYAO_UNINSTALL_SOURCE}" ${CMAKE_CURRENT_BINARY_DIR}/uninstall.cmake @ONLY)
# Configured for every build, not only packaging ones, so the gate's ctest exercises the scripts the .deb ships; packaging.cmake hands them to CPack.
foreach(LINGYAO_DEB_SCRIPT prerm postinst)
  lingyao_edition_source(LINGYAO_DEB_SCRIPT_SOURCE cmake/deb-${LINGYAO_DEB_SCRIPT}.in)
  configure_file("${LINGYAO_DEB_SCRIPT_SOURCE}" ${CMAKE_CURRENT_BINARY_DIR}/debian/${LINGYAO_DEB_SCRIPT} @ONLY
                 FILE_PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE)
endforeach()
add_custom_target(uninstall
  COMMAND "${CMAKE_COMMAND}" -P "${CMAKE_CURRENT_BINARY_DIR}/uninstall.cmake"
  COMMENT "Remove installed LINGYAO files while preserving runtime configuration")
include(CTest)
if(BUILD_TESTING)
  find_package(Python3 COMPONENTS Interpreter REQUIRED)
  add_test(NAME linux-fcitx5-contract
           COMMAND "${Python3_EXECUTABLE}" "${CMAKE_CURRENT_SOURCE_DIR}/tests/core/fcitx5_contract.py")
endif()
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
find_package(PkgConfig REQUIRED)
include_directories("${CMAKE_CURRENT_SOURCE_DIR}/src/core" "${CMAKE_CURRENT_SOURCE_DIR}/src/candidates" "${CMAKE_CURRENT_SOURCE_DIR}/src/clipboard" "${CMAKE_CURRENT_SOURCE_DIR}/src/providers" "${CMAKE_CURRENT_SOURCE_DIR}/src/voice" "${CMAKE_CURRENT_SOURCE_DIR}/src/overlay" "${CMAKE_CURRENT_SOURCE_DIR}/src/system" "${CMAKE_CURRENT_SOURCE_DIR}/src/entrypoints")
pkg_check_modules(IBUS REQUIRED IMPORTED_TARGET ibus-1.0>=1.5.20)
pkg_check_modules(XKBCOMMON REQUIRED IMPORTED_TARGET xkbcommon)
find_package(nlohmann_json 3.11 REQUIRED)
# Optional on Wayland-only systems; the monitor retains bounded polling.
pkg_check_modules(X11_CLIPBOARD QUIET IMPORTED_TARGET x11 xfixes)
# The voice overlay enumerates monitors with RandR 1.5 to follow the focused window; libXrandr ships with every X desktop that has libXfixes.
pkg_check_modules(X11_SURFACE QUIET IMPORTED_TARGET x11 xfixes xrandr)
pkg_check_modules(WAYLAND_CLIENT QUIET IMPORTED_TARGET wayland-client)
pkg_check_modules(WAYLAND_TEXT QUIET IMPORTED_TARGET pangocairo)
find_program(WAYLAND_SCANNER_EXECUTABLE wayland-scanner)
if(WAYLAND_CLIENT_FOUND AND WAYLAND_SCANNER_EXECUTABLE)
  enable_language(C)
  set(LINGYAO_WAYLAND_PROTOCOL_DIR "${CMAKE_CURRENT_BINARY_DIR}/wayland-protocols")
  set(LINGYAO_LAYER_SHELL_HEADER
      "${LINGYAO_WAYLAND_PROTOCOL_DIR}/wlr-layer-shell-unstable-v1-client-protocol.h")
  set(LINGYAO_LAYER_SHELL_CODE
      "${LINGYAO_WAYLAND_PROTOCOL_DIR}/wlr-layer-shell-unstable-v1-protocol.c")
  # wayland-protocols 的 .pc 给出它的数据目录；只搜 /usr/share 的话，装在别处的（例如 Nix store）
  # 找不到，Wayland 浮层被静默跳过。原有路径留作没有 .pc 时的退路。
  pkg_get_variable(LINGYAO_WAYLAND_PROTOCOLS_DIR wayland-protocols pkgdatadir)
  find_path(LINGYAO_XDG_SHELL_DIR NAMES xdg-shell.xml
            HINTS "${LINGYAO_WAYLAND_PROTOCOLS_DIR}/stable/xdg-shell"
            PATHS /usr/share/wayland-protocols/stable/xdg-shell
                  /usr/local/share/wayland-protocols/stable/xdg-shell)
  set(LINGYAO_XDG_SHELL_XML "${LINGYAO_XDG_SHELL_DIR}/xdg-shell.xml")
  set(LINGYAO_XDG_SHELL_HEADER
      "${LINGYAO_WAYLAND_PROTOCOL_DIR}/xdg-shell-client-protocol.h")
  set(LINGYAO_XDG_SHELL_CODE
      "${LINGYAO_WAYLAND_PROTOCOL_DIR}/xdg-shell-protocol.c")
  if(NOT EXISTS "${LINGYAO_XDG_SHELL_XML}")
    unset(LINGYAO_XDG_SHELL_XML)
  endif()
  add_custom_command(
    OUTPUT "${LINGYAO_LAYER_SHELL_HEADER}" "${LINGYAO_LAYER_SHELL_CODE}"
    COMMAND "${CMAKE_COMMAND}" -E make_directory "${LINGYAO_WAYLAND_PROTOCOL_DIR}"
    COMMAND "${WAYLAND_SCANNER_EXECUTABLE}" client-header
            "${CMAKE_CURRENT_SOURCE_DIR}/data/wayland/wlr-layer-shell-unstable-v1.xml"
            "${LINGYAO_LAYER_SHELL_HEADER}"
    COMMAND "${WAYLAND_SCANNER_EXECUTABLE}" private-code
            "${CMAKE_CURRENT_SOURCE_DIR}/data/wayland/wlr-layer-shell-unstable-v1.xml"
            "${LINGYAO_LAYER_SHELL_CODE}"
    DEPENDS data/wayland/wlr-layer-shell-unstable-v1.xml)
  if(LINGYAO_XDG_SHELL_XML)
    add_custom_command(
      OUTPUT "${LINGYAO_XDG_SHELL_HEADER}" "${LINGYAO_XDG_SHELL_CODE}"
      COMMAND "${CMAKE_COMMAND}" -E make_directory "${LINGYAO_WAYLAND_PROTOCOL_DIR}"
      COMMAND "${WAYLAND_SCANNER_EXECUTABLE}" client-header
              "${LINGYAO_XDG_SHELL_XML}" "${LINGYAO_XDG_SHELL_HEADER}"
      COMMAND "${WAYLAND_SCANNER_EXECUTABLE}" private-code
              "${LINGYAO_XDG_SHELL_XML}" "${LINGYAO_XDG_SHELL_CODE}"
      DEPENDS "${LINGYAO_XDG_SHELL_XML}")
  endif()
endif()
if(X11_CLIPBOARD_FOUND)
  add_executable(lingyao-linux-clipboard-watch-x11 src/clipboard/clipboard_watch_x11.cpp)
  target_compile_options(lingyao-linux-clipboard-watch-x11 PRIVATE -Wall -Wextra -Werror)
  target_link_libraries(lingyao-linux-clipboard-watch-x11 PRIVATE PkgConfig::X11_CLIPBOARD)
  install(TARGETS lingyao-linux-clipboard-watch-x11 RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}" COMPONENT clipboard-watch)
  if(BUILD_TESTING)
    add_executable(lingyao-test-x11-string-owner tests/clipboard/clipboard_x11_string_owner.cpp)
    target_compile_options(lingyao-test-x11-string-owner PRIVATE -Wall -Wextra -Werror)
    target_link_libraries(lingyao-test-x11-string-owner PRIVATE PkgConfig::X11_CLIPBOARD)
  endif()
endif()
option(LINGYAO_LINUX_VOICE "Build voice worker test" OFF)
set(LINGYAO_HOST_LIBRARY "${CMAKE_CURRENT_SOURCE_DIR}/../../target/debug/liblingyao_host_api.so" CACHE FILEPATH "Cargo-built Linux host library")
set(LINGYAO_RUNTIME_OPTIONS_FILE "" CACHE FILEPATH "Prepared runtime options")
set(LINGYAO_DESKTOP_BINARY "" CACHE FILEPATH "Cargo-built Tauri desktop binary")
set(LINGYAO_MCP_BINARY "" CACHE FILEPATH "Cargo-built MCP server (lingyao-mcp)")
set(LINGYAO_HANDWRITING_MODEL_DIR "" CACHE PATH "Offline handwriting model with its license, as fetched by scripts/fetch_handwriting_model.py; empty uses target/handwriting-model when it is there")
option(LINGYAO_BUNDLE_HANDWRITING_MODEL "Install the offline handwriting model with its license and require it when packaging; OFF leaves it to the settings app to download on demand" ON)
set(LINGYAO_EMOJI_RESOURCES "" CACHE PATH "Trusted packaged Engine Emoji resource directory")
set(LINGYAO_ENGINE_RESOURCES "" CACHE PATH "Trusted packaged Engine desktop resource directory")
if(NOT EXISTS "${LINGYAO_HOST_LIBRARY}")
  message(FATAL_ERROR "Build lingyao-host-api for Linux first")
endif()
lingyao_edition_host_library(LINGYAO_HOST_LIBRARY)
add_library(lingyao-ibus-host STATIC
  src/core/ClientEngine.cpp src/system/DiagnosticLog.cpp src/system/ChineseTextConversion.cpp src/overlay/WaveOverlayIbusSurface.cpp
  src/overlay/WaveOverlaySurfaceFactory.cpp)
target_compile_options(lingyao-ibus-host PRIVATE -Wall -Wextra -Werror)
target_include_directories(lingyao-ibus-host PUBLIC src src/core src/candidates src/clipboard src/providers src/voice src/overlay src/system src/entrypoints ../../crates/host-api/include)
target_link_libraries(lingyao-ibus-host PUBLIC PkgConfig::IBUS PkgConfig::XKBCOMMON nlohmann_json::nlohmann_json "${LINGYAO_HOST_LIBRARY}")
if(X11_SURFACE_FOUND)
  target_sources(lingyao-ibus-host PRIVATE src/overlay/WaveOverlayX11Surface.cpp)
  target_compile_definitions(lingyao-ibus-host PRIVATE LINGYAO_LINUX_HAS_X11_SURFACE)
  target_link_libraries(lingyao-ibus-host PUBLIC PkgConfig::X11_SURFACE)
endif()
if(WAYLAND_CLIENT_FOUND AND WAYLAND_SCANNER_EXECUTABLE AND LINGYAO_XDG_SHELL_XML)
  target_sources(lingyao-ibus-host PRIVATE src/overlay/WaveOverlayWaylandSurface.cpp
                 "${LINGYAO_LAYER_SHELL_CODE}" ${LINGYAO_XDG_SHELL_CODE})
  target_include_directories(lingyao-ibus-host PRIVATE "${LINGYAO_WAYLAND_PROTOCOL_DIR}")
  target_compile_definitions(lingyao-ibus-host PRIVATE LINGYAO_LINUX_HAS_WAYLAND_SURFACE)
  target_link_libraries(lingyao-ibus-host PUBLIC PkgConfig::WAYLAND_CLIENT)
  if(WAYLAND_TEXT_FOUND)
    target_compile_definitions(lingyao-ibus-host PRIVATE LINGYAO_LINUX_WAYLAND_TEXT)
    target_link_libraries(lingyao-ibus-host PUBLIC PkgConfig::WAYLAND_TEXT)
  endif()
endif()
# The version the IBus host reports in telemetry, which is also the package version packaging.cmake hands to CPack. Like LINGYAO_WINDOWS_VERSION on Windows it defaults to this platform's version.txt, the file the release workflow reads for the linux-vVERSION tag; package-container.sh passes the release version explicitly.
set(LINGYAO_PACKAGE_VERSION "" CACHE STRING "Package version; empty uses platforms/linux/version.txt")
if(LINGYAO_PACKAGE_VERSION)
  set(LINGYAO_LINUX_VERSION "${LINGYAO_PACKAGE_VERSION}")
else()
  set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/version.txt")
  file(STRINGS "${CMAKE_CURRENT_SOURCE_DIR}/version.txt" LINGYAO_LINUX_VERSION LIMIT_COUNT 1)
  string(STRIP "${LINGYAO_LINUX_VERSION}" LINGYAO_LINUX_VERSION)
endif()
if(NOT LINGYAO_LINUX_VERSION MATCHES "^[0-9]+\\.[0-9]+\\.[0-9]+$")
  message(FATAL_ERROR "The Linux package version must be MAJOR.MINOR.PATCH: ${LINGYAO_LINUX_VERSION}")
endif()
find_package(Threads REQUIRED)
add_executable(lingyao-linux-ibus src/entrypoints/ibus_main.cpp src/system/SystemTheme.cpp)
target_sources(lingyao-linux-ibus PRIVATE ../common/Telemetry.cpp)
target_include_directories(lingyao-linux-ibus PRIVATE ../common)
target_compile_definitions(lingyao-linux-ibus PRIVATE LINGYAO_LINUX_VERSION="${LINGYAO_LINUX_VERSION}")
target_link_libraries(lingyao-linux-ibus PRIVATE Threads::Threads)
target_compile_options(lingyao-linux-ibus PRIVATE -Wall -Wextra -Werror)
target_link_libraries(lingyao-linux-ibus PRIVATE lingyao-ibus-host)
add_executable(lingyao-linux-dictionary src/providers/dictionary_request.cpp)
add_executable(lingyao-linux-prepare src/entrypoints/prepare_host_main.cpp)
target_compile_options(lingyao-linux-prepare PRIVATE -Wall -Wextra -Werror)
target_link_libraries(lingyao-linux-prepare PRIVATE lingyao-ibus-host)
file(RELATIVE_PATH LINGYAO_INSTALLED_RESOURCE_RELATIVE_DIR
     "${CMAKE_INSTALL_FULL_BINDIR}"
     "${CMAKE_INSTALL_FULL_DATADIR}/${LINGYAO_CLIENT_DIRECTORY}/resources")
target_compile_definitions(lingyao-linux-prepare PRIVATE
  LINGYAO_INSTALLED_RESOURCE_RELATIVE_DIR="${LINGYAO_INSTALLED_RESOURCE_RELATIVE_DIR}")
# The IBus engine names the installed built-in sound packs to the Host API, found from its own executable as the prepare tool finds the resources (core/PreparePaths.h).
file(RELATIVE_PATH LINGYAO_INSTALLED_SOUND_PACKS_RELATIVE_DIR
     "${CMAKE_INSTALL_FULL_BINDIR}"
     "${CMAKE_INSTALL_FULL_DATADIR}/${LINGYAO_CLIENT_DIRECTORY}/sound-packs")
target_compile_definitions(lingyao-ibus-host PRIVATE
  LINGYAO_INSTALLED_SOUND_PACKS_RELATIVE_DIR="${LINGYAO_INSTALLED_SOUND_PACKS_RELATIVE_DIR}")
target_compile_options(lingyao-linux-dictionary PRIVATE -Wall -Wextra -Werror)
target_link_libraries(lingyao-linux-dictionary PRIVATE lingyao-ibus-host)
add_executable(lingyao-linux-cloud-dictionary src/providers/cloud_dictionary_request.cpp)
target_compile_options(lingyao-linux-cloud-dictionary PRIVATE -Wall -Wextra -Werror)
target_link_libraries(lingyao-linux-cloud-dictionary PRIVATE lingyao-ibus-host)
add_executable(lingyao-linux-cloud-clipboard src/providers/cloud_clipboard_request.cpp)
target_compile_options(lingyao-linux-cloud-clipboard PRIVATE -Wall -Wextra -Werror)
target_link_libraries(lingyao-linux-cloud-clipboard PRIVATE lingyao-ibus-host)
add_executable(lingyao-linux-online src/providers/online_request.cpp)
target_compile_options(lingyao-linux-online PRIVATE -Wall -Wextra -Werror)
target_link_libraries(lingyao-linux-online PRIVATE lingyao-ibus-host)
add_executable(lingyao-linux-online-provider-contract tests/provider/online_provider_contract.cpp)
target_compile_options(lingyao-linux-online-provider-contract PRIVATE -Wall -Wextra -Werror)
target_include_directories(lingyao-linux-online-provider-contract PRIVATE ../../crates/host-api/include)
target_link_libraries(lingyao-linux-online-provider-contract PRIVATE nlohmann_json::nlohmann_json "${LINGYAO_HOST_LIBRARY}")
add_test(NAME linux-online-provider-contract COMMAND lingyao-linux-online-provider-contract)
add_executable(lingyao-linux-translation src/providers/translation_request.cpp)
target_compile_options(lingyao-linux-translation PRIVATE -Wall -Wextra -Werror)
target_link_libraries(lingyao-linux-translation PRIVATE lingyao-ibus-host)
add_executable(lingyao-linux-clipboard src/clipboard/clipboard_history.cpp)
target_compile_options(lingyao-linux-clipboard PRIVATE -Wall -Wextra -Werror)
target_link_libraries(lingyao-linux-clipboard PRIVATE nlohmann_json::nlohmann_json)
add_executable(linux-clipboard-atomic-write-test tests/clipboard/clipboard_atomic_write.cpp)
target_compile_options(linux-clipboard-atomic-write-test PRIVATE -Wall -Wextra -Werror -UNDEBUG)
target_include_directories(linux-clipboard-atomic-write-test PRIVATE src)
add_test(NAME linux-clipboard-atomic-write COMMAND linux-clipboard-atomic-write-test)
add_executable(lingyao-linux-clipboard-capture src/clipboard/clipboard_capture.cpp)
target_compile_options(lingyao-linux-clipboard-capture PRIVATE -Wall -Wextra -Werror)
target_link_libraries(lingyao-linux-clipboard-capture PRIVATE lingyao-ibus-host)
add_executable(lingyao-linux-handwriting src/providers/handwriting_request.cpp)
target_compile_options(lingyao-linux-handwriting PRIVATE -Wall -Wextra -Werror)
target_link_libraries(lingyao-linux-handwriting PRIVATE lingyao-ibus-host)
add_executable(lingyao-linux-voice src/voice/voice_request.cpp)
target_compile_options(lingyao-linux-voice PRIVATE -Wall -Wextra -Werror)
target_link_libraries(lingyao-linux-voice PRIVATE lingyao-ibus-host)
# On-device recognition for the `local` voice provider: the voice service spawns this helper (scripts/lingyao_voice_local.py) and speaks its JSON-lines protocol, so the model never loads into the service or the input method. It opens the sherpa-onnx runtime with dlopen from its own directory, so it builds without one; LINGYAO_VOICE_RUNTIME_DIR below installs the runtime beside it. Compiled from the shared sources directly because shared/voice/CMakeLists.txt also builds the cloud providers and everything they link.
find_package(Threads REQUIRED)
set(LINGYAO_SHARED_VOICE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../../shared/voice")
add_executable(lingyao-voice-local "${LINGYAO_SHARED_VOICE_DIR}/LocalAsrHelper.cpp" "${LINGYAO_SHARED_VOICE_DIR}/LocalAsr.cpp")
target_compile_options(lingyao-voice-local PRIVATE -Wall -Wextra -Werror)
target_include_directories(lingyao-voice-local PRIVATE "${LINGYAO_SHARED_VOICE_DIR}" "${LINGYAO_SHARED_VOICE_DIR}/third_party")
target_link_libraries(lingyao-voice-local PRIVATE nlohmann_json::nlohmann_json Threads::Threads ${CMAKE_DL_LIBS})
add_executable(lingyao-linux-emoji src/providers/emoji_request.cpp)
target_compile_options(lingyao-linux-emoji PRIVATE -Wall -Wextra -Werror)
target_link_libraries(lingyao-linux-emoji PRIVATE lingyao-ibus-host)
add_executable(ibus-engine-smoke tests/runtime/engine_smoke.cpp)
target_compile_options(ibus-engine-smoke PRIVATE -Wall -Wextra -Werror)
target_link_libraries(ibus-engine-smoke PRIVATE lingyao-ibus-host)
# The Zhuyin and Stroke cases install these dictionaries into a directory of their own; the locked resources carry none.
target_compile_definitions(ibus-engine-smoke PRIVATE
  LINGYAO_ZHUYIN_DICTIONARY_FIXTURE="${CMAKE_CURRENT_SOURCE_DIR}/tests/runtime/zhuyin_dictionary.py"
  LINGYAO_STROKE_DICTIONARY_FIXTURE="${CMAKE_CURRENT_SOURCE_DIR}/tests/runtime/stroke_dictionary.py")
if(BUILD_TESTING AND LINGYAO_ENGINE_RESOURCES)
  add_test(NAME ibus-page-number-visibility
    COMMAND ibus-engine-smoke "${LINGYAO_ENGINE_RESOURCES}" --page-number)
  set_tests_properties(ibus-page-number-visibility PROPERTIES TIMEOUT 60)
endif()
add_executable(linux-navigation-bindings-test tests/input/navigation_bindings.cpp)
target_compile_options(linux-navigation-bindings-test PRIVATE -Wall -Wextra -Werror)
target_include_directories(linux-navigation-bindings-test PRIVATE src ../../crates/host-api/include)
target_link_libraries(linux-navigation-bindings-test PRIVATE PkgConfig::IBUS)
add_test(NAME linux-navigation-bindings COMMAND linux-navigation-bindings-test)
add_executable(linux-spelling-symbols-test tests/input/spelling_symbols.cpp)
target_compile_options(linux-spelling-symbols-test PRIVATE -Wall -Wextra -Werror -UNDEBUG)
target_include_directories(linux-spelling-symbols-test PRIVATE src)
target_link_libraries(linux-spelling-symbols-test PRIVATE nlohmann_json::nlohmann_json)
add_test(NAME linux-spelling-symbols COMMAND linux-spelling-symbols-test)
add_executable(linux-input-schemes-test tests/input/input_schemes.cpp)
target_compile_options(linux-input-schemes-test PRIVATE -Wall -Wextra -Werror -UNDEBUG)
target_include_directories(linux-input-schemes-test PRIVATE src)
target_link_libraries(linux-input-schemes-test PRIVATE nlohmann_json::nlohmann_json)
add_test(NAME linux-input-schemes COMMAND linux-input-schemes-test)
add_executable(linux-korean-hanja-test tests/input/korean_hanja.cpp)
target_compile_options(linux-korean-hanja-test PRIVATE -Wall -Wextra -Werror -UNDEBUG)
target_include_directories(linux-korean-hanja-test PRIVATE src)
target_link_libraries(linux-korean-hanja-test PRIVATE nlohmann_json::nlohmann_json PkgConfig::IBUS)
add_test(NAME linux-korean-hanja COMMAND linux-korean-hanja-test)
add_executable(linux-key-sound-test tests/input/key_sound.cpp)
target_compile_options(linux-key-sound-test PRIVATE -Wall -Wextra -Werror -UNDEBUG)
target_include_directories(linux-key-sound-test PRIVATE src)
add_test(NAME linux-key-sound COMMAND linux-key-sound-test)
add_executable(linux-client-input-mode-memory-test tests/input/client_input_mode_memory.cpp)
target_compile_options(linux-client-input-mode-memory-test PRIVATE -Wall -Wextra -Werror)
target_include_directories(linux-client-input-mode-memory-test PRIVATE src)
add_test(NAME linux-client-input-mode-memory COMMAND linux-client-input-mode-memory-test)
add_executable(linux-shuangpin-profile-names-test tests/input/shuangpin_profile_names.cpp)
target_compile_options(linux-shuangpin-profile-names-test PRIVATE -Wall -Wextra -Werror)
target_include_directories(linux-shuangpin-profile-names-test PRIVATE src)
add_test(NAME linux-shuangpin-profile-names COMMAND linux-shuangpin-profile-names-test)
add_executable(linux-wubi-profile-names-test tests/input/wubi_profile_names.cpp)
target_compile_options(linux-wubi-profile-names-test PRIVATE -Wall -Wextra -Werror -UNDEBUG)
target_include_directories(linux-wubi-profile-names-test PRIVATE src)
add_test(NAME linux-wubi-profile-names COMMAND linux-wubi-profile-names-test)
add_executable(linux-candidate-palette-test tests/candidate/candidate_palette.cpp)
target_compile_options(linux-candidate-palette-test PRIVATE -Wall -Wextra -Werror)
target_include_directories(linux-candidate-palette-test PRIVATE src)
target_link_libraries(linux-candidate-palette-test PRIVATE nlohmann_json::nlohmann_json)
add_test(NAME linux-candidate-palette COMMAND linux-candidate-palette-test)
add_executable(linux-candidate-fcitx-theme-test tests/candidate/candidate_fcitx_theme.cpp)
target_compile_options(linux-candidate-fcitx-theme-test PRIVATE -Wall -Wextra -Werror)
target_include_directories(linux-candidate-fcitx-theme-test PRIVATE src)
target_link_libraries(linux-candidate-fcitx-theme-test PRIVATE nlohmann_json::nlohmann_json)
add_test(NAME linux-candidate-fcitx-theme COMMAND linux-candidate-fcitx-theme-test)
add_executable(linux-candidate-font-policy-test tests/candidate/candidate_font_policy.cpp)
target_compile_options(linux-candidate-font-policy-test PRIVATE -Wall -Wextra -Werror)
target_include_directories(linux-candidate-font-policy-test PRIVATE src)
target_link_libraries(linux-candidate-font-policy-test PRIVATE nlohmann_json::nlohmann_json)
add_test(NAME linux-candidate-font-policy COMMAND linux-candidate-font-policy-test)
add_executable(linux-candidate-wheel-paging-test tests/candidate/candidate_wheel_paging.cpp)
target_compile_options(linux-candidate-wheel-paging-test PRIVATE -Wall -Wextra -Werror)
target_include_directories(linux-candidate-wheel-paging-test PRIVATE src)
target_link_libraries(linux-candidate-wheel-paging-test PRIVATE nlohmann_json::nlohmann_json)
add_test(NAME linux-candidate-wheel-paging COMMAND linux-candidate-wheel-paging-test)
add_executable(linux-panel-restore-record-test tests/candidate/panel_restore_record.cpp)
target_compile_options(linux-panel-restore-record-test PRIVATE -Wall -Wextra -Werror -UNDEBUG)
target_include_directories(linux-panel-restore-record-test PRIVATE src)
target_link_libraries(linux-panel-restore-record-test PRIVATE nlohmann_json::nlohmann_json)
add_test(NAME linux-panel-restore-record COMMAND linux-panel-restore-record-test)
add_executable(linux-candidate-action-policy-test tests/candidate/candidate_action_policy.cpp)
target_compile_options(linux-candidate-action-policy-test PRIVATE -Wall -Wextra -Werror)
target_include_directories(linux-candidate-action-policy-test PRIVATE src)
add_test(NAME linux-candidate-action-policy COMMAND linux-candidate-action-policy-test)
add_executable(linux-candidate-local-mode-labels-test tests/candidate/candidate_local_mode_labels.cpp)
target_compile_options(linux-candidate-local-mode-labels-test PRIVATE -Wall -Wextra -Werror)
target_include_directories(linux-candidate-local-mode-labels-test PRIVATE src)
add_test(NAME linux-candidate-local-mode-labels COMMAND linux-candidate-local-mode-labels-test)
add_executable(linux-candidate-panel-status-test tests/candidate/candidate_panel_status.cpp)
target_compile_options(linux-candidate-panel-status-test PRIVATE -Wall -Wextra -Werror)
target_include_directories(linux-candidate-panel-status-test PRIVATE src)
add_test(NAME linux-candidate-panel-status COMMAND linux-candidate-panel-status-test)
add_executable(linux-input-status-test tests/core/input_status.cpp)
target_compile_options(linux-input-status-test PRIVATE -Wall -Wextra -Werror)
target_include_directories(linux-input-status-test PRIVATE src)
target_link_libraries(linux-input-status-test PRIVATE nlohmann_json::nlohmann_json)
add_test(NAME linux-input-status COMMAND linux-input-status-test)
add_executable(linux-json-integer-test tests/core/json_integer.cpp)
target_compile_options(linux-json-integer-test PRIVATE -Wall -Wextra -Werror -UNDEBUG)
target_include_directories(linux-json-integer-test PRIVATE src)
target_link_libraries(linux-json-integer-test PRIVATE nlohmann_json::nlohmann_json)
add_test(NAME linux-json-integer COMMAND linux-json-integer-test)
add_executable(linux-candidate-translation-policy-test tests/candidate/candidate_translation_policy.cpp)
target_compile_options(linux-candidate-translation-policy-test PRIVATE -Wall -Wextra -Werror)
target_include_directories(linux-candidate-translation-policy-test PRIVATE src)
add_test(NAME linux-candidate-translation-policy COMMAND linux-candidate-translation-policy-test)
add_executable(linux-paired-punctuation-test tests/input/paired_punctuation.cpp)
target_compile_options(linux-paired-punctuation-test PRIVATE -Wall -Wextra -Werror)
target_include_directories(linux-paired-punctuation-test PRIVATE src)
add_test(NAME linux-paired-punctuation COMMAND linux-paired-punctuation-test)
add_executable(linux-dictionary-quiesce-lease-test tests/core/dictionary_quiesce_lease.cpp)
target_compile_options(linux-dictionary-quiesce-lease-test PRIVATE -Wall -Wextra -Werror)
target_include_directories(linux-dictionary-quiesce-lease-test PRIVATE src)
add_test(NAME linux-dictionary-quiesce-lease COMMAND linux-dictionary-quiesce-lease-test)
add_executable(linux-emoji-plugin-groups-test tests/core/emoji_plugin_groups.cpp)
target_compile_options(linux-emoji-plugin-groups-test PRIVATE -Wall -Wextra -Werror -UNDEBUG)
target_include_directories(linux-emoji-plugin-groups-test PRIVATE src)
target_link_libraries(linux-emoji-plugin-groups-test PRIVATE nlohmann_json::nlohmann_json)
add_test(NAME linux-emoji-plugin-groups COMMAND linux-emoji-plugin-groups-test)
add_executable(common-dictionary-quiesce-lease-test ../common/tests/dictionary_quiesce_lease.cpp)
target_compile_options(common-dictionary-quiesce-lease-test PRIVATE -Wall -Wextra -Werror)
add_test(NAME common-dictionary-quiesce-lease COMMAND common-dictionary-quiesce-lease-test)
add_executable(common-telemetry-test ../common/tests/telemetry.cpp ../common/Telemetry.cpp)
target_compile_options(common-telemetry-test PRIVATE -Wall -Wextra -Werror -UNDEBUG)
target_include_directories(common-telemetry-test PRIVATE ../common ../../crates/host-api/include)
target_link_libraries(common-telemetry-test PRIVATE nlohmann_json::nlohmann_json "${LINGYAO_HOST_LIBRARY}" Threads::Threads)
add_test(NAME common-telemetry COMMAND common-telemetry-test)
add_executable(linux-input-mode-indicator-test tests/core/input_mode_indicator.cpp)
target_compile_options(linux-input-mode-indicator-test PRIVATE -Wall -Wextra -Werror)
target_include_directories(linux-input-mode-indicator-test PRIVATE src)
add_test(NAME linux-input-mode-indicator COMMAND linux-input-mode-indicator-test)
add_executable(linux-voice-provider-options-test tests/voice/voice_provider_options.cpp)
target_compile_options(linux-voice-provider-options-test PRIVATE -Wall -Wextra -Werror)
target_include_directories(linux-voice-provider-options-test PRIVATE src)
target_link_libraries(linux-voice-provider-options-test PRIVATE nlohmann_json::nlohmann_json)
add_test(NAME linux-voice-provider-options COMMAND linux-voice-provider-options-test)
add_executable(linux-prepare-paths-test tests/core/prepare_paths.cpp)
target_compile_options(linux-prepare-paths-test PRIVATE -Wall -Wextra -Werror)
target_include_directories(linux-prepare-paths-test PRIVATE src)
add_test(NAME linux-prepare-paths COMMAND linux-prepare-paths-test)
add_executable(linux-safe-path-test tests/core/safe_path.cpp)
target_compile_options(linux-safe-path-test PRIVATE -Wall -Wextra -Werror -UNDEBUG)
target_include_directories(linux-safe-path-test PRIVATE src)
add_test(NAME linux-safe-path COMMAND linux-safe-path-test)
add_executable(linux-key-router-adapter-test tests/input/key_router_adapter.cpp)
target_compile_options(linux-key-router-adapter-test PRIVATE -Wall -Wextra -Werror)
target_include_directories(linux-key-router-adapter-test PRIVATE src ../../crates/host-api/include)
add_test(NAME linux-key-router-adapter COMMAND linux-key-router-adapter-test)
add_executable(linux-backspace-hold-policy-test tests/input/backspace_hold_policy.cpp)
target_compile_options(linux-backspace-hold-policy-test PRIVATE -Wall -Wextra -Werror)
target_include_directories(linux-backspace-hold-policy-test PRIVATE src)
add_test(NAME linux-backspace-hold-policy COMMAND linux-backspace-hold-policy-test)
add_executable(linux-diagnostic-log-test tests/core/diagnostic_log.cpp)
target_compile_options(linux-diagnostic-log-test PRIVATE -Wall -Wextra -Werror)
target_include_directories(linux-diagnostic-log-test PRIVATE src)
target_sources(linux-diagnostic-log-test PRIVATE src/system/DiagnosticLog.cpp)
add_test(NAME linux-diagnostic-log COMMAND linux-diagnostic-log-test)
add_executable(linux-surrounding-characters-test tests/core/surrounding_characters.cpp)
target_compile_options(linux-surrounding-characters-test PRIVATE -Wall -Wextra -Werror)
target_include_directories(linux-surrounding-characters-test PRIVATE src)
target_link_libraries(linux-surrounding-characters-test PRIVATE PkgConfig::IBUS)
add_test(NAME linux-surrounding-characters COMMAND linux-surrounding-characters-test)
# The composition both front ends draw while a phrase is being assembled: the piece already picked
# leads the reading, and the caret has to move past it in the unit each toolkit counts in - bytes
# for fcitx5, Unicode scalars for IBus.
# Space converts and Enter takes what is on screen: the decision both front ends share, and the
# reason the Engine's raw-input command cannot be what Enter sends in Japanese.
add_executable(linux-japanese-conversion-test tests/core/japanese_conversion.cpp)
target_compile_options(linux-japanese-conversion-test PRIVATE -Wall -Wextra -Werror -UNDEBUG)
target_include_directories(linux-japanese-conversion-test PRIVATE src)
add_test(NAME linux-japanese-conversion COMMAND linux-japanese-conversion-test)
# One table for the two menus over one setting, because they disagreed: 首右 had been written as
# 搜狗, which names a different company's input method.
add_executable(linux-helpcode-schema-names-test tests/core/helpcode_schema_names.cpp)
target_compile_options(linux-helpcode-schema-names-test PRIVATE -Wall -Wextra -Werror -UNDEBUG)
target_include_directories(linux-helpcode-schema-names-test PRIVATE src)
add_test(NAME linux-helpcode-schema-names COMMAND linux-helpcode-schema-names-test)
add_executable(linux-phrase-preedit-test tests/core/phrase_preedit.cpp)
target_compile_options(linux-phrase-preedit-test PRIVATE -Wall -Wextra -Werror -UNDEBUG)
target_include_directories(linux-phrase-preedit-test PRIVATE src)
add_test(NAME linux-phrase-preedit COMMAND linux-phrase-preedit-test)
add_executable(linux-replaced-program-test tests/core/replaced_program.cpp)
target_compile_options(linux-replaced-program-test PRIVATE -Wall -Wextra -Werror -UNDEBUG)
target_include_directories(linux-replaced-program-test PRIVATE src)
add_test(NAME linux-replaced-program COMMAND linux-replaced-program-test)
add_executable(linux-smart-punctuation-space-test tests/core/smart_punctuation_space.cpp)
target_compile_options(linux-smart-punctuation-space-test PRIVATE -Wall -Wextra -Werror)
target_include_directories(linux-smart-punctuation-space-test PRIVATE src)
add_test(NAME linux-smart-punctuation-space COMMAND linux-smart-punctuation-space-test)
add_test(NAME linux-setup-resolution
         COMMAND "${Python3_EXECUTABLE}" "${CMAKE_CURRENT_SOURCE_DIR}/tests/core/setup_resolution.py")
add_test(NAME linux-setup-update
         COMMAND "${Python3_EXECUTABLE}" "${CMAKE_CURRENT_SOURCE_DIR}/tests/core/setup_update.py"
                 $<TARGET_FILE:lingyao-linux-prepare>)
add_test(NAME linux-setup-registration
         COMMAND "${Python3_EXECUTABLE}" "${CMAKE_CURRENT_SOURCE_DIR}/tests/core/setup_registration.py")
add_test(NAME linux-setup-omarchy
         COMMAND "${Python3_EXECUTABLE}" "${CMAKE_CURRENT_SOURCE_DIR}/tests/core/setup_omarchy.py")
add_test(NAME linux-setup-panel-restore
         COMMAND "${Python3_EXECUTABLE}" "${CMAKE_CURRENT_SOURCE_DIR}/tests/core/setup_panel_restore.py")
add_test(NAME linux-first-run-guide
         COMMAND "${Python3_EXECUTABLE}" "${CMAKE_CURRENT_SOURCE_DIR}/tests/core/first_run_guide.py")
add_test(NAME linux-settings-launcher-contract
         COMMAND "${Python3_EXECUTABLE}" "${CMAKE_CURRENT_SOURCE_DIR}/tests/core/settings_launcher_contract.py")
add_test(NAME linux-deb-maintainer-scripts
         COMMAND "${Python3_EXECUTABLE}" "${CMAKE_CURRENT_SOURCE_DIR}/tests/core/deb_maintainer_scripts.py"
                 "${CMAKE_CURRENT_BINARY_DIR}/debian" "${CMAKE_CURRENT_BINARY_DIR}/uninstall.cmake" "${LINGYAO_USER_UNIT_LIST}"
                 "${CMAKE_INSTALL_FULL_BINDIR}/${LINGYAO_EDITION_PACKAGE}-setup")
add_test(NAME linux-uninstall-unregister
         COMMAND "${Python3_EXECUTABLE}" "${CMAKE_CURRENT_SOURCE_DIR}/tests/core/uninstall_unregister.py"
                 "${CMAKE_COMMAND}" "${CMAKE_CURRENT_BINARY_DIR}/uninstall.cmake")
add_test(NAME linux-clipboard-autostart
         COMMAND "${Python3_EXECUTABLE}" "${CMAKE_CURRENT_SOURCE_DIR}/tests/core/clipboard_autostart.py"
                 "${CMAKE_COMMAND}" "${CMAKE_CURRENT_BINARY_DIR}" "${LINGYAO_XDG_AUTOSTART_DIR}" "${CMAKE_CURRENT_BINARY_DIR}/uninstall.cmake")
add_test(NAME linux-ibus-launcher-supervisor
         COMMAND "${Python3_EXECUTABLE}" "${CMAKE_CURRENT_SOURCE_DIR}/tests/core/ibus_launcher_supervisor.py")
add_executable(linux-ibus-registration-bus tests/core/ibus_registration_bus.cpp)
target_compile_options(linux-ibus-registration-bus PRIVATE -Wall -Wextra -Werror)
target_link_libraries(linux-ibus-registration-bus PRIVATE PkgConfig::IBUS)
add_test(NAME linux-ibus-startup-telemetry
         COMMAND "${Python3_EXECUTABLE}" "${CMAKE_CURRENT_SOURCE_DIR}/tests/core/ibus_startup_telemetry.py"
                 $<TARGET_FILE:lingyao-linux-ibus> $<TARGET_FILE:linux-ibus-registration-bus> "${LINGYAO_LINUX_VERSION}")
set_tests_properties(linux-ibus-startup-telemetry PROPERTIES TIMEOUT 60 SKIP_RETURN_CODE 77)
add_test(NAME linux-voice-provider-degraded-start
         COMMAND "${Python3_EXECUTABLE}" "${CMAKE_CURRENT_SOURCE_DIR}/tests/voice/provider_degraded_start.py")
add_test(NAME linux-voice-local-stream
         COMMAND "${Python3_EXECUTABLE}" "${CMAKE_CURRENT_SOURCE_DIR}/tests/voice/local_stream.py")
add_test(NAME linux-voice-provider-local
         COMMAND "${Python3_EXECUTABLE}" "${CMAKE_CURRENT_SOURCE_DIR}/tests/voice/provider_local.py"
                 $<TARGET_FILE:lingyao-voice-local>)
set_tests_properties(linux-voice-local-stream linux-voice-provider-local PROPERTIES TIMEOUT 120)
add_test(NAME linux-voice-command-bounds
         COMMAND "${Python3_EXECUTABLE}" "${CMAKE_CURRENT_SOURCE_DIR}/tests/voice/voice_command_bounds.py")
add_test(NAME linux-voice-capture-device
         COMMAND "${Python3_EXECUTABLE}" "${CMAKE_CURRENT_SOURCE_DIR}/tests/voice/capture_device_contract.py")
add_test(NAME linux-clipboard-tool-parity
         COMMAND "${Python3_EXECUTABLE}" "${CMAKE_CURRENT_SOURCE_DIR}/tests/clipboard/clipboard_tool_parity.py"
                 $<TARGET_FILE:lingyao-linux-clipboard>)
add_executable(linux-first-run-guidance-test tests/core/first_run_guidance.cpp)
target_compile_options(linux-first-run-guidance-test PRIVATE -Wall -Wextra -Werror -UNDEBUG)
target_include_directories(linux-first-run-guidance-test PRIVATE src)
add_test(NAME linux-first-run-guidance COMMAND linux-first-run-guidance-test)
add_executable(linux-candidate-skin-catalog-test tests/core/candidate_skin_catalog.cpp)
target_compile_options(linux-candidate-skin-catalog-test PRIVATE -Wall -Wextra -Werror)
target_include_directories(linux-candidate-skin-catalog-test PRIVATE src)
target_link_libraries(linux-candidate-skin-catalog-test PRIVATE nlohmann_json::nlohmann_json)
add_test(NAME linux-candidate-skin-catalog COMMAND linux-candidate-skin-catalog-test)
add_executable(linux-typing-statistics-test tests/core/typing_statistics.cpp)
target_compile_options(linux-typing-statistics-test PRIVATE -Wall -Wextra -Werror)
target_include_directories(linux-typing-statistics-test PRIVATE src ../../crates/host-api/include)
target_link_libraries(linux-typing-statistics-test PRIVATE "${LINGYAO_HOST_LIBRARY}")
add_test(NAME linux-typing-statistics COMMAND linux-typing-statistics-test)
add_executable(linux-panel-input-channel-test tests/core/panel_input_channel.cpp)
target_compile_options(linux-panel-input-channel-test PRIVATE -Wall -Wextra -Werror)
target_include_directories(linux-panel-input-channel-test PRIVATE src src/system)
target_link_libraries(linux-panel-input-channel-test PRIVATE nlohmann_json::nlohmann_json)
add_test(NAME linux-panel-input-channel COMMAND linux-panel-input-channel-test)
add_executable(linux-traditional-output-test tests/input/traditional_output.cpp src/system/ChineseTextConversion.cpp)
target_compile_options(linux-traditional-output-test PRIVATE -Wall -Wextra -Werror)
target_include_directories(linux-traditional-output-test PRIVATE src ../../crates/host-api/include)
target_link_libraries(linux-traditional-output-test PRIVATE "${LINGYAO_HOST_LIBRARY}")
add_test(NAME linux-traditional-output COMMAND linux-traditional-output-test)
if(LINGYAO_LINUX_VOICE)
 add_executable(lingyao-voice-worker-test tests/voice/voice_worker.cpp)
 target_compile_options(lingyao-voice-worker-test PRIVATE -Wall -Wextra -Werror)
 target_include_directories(lingyao-voice-worker-test PRIVATE src)
 add_test(NAME linux-voice-worker COMMAND lingyao-voice-worker-test)
endif()
# IBus 组件文件以版本的包名命名，组件名和引擎名也随版本（full 仍是 lingyao-linux.xml）。
lingyao_edition_source(LINGYAO_IBUS_COMPONENT_SOURCE data/lingyao-linux.xml.in)
configure_file("${LINGYAO_IBUS_COMPONENT_SOURCE}" ${CMAKE_CURRENT_BINARY_DIR}/${LINGYAO_EDITION_PACKAGE}.xml @ONLY)
install(TARGETS lingyao-linux-ibus lingyao-linux-dictionary lingyao-linux-cloud-dictionary lingyao-linux-cloud-clipboard lingyao-linux-online lingyao-linux-translation lingyao-linux-clipboard
                lingyao-linux-handwriting lingyao-linux-voice lingyao-linux-emoji lingyao-linux-clipboard-capture lingyao-linux-prepare
                RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}")
if(LINGYAO_LINUX_VOICE)
 install(TARGETS lingyao-voice-worker-test RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}")
endif()
# 带着每用户目录名、单元名或命令名的脚本按版本改写（full 原样安装）；其余脚本只按自己的目录找同级程序，各版本相同。
foreach(LINGYAO_EDITION_SCRIPT lingyao-linux-ibus-launcher lingyao-linux-first-run-guide lingyao-linux-online-provider lingyao-linux-provider-session)
  lingyao_edition_source(LINGYAO_EDITION_SCRIPT_SOURCE scripts/${LINGYAO_EDITION_SCRIPT})
  install(PROGRAMS "${LINGYAO_EDITION_SCRIPT_SOURCE}" DESTINATION "${CMAKE_INSTALL_BINDIR}")
endforeach()
install(PROGRAMS scripts/lingyao-linux-voice-provider DESTINATION "${CMAKE_INSTALL_BINDIR}")
install(PROGRAMS scripts/lingyao-linux-clipboard-monitor DESTINATION "${CMAKE_INSTALL_BINDIR}")
# 安装后的首次配置入口。词库与状态目录此前没有任何产品侧的路径：词库要么在配置阶段随包装好，要么只能在仓库检出里跑一个 Cargo 示例去取，于是只拿到安装包的用户凑不齐词库，而没有词库一个候选都出不来。词库锁无条件随装，它是这个入口据以校验和取回的依据——它此前只在 LINGYAO_ENGINE_RESOURCES 存在时才安装，也就是最需要它的那种安装里反而没有。
# 命令名以版本的包名开头（full 仍是 lingyao-linux-setup）；随装的词库锁是本版本的锁（full 是 desktop-dictionary.lock.json 本身，其他版本是 resources/editions/<id>.lock.json），装成同一个文件名，lingyao-linux-setup 据它校验和取回本版本的词库。
lingyao_edition_source(LINGYAO_SETUP_SOURCE scripts/lingyao-linux-setup)
install(PROGRAMS "${LINGYAO_SETUP_SOURCE}" DESTINATION "${CMAKE_INSTALL_BINDIR}" RENAME ${LINGYAO_EDITION_PACKAGE}-setup)
if(NOT LINGYAO_ENGINE_RESOURCES)
  install(FILES "${LINGYAO_EDITION_RESOURCE_LOCK}"
          DESTINATION "${CMAKE_INSTALL_DATADIR}/${LINGYAO_CLIENT_DIRECTORY}" RENAME desktop-dictionary.lock.json)
endif()
set(LINGYAO_SYSTEMD_USER_UNIT_DIR "${LINGYAO_SYSTEM_DATADIR}/systemd/user" CACHE PATH "systemd user unit installation directory")
foreach(LINGYAO_PROVIDER online voice clipboard)
  lingyao_edition_source(LINGYAO_UNIT_SOURCE data/lingyao-linux-${LINGYAO_PROVIDER}.service.in)
  configure_file("${LINGYAO_UNIT_SOURCE}"
                 ${CMAKE_CURRENT_BINARY_DIR}/${LINGYAO_EDITION_PACKAGE}-${LINGYAO_PROVIDER}.service @ONLY)
  install(FILES ${CMAKE_CURRENT_BINARY_DIR}/${LINGYAO_EDITION_PACKAGE}-${LINGYAO_PROVIDER}.service
          DESTINATION "${LINGYAO_SYSTEMD_USER_UNIT_DIR}")
endforeach()
# Starts the clipboard service at login on sessions without graphical-session.target, for users who enabled it; see the comment in the file. Its own component lets the test install just this file.
lingyao_edition_source(LINGYAO_CLIPBOARD_AUTOSTART_SOURCE data/lingyao-linux-clipboard.desktop)
install(FILES "${LINGYAO_CLIPBOARD_AUTOSTART_SOURCE}" DESTINATION "${LINGYAO_XDG_AUTOSTART_DIR}"
        RENAME ${LINGYAO_EDITION_PACKAGE}-clipboard.desktop COMPONENT clipboard-autostart)
# Socket units keep the provider paths present from login, so the input method and the panels find the services the way the Windows server is simply there; systemd starts a provider on its first request.
foreach(LINGYAO_PROVIDER online voice)
  lingyao_edition_source(LINGYAO_UNIT_SOURCE data/lingyao-linux-${LINGYAO_PROVIDER}.socket)
  install(FILES "${LINGYAO_UNIT_SOURCE}" DESTINATION "${LINGYAO_SYSTEMD_USER_UNIT_DIR}"
          RENAME ${LINGYAO_EDITION_PACKAGE}-${LINGYAO_PROVIDER}.socket)
endforeach()
install(FILES scripts/lingyao_voice_doubao.py scripts/lingyao_voice_local.py scripts/lingyao_provider_runtime.py DESTINATION "${CMAKE_INSTALL_BINDIR}")
# The helper and the sherpa-onnx runtime share the host library's private directory: the helper finds the runtime in its own directory, and libsherpa-onnx-c-api.so finds libonnxruntime.so through its $ORIGIN RPATH.
install(TARGETS lingyao-voice-local RUNTIME DESTINATION "${CMAKE_INSTALL_LIBDIR}/${LINGYAO_CLIENT_DIRECTORY}")
set(LINGYAO_VOICE_RUNTIME_DIR "" CACHE PATH "sherpa-onnx runtime for on-device recognition, as unpacked by scripts/fetch_voice_runtime.py --platform linux-<arch>")
set(LINGYAO_VOICE_RUNTIME_LIBRARIES libsherpa-onnx-c-api.so libonnxruntime.so)
if(LINGYAO_VOICE_RUNTIME_DIR)
  foreach(LINGYAO_VOICE_RUNTIME_LIBRARY IN LISTS LINGYAO_VOICE_RUNTIME_LIBRARIES)
    if(NOT EXISTS "${LINGYAO_VOICE_RUNTIME_DIR}/${LINGYAO_VOICE_RUNTIME_LIBRARY}")
      message(FATAL_ERROR "LINGYAO_VOICE_RUNTIME_DIR has no ${LINGYAO_VOICE_RUNTIME_LIBRARY}; run scripts/fetch_voice_runtime.py --platform linux-<arch> --out <dir>")
    endif()
    install(FILES "${LINGYAO_VOICE_RUNTIME_DIR}/${LINGYAO_VOICE_RUNTIME_LIBRARY}" DESTINATION "${CMAKE_INSTALL_LIBDIR}/${LINGYAO_CLIENT_DIRECTORY}")
  endforeach()
elseif(LINGYAO_ENABLE_PACKAGING)
  # A package without the runtime would offer on-device recognition that fails at the first dictation.
  message(FATAL_ERROR "Packaging requires LINGYAO_VOICE_RUNTIME_DIR; fetch it with scripts/fetch_voice_runtime.py (package-container.sh does)")
endif()
# 上面只核对运行库的文件在不在；这里让构建出的 lingyao-voice-local 真正打开它（dlopen 并解析全部符号），各打包路线的 ctest 都会跑到。
if(BUILD_TESTING AND LINGYAO_VOICE_RUNTIME_DIR)
  add_test(NAME linux-voice-local-runtime
           COMMAND "${Python3_EXECUTABLE}" "${CMAKE_CURRENT_SOURCE_DIR}/tests/voice/local_runtime.py"
                   $<TARGET_FILE:lingyao-voice-local> "${LINGYAO_VOICE_RUNTIME_DIR}/libsherpa-onnx-c-api.so")
endif()
install(FILES scripts/requirements-voice.txt DESTINATION "${CMAKE_INSTALL_DATADIR}/${LINGYAO_CLIENT_DIRECTORY}")
file(RELATIVE_PATH LINGYAO_VOICE_CUE_RELATIVE "${CMAKE_INSTALL_FULL_BINDIR}"
     "${CMAKE_INSTALL_FULL_DATADIR}/${LINGYAO_CLIENT_DIRECTORY}/voice")
file(RELATIVE_PATH LINGYAO_VOICE_LOCAL_HELPER_RELATIVE "${CMAKE_INSTALL_FULL_BINDIR}"
     "${CMAKE_INSTALL_FULL_LIBDIR}/${LINGYAO_CLIENT_DIRECTORY}/lingyao-voice-local")
get_filename_component(LINGYAO_HOST_LIBRARY_NAME "${LINGYAO_HOST_LIBRARY}" NAME)
file(RELATIVE_PATH LINGYAO_HOST_LIBRARY_RELATIVE "${CMAKE_INSTALL_FULL_BINDIR}"
     "${CMAKE_INSTALL_FULL_LIBDIR}/${LINGYAO_CLIENT_DIRECTORY}/${LINGYAO_HOST_LIBRARY_NAME}")
configure_file(data/lingyao_voice_paths.py.in lingyao_voice_paths.py @ONLY)
install(FILES "${CMAKE_CURRENT_BINARY_DIR}/lingyao_voice_paths.py" DESTINATION "${CMAKE_INSTALL_BINDIR}")
install(FILES data/voice/start.pcm data/voice/end.pcm data/voice/SOURCE.md
        DESTINATION "${CMAKE_INSTALL_DATADIR}/${LINGYAO_CLIENT_DIRECTORY}/voice")
# `lingyao-linux-handwriting --local` 识别用的 zinnia 模型及其 LGPL-2.1 许可证。它有 26.8 MB，不进版本库：scripts/fetch_handwriting_model.py 把 resources/handwriting-model.lock.json 锁定的文件下载到 target/handwriting-model，存在时这里取用，并逐个文件按锁校验。LINGYAO_BUNDLE_HANDWRITING_MODEL 打开时（默认如此，packaging/ 下的发行版构建和 nix 都依赖这个默认值）打包必须带上模型，否则包里的离线识别器第一笔就会失败；关闭时（我们自己发布的 deb/rpm，由 package-container.sh 关闭）不安装模型，由设置应用按需下载到用户目录。开发安装没有模型时，只是 --local 报告未安装模型。
# 模型只认汉字：不提供手写的版本（版本表 `features.handwriting` 为 false 的日文、越南文和藏文版）即使下载或指定了模型，也既不装模型也不装它的许可证，打包时也不要求有模型。
# 我们自己发布的 deb/rpm（package-container.sh）传 -DLINGYAO_BUNDLE_HANDWRITING_MODEL=OFF：包里不带模型和它的许可证，设置应用在需要时按同一份锁把两者下载到用户的状态目录（client-core 的手写资源包）。发行版仓库的包不传这个选项，照旧随包。
if(NOT LINGYAO_EDITION_HANDWRITING)
  if(LINGYAO_HANDWRITING_MODEL_DIR)
    message(STATUS "Edition ${LINGYAO_EDITION} offers no handwriting; not installing the model in ${LINGYAO_HANDWRITING_MODEL_DIR}")
  endif()
  set(LINGYAO_HANDWRITING_MODEL_DIR "")
elseif(NOT LINGYAO_BUNDLE_HANDWRITING_MODEL)
  if(LINGYAO_HANDWRITING_MODEL_DIR)
    message(STATUS "LINGYAO_BUNDLE_HANDWRITING_MODEL is OFF; not installing the model in ${LINGYAO_HANDWRITING_MODEL_DIR}")
  endif()
  set(LINGYAO_HANDWRITING_MODEL_DIR "")
elseif(NOT LINGYAO_HANDWRITING_MODEL_DIR AND
   EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/../../target/handwriting-model/handwriting-zh_CN.model")
  get_filename_component(LINGYAO_HANDWRITING_MODEL_DIR
                         "${CMAKE_CURRENT_SOURCE_DIR}/../../target/handwriting-model" ABSOLUTE)
  message(STATUS "Using handwriting model staging directory: ${LINGYAO_HANDWRITING_MODEL_DIR}")
endif()
if(LINGYAO_HANDWRITING_MODEL_DIR)
  if(NOT IS_DIRECTORY "${LINGYAO_HANDWRITING_MODEL_DIR}")
    message(FATAL_ERROR "LINGYAO_HANDWRITING_MODEL_DIR is not a directory: ${LINGYAO_HANDWRITING_MODEL_DIR}")
  endif()
  set(LINGYAO_HANDWRITING_LOCK_FILE "${CMAKE_CURRENT_SOURCE_DIR}/../../resources/handwriting-model.lock.json")
  set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS "${LINGYAO_HANDWRITING_LOCK_FILE}")
  file(READ "${LINGYAO_HANDWRITING_LOCK_FILE}" LINGYAO_HANDWRITING_LOCK)
  string(JSON LINGYAO_HANDWRITING_COUNT LENGTH "${LINGYAO_HANDWRITING_LOCK}" artifacts)
  math(EXPR LINGYAO_HANDWRITING_LAST "${LINGYAO_HANDWRITING_COUNT} - 1")
  foreach(LINGYAO_HANDWRITING_INDEX RANGE 0 ${LINGYAO_HANDWRITING_LAST})
    string(JSON LINGYAO_HANDWRITING_NAME GET "${LINGYAO_HANDWRITING_LOCK}"
           artifacts ${LINGYAO_HANDWRITING_INDEX} name)
    set(LINGYAO_HANDWRITING_FILE "${LINGYAO_HANDWRITING_MODEL_DIR}/${LINGYAO_HANDWRITING_NAME}")
    if(NOT EXISTS "${LINGYAO_HANDWRITING_FILE}" OR
       IS_DIRECTORY "${LINGYAO_HANDWRITING_FILE}" OR
       IS_SYMLINK "${LINGYAO_HANDWRITING_FILE}")
      message(FATAL_ERROR "Missing ${LINGYAO_HANDWRITING_NAME} in ${LINGYAO_HANDWRITING_MODEL_DIR}; run scripts/fetch_handwriting_model.py")
    endif()
    string(JSON LINGYAO_HANDWRITING_SIZE GET "${LINGYAO_HANDWRITING_LOCK}"
           artifacts ${LINGYAO_HANDWRITING_INDEX} size)
    string(JSON LINGYAO_HANDWRITING_SHA256 GET "${LINGYAO_HANDWRITING_LOCK}"
           artifacts ${LINGYAO_HANDWRITING_INDEX} sha256)
    file(SIZE "${LINGYAO_HANDWRITING_FILE}" LINGYAO_HANDWRITING_ACTUAL_SIZE)
    file(SHA256 "${LINGYAO_HANDWRITING_FILE}" LINGYAO_HANDWRITING_ACTUAL_SHA256)
    if(NOT LINGYAO_HANDWRITING_ACTUAL_SIZE STREQUAL LINGYAO_HANDWRITING_SIZE OR
       NOT LINGYAO_HANDWRITING_ACTUAL_SHA256 STREQUAL LINGYAO_HANDWRITING_SHA256)
      message(FATAL_ERROR
        "${LINGYAO_HANDWRITING_NAME} in ${LINGYAO_HANDWRITING_MODEL_DIR} does not match resources/handwriting-model.lock.json")
    endif()
    install(FILES "${LINGYAO_HANDWRITING_FILE}"
            DESTINATION "${CMAKE_INSTALL_DATADIR}/${LINGYAO_CLIENT_DIRECTORY}/handwriting")
  endforeach()
  install(FILES "${LINGYAO_HANDWRITING_LOCK_FILE}" DESTINATION "${CMAKE_INSTALL_DATADIR}/${LINGYAO_CLIENT_DIRECTORY}")
elseif(LINGYAO_ENABLE_PACKAGING AND LINGYAO_EDITION_HANDWRITING AND LINGYAO_BUNDLE_HANDWRITING_MODEL)
  message(FATAL_ERROR "Packaging requires the handwriting model; fetch it with scripts/fetch_handwriting_model.py, or configure with -DLINGYAO_BUNDLE_HANDWRITING_MODEL=OFF to leave it to the on-demand download")
endif()
# 上面只按锁核对模型的字节；这里用构建出的识别入口真正加载它并识别一笔，各打包路线的 ctest 都会跑到。
if(BUILD_TESTING AND LINGYAO_HANDWRITING_MODEL_DIR)
  add_test(NAME linux-handwriting-local-model
           COMMAND "${Python3_EXECUTABLE}" "${CMAKE_CURRENT_SOURCE_DIR}/tests/provider/handwriting_local_model.py"
                   $<TARGET_FILE:lingyao-linux-handwriting> "${LINGYAO_HANDWRITING_MODEL_DIR}/handwriting-zh_CN.model")
endif()
if(LINGYAO_EMOJI_RESOURCES)
  if(NOT IS_DIRECTORY "${LINGYAO_EMOJI_RESOURCES}")
    message(FATAL_ERROR "LINGYAO_EMOJI_RESOURCES is not a directory: ${LINGYAO_EMOJI_RESOURCES}")
  endif()
  install(DIRECTORY "${LINGYAO_EMOJI_RESOURCES}/"
          DESTINATION "${CMAKE_INSTALL_DATADIR}/${LINGYAO_CLIENT_DIRECTORY}/emoji")
endif()
if(LINGYAO_ENGINE_RESOURCES)
  if(NOT IS_DIRECTORY "${LINGYAO_ENGINE_RESOURCES}")
    message(FATAL_ERROR "LINGYAO_ENGINE_RESOURCES is not a directory: ${LINGYAO_ENGINE_RESOURCES}")
  endif()
  file(READ "${LINGYAO_EDITION_RESOURCE_LOCK}" LINGYAO_ENGINE_RESOURCE_LOCK)
  string(JSON LINGYAO_ENGINE_RESOURCE_COUNT LENGTH "${LINGYAO_ENGINE_RESOURCE_LOCK}" artifacts)
  math(EXPR LINGYAO_ENGINE_RESOURCE_LAST "${LINGYAO_ENGINE_RESOURCE_COUNT} - 1")
  foreach(LINGYAO_ENGINE_RESOURCE_INDEX RANGE 0 ${LINGYAO_ENGINE_RESOURCE_LAST})
    string(JSON LINGYAO_ENGINE_RESOURCE_NAME GET "${LINGYAO_ENGINE_RESOURCE_LOCK}"
           artifacts ${LINGYAO_ENGINE_RESOURCE_INDEX} name)
    set(LINGYAO_ENGINE_RESOURCE_FILE "${LINGYAO_ENGINE_RESOURCES}/${LINGYAO_ENGINE_RESOURCE_NAME}")
    if(NOT EXISTS "${LINGYAO_ENGINE_RESOURCE_FILE}" OR
       IS_DIRECTORY "${LINGYAO_ENGINE_RESOURCE_FILE}" OR
       IS_SYMLINK "${LINGYAO_ENGINE_RESOURCE_FILE}")
      message(FATAL_ERROR "Missing Engine resource ${LINGYAO_ENGINE_RESOURCE_NAME} in ${LINGYAO_ENGINE_RESOURCES}")
    endif()
    string(JSON LINGYAO_ENGINE_RESOURCE_SIZE GET "${LINGYAO_ENGINE_RESOURCE_LOCK}"
           artifacts ${LINGYAO_ENGINE_RESOURCE_INDEX} size)
    string(JSON LINGYAO_ENGINE_RESOURCE_SHA256 GET "${LINGYAO_ENGINE_RESOURCE_LOCK}"
           artifacts ${LINGYAO_ENGINE_RESOURCE_INDEX} sha256)
    file(SIZE "${LINGYAO_ENGINE_RESOURCE_FILE}" LINGYAO_ENGINE_RESOURCE_ACTUAL_SIZE)
    file(SHA256 "${LINGYAO_ENGINE_RESOURCE_FILE}" LINGYAO_ENGINE_RESOURCE_ACTUAL_SHA256)
    if(NOT LINGYAO_ENGINE_RESOURCE_ACTUAL_SIZE STREQUAL LINGYAO_ENGINE_RESOURCE_SIZE OR
       NOT LINGYAO_ENGINE_RESOURCE_ACTUAL_SHA256 STREQUAL LINGYAO_ENGINE_RESOURCE_SHA256)
      message(FATAL_ERROR
        "Engine resource ${LINGYAO_ENGINE_RESOURCE_NAME} does not match the reviewed lock")
    endif()
    install(FILES "${LINGYAO_ENGINE_RESOURCE_FILE}"
            DESTINATION "${CMAKE_INSTALL_DATADIR}/${LINGYAO_CLIENT_DIRECTORY}/resources")
  endforeach()
  # The helpcode tables are not part of the dictionary release; the repository carries them in resources/helpcodes, and the Engine reads them from helpcodes/ under the resource directory (crates/engine/src/assets.rs names the six files). The hosts' verification lets a real helpcodes/ directory through. Their notices are installed with the others below.
  install(FILES
            "${CMAKE_CURRENT_SOURCE_DIR}/../../resources/helpcodes/helpcode.txt"
            "${CMAKE_CURRENT_SOURCE_DIR}/../../resources/helpcodes/zrm_helpcode_big_unique.txt"
            "${CMAKE_CURRENT_SOURCE_DIR}/../../resources/helpcodes/shouyou2_0_helpcode.txt"
            "${CMAKE_CURRENT_SOURCE_DIR}/../../resources/helpcodes/shouyouplus_helpcode.txt"
            "${CMAKE_CURRENT_SOURCE_DIR}/../../resources/helpcodes/xiaohe_helpcode.txt"
            "${CMAKE_CURRENT_SOURCE_DIR}/../../resources/helpcodes/jiajia_helpcode.txt"
          DESTINATION "${CMAKE_INSTALL_DATADIR}/${LINGYAO_CLIENT_DIRECTORY}/resources/helpcodes")
  # Keep the reviewed lock beside the installed bundle as provenance metadata;
  # it is not copied into the runtime directory because the Engine verifier
  # requires that directory to contain exactly the pinned artifacts.
  install(FILES "${LINGYAO_EDITION_RESOURCE_LOCK}"
          DESTINATION "${CMAKE_INSTALL_DATADIR}/${LINGYAO_CLIENT_DIRECTORY}" RENAME desktop-dictionary.lock.json)
endif()
# The settled-rerank model, installed as a sibling of the resource bundle.
#
# A sibling and not a member: the Engine verifier requires the resource directory to hold exactly
# the artifacts the dictionary lock pins, so an extra file there fails the check that proves a
# shipped dictionary is intact. `prepare_host_configuration` looks for it here and writes the path
# into the runtime options; without it the host behaves exactly as it does today.
#
# Optional because it is 25 MB and buys a desktop-only improvement — 49 points of top-1 on the
# harvested failure set, at a cost that keeps it off the keystroke path and on the settle timer.
# Fetch it with `scripts/fetch_neural_model.py`, which writes `target/neural-model` by default.
# The historical one-artifact `scripts/fetch_settled_model.py` output remains accepted below.
# 不带中文主词库的版本（cmake/Edition.cmake 的 LINGYAO_EDITION_CHINESE_MAIN）没有中文整句可以重排，不装这个模型，也不从暂存目录捡。
if(NOT LINGYAO_EDITION_CHINESE_MAIN)
  if(LINGYAO_SETTLED_MODEL)
    message(STATUS "Edition ${LINGYAO_EDITION} has no Chinese main dictionary; not installing the settled model")
  endif()
  set(LINGYAO_SETTLED_MODEL "")
elseif(NOT LINGYAO_SETTLED_MODEL AND
   EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/../../target/neural-model/sentence-model-desktop.safetensors")
  get_filename_component(LINGYAO_SETTLED_MODEL
                         "${CMAKE_CURRENT_SOURCE_DIR}/../../target/neural-model" ABSOLUTE)
  message(STATUS "Using neural model staging directory: ${LINGYAO_SETTLED_MODEL}")
endif()
if(LINGYAO_SETTLED_MODEL)
  if(NOT IS_DIRECTORY "${LINGYAO_SETTLED_MODEL}")
    message(FATAL_ERROR "LINGYAO_SETTLED_MODEL is not a directory: ${LINGYAO_SETTLED_MODEL}")
  endif()
  file(READ "${CMAKE_CURRENT_SOURCE_DIR}/../../resources/settled-model.lock.json"
       LINGYAO_SETTLED_LOCK)
  string(JSON LINGYAO_SETTLED_COUNT LENGTH "${LINGYAO_SETTLED_LOCK}" artifacts)
  math(EXPR LINGYAO_SETTLED_LAST "${LINGYAO_SETTLED_COUNT} - 1")
  foreach(LINGYAO_SETTLED_INDEX RANGE 0 ${LINGYAO_SETTLED_LAST})
    string(JSON LINGYAO_SETTLED_NAME GET "${LINGYAO_SETTLED_LOCK}"
           artifacts ${LINGYAO_SETTLED_INDEX} name)
    set(LINGYAO_SETTLED_FILE "${LINGYAO_SETTLED_MODEL}/${LINGYAO_SETTLED_NAME}")
    if(NOT EXISTS "${LINGYAO_SETTLED_FILE}" OR
       IS_DIRECTORY "${LINGYAO_SETTLED_FILE}" OR
       IS_SYMLINK "${LINGYAO_SETTLED_FILE}")
      message(FATAL_ERROR "Missing settled model ${LINGYAO_SETTLED_NAME} in ${LINGYAO_SETTLED_MODEL}")
    endif()
    string(JSON LINGYAO_SETTLED_SIZE GET "${LINGYAO_SETTLED_LOCK}"
           artifacts ${LINGYAO_SETTLED_INDEX} size)
    string(JSON LINGYAO_SETTLED_SHA256 GET "${LINGYAO_SETTLED_LOCK}"
           artifacts ${LINGYAO_SETTLED_INDEX} sha256)
    file(SIZE "${LINGYAO_SETTLED_FILE}" LINGYAO_SETTLED_ACTUAL_SIZE)
    file(SHA256 "${LINGYAO_SETTLED_FILE}" LINGYAO_SETTLED_ACTUAL_SHA256)
    if(NOT LINGYAO_SETTLED_ACTUAL_SIZE STREQUAL LINGYAO_SETTLED_SIZE OR
       NOT LINGYAO_SETTLED_ACTUAL_SHA256 STREQUAL LINGYAO_SETTLED_SHA256)
      message(FATAL_ERROR
        "Settled model ${LINGYAO_SETTLED_NAME} does not match the reviewed lock")
    endif()
    install(FILES "${LINGYAO_SETTLED_FILE}"
            DESTINATION "${CMAKE_INSTALL_DATADIR}/${LINGYAO_CLIENT_DIRECTORY}/settled-model")
  endforeach()
  install(FILES "${CMAKE_CURRENT_SOURCE_DIR}/../../resources/settled-model.lock.json"
          DESTINATION "${CMAKE_INSTALL_DATADIR}/${LINGYAO_CLIENT_DIRECTORY}")
  install(FILES "${CMAKE_CURRENT_SOURCE_DIR}/../../resources/neural-model.lock.json"
          DESTINATION "${CMAKE_INSTALL_DATADIR}/${LINGYAO_CLIENT_DIRECTORY}")
endif()
# Offline glosses for non-English translation targets, one zh-<lang>.db per language built by `scripts/build_offline_glosses.py`, installed as a sibling of the resource bundle for the same reason as the settled model; the Engine looks for them there. Optional: without them the candidate glosses stay English only. Their notice is required with them, since the databases are CC BY-SA and must travel with their attribution.
set(LINGYAO_OFFLINE_GLOSSES "" CACHE PATH "Offline gloss databases with their notice, e.g. target/offline-glosses")
# 离线释义按中文候选查：不提供中文方案的版本（版本表 `features.offline_glosses` 为 false 的日文、越南文和藏文版）即使指定了 `LINGYAO_OFFLINE_GLOSSES` 也不装。
if(LINGYAO_OFFLINE_GLOSSES AND NOT LINGYAO_EDITION_OFFLINE_GLOSSES)
  message(STATUS "Edition ${LINGYAO_EDITION} offers no Chinese scheme; not installing the offline glosses in ${LINGYAO_OFFLINE_GLOSSES}")
elseif(LINGYAO_OFFLINE_GLOSSES)
  if(NOT EXISTS "${LINGYAO_OFFLINE_GLOSSES}/offline-glosses-NOTICE.txt")
    message(FATAL_ERROR "LINGYAO_OFFLINE_GLOSSES has no offline-glosses-NOTICE.txt: ${LINGYAO_OFFLINE_GLOSSES}")
  endif()
  file(GLOB LINGYAO_OFFLINE_GLOSS_FILES LIST_DIRECTORIES false "${LINGYAO_OFFLINE_GLOSSES}/zh-*.db")
  if(NOT LINGYAO_OFFLINE_GLOSS_FILES)
    message(FATAL_ERROR "LINGYAO_OFFLINE_GLOSSES has no zh-*.db: ${LINGYAO_OFFLINE_GLOSSES}")
  endif()
  install(FILES ${LINGYAO_OFFLINE_GLOSS_FILES} "${LINGYAO_OFFLINE_GLOSSES}/offline-glosses-NOTICE.txt"
          DESTINATION "${CMAKE_INSTALL_DATADIR}/${LINGYAO_CLIENT_DIRECTORY}/offline-glosses")
endif()
# The Cantonese, Zhuyin and Stroke dictionaries fetched by scripts/fetch_language_dictionaries.py (or built by `lingyao-dict-build languages`), installed as the `language-dictionaries` sibling of the resource bundle for the same reason as the settled model: the resource directory must match the dictionary lock exactly. lingyao_client_refresh_host names the directory in the runtime options when the host starts, and a scheme whose dictionary is missing is shown as unavailable and falls back. Optional, picked up from target/language-dictionaries when present; each dictionary is installed only with its licence text, which must travel with the data. LINGYAO_REQUIRE_LANGUAGE_DICTIONARIES makes a package fail instead of shipping without any dictionary the lock pins.
set(LINGYAO_LANGUAGE_DICTIONARIES "" CACHE PATH "Cantonese, Zhuyin and Stroke dictionaries with their licences, e.g. target/language-dictionaries")
option(LINGYAO_REQUIRE_LANGUAGE_DICTIONARIES "Fail unless every dictionary resources/language-dictionaries.lock.json pins is installed" OFF)
# 不用粤语、注音和笔画的版本（版本表的 language_dictionaries 为空）不装这些词库，也不从暂存目录捡。
if(NOT LINGYAO_EDITION_LANGUAGE_DICTIONARIES)
  set(LINGYAO_LANGUAGE_DICTIONARIES "")
elseif(NOT LINGYAO_LANGUAGE_DICTIONARIES AND
   IS_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/../../target/language-dictionaries")
  get_filename_component(LINGYAO_LANGUAGE_DICTIONARIES
                         "${CMAKE_CURRENT_SOURCE_DIR}/../../target/language-dictionaries" ABSOLUTE)
  message(STATUS "Using language dictionary staging directory: ${LINGYAO_LANGUAGE_DICTIONARIES}")
endif()
set(LINGYAO_LANGUAGE_DICTIONARY_COUNT 0)
set(LINGYAO_LANGUAGE_DICTIONARIES_INSTALLED)
if(LINGYAO_LANGUAGE_DICTIONARIES)
  if(NOT IS_DIRECTORY "${LINGYAO_LANGUAGE_DICTIONARIES}")
    message(FATAL_ERROR "LINGYAO_LANGUAGE_DICTIONARIES is not a directory: ${LINGYAO_LANGUAGE_DICTIONARIES}")
  endif()
  foreach(LINGYAO_LANGUAGE_PAIR "lingyao-cantonese.db:lingyao-rime_cantonese_LICENSE.txt" "lingyao-zhuyin.db:lingyao-libchewing_data_LICENSE.txt"
          "lingyao-stroke.db:lingyao-rime_stroke_LICENSE.txt")
    string(REPLACE ":" ";" LINGYAO_LANGUAGE_PAIR "${LINGYAO_LANGUAGE_PAIR}")
    list(GET LINGYAO_LANGUAGE_PAIR 0 LINGYAO_LANGUAGE_DATABASE)
    list(GET LINGYAO_LANGUAGE_PAIR 1 LINGYAO_LANGUAGE_LICENSE)
    set(LINGYAO_LANGUAGE_DATABASE_FILE "${LINGYAO_LANGUAGE_DICTIONARIES}/${LINGYAO_LANGUAGE_DATABASE}")
    if(NOT EXISTS "${LINGYAO_LANGUAGE_DATABASE_FILE}" OR IS_DIRECTORY "${LINGYAO_LANGUAGE_DATABASE_FILE}")
      continue()
    endif()
    if(NOT EXISTS "${LINGYAO_LANGUAGE_DICTIONARIES}/${LINGYAO_LANGUAGE_LICENSE}")
      message(FATAL_ERROR "${LINGYAO_LANGUAGE_DATABASE_FILE} has no ${LINGYAO_LANGUAGE_LICENSE} beside it; refusing to install the data without its licence")
    endif()
    install(FILES "${LINGYAO_LANGUAGE_DATABASE_FILE}" "${LINGYAO_LANGUAGE_DICTIONARIES}/${LINGYAO_LANGUAGE_LICENSE}"
            DESTINATION "${CMAKE_INSTALL_DATADIR}/${LINGYAO_CLIENT_DIRECTORY}/language-dictionaries")
    math(EXPR LINGYAO_LANGUAGE_DICTIONARY_COUNT "${LINGYAO_LANGUAGE_DICTIONARY_COUNT} + 1")
    list(APPEND LINGYAO_LANGUAGE_DICTIONARIES_INSTALLED "${LINGYAO_LANGUAGE_DATABASE}")
  endforeach()
endif()
if(LINGYAO_LANGUAGE_DICTIONARY_COUNT EQUAL 0)
  message(STATUS "No language dictionaries; Cantonese, Zhuyin and Stroke stay unavailable")
endif()
# A release requires every dictionary resources/language-dictionaries.lock.json pins, not a fixed list: a dictionary that has not been released yet is installed when present but cannot fail a release, and the lock bump that publishes it makes it required.
if(LINGYAO_REQUIRE_LANGUAGE_DICTIONARIES)
  set(LINGYAO_LANGUAGE_DICTIONARIES_LOCK "${CMAKE_CURRENT_SOURCE_DIR}/../../resources/language-dictionaries.lock.json")
  if(NOT EXISTS "${LINGYAO_LANGUAGE_DICTIONARIES_LOCK}")
    message(FATAL_ERROR "LINGYAO_REQUIRE_LANGUAGE_DICTIONARIES is ON but ${LINGYAO_LANGUAGE_DICTIONARIES_LOCK} does not exist")
  endif()
  file(READ "${LINGYAO_LANGUAGE_DICTIONARIES_LOCK}" LINGYAO_LANGUAGE_LOCK_JSON)
  string(JSON LINGYAO_LANGUAGE_LOCK_LENGTH LENGTH "${LINGYAO_LANGUAGE_LOCK_JSON}" artifacts)
  set(LINGYAO_LANGUAGE_DICTIONARIES_PINNED)
  if(LINGYAO_LANGUAGE_LOCK_LENGTH GREATER 0)
    math(EXPR LINGYAO_LANGUAGE_LOCK_LAST "${LINGYAO_LANGUAGE_LOCK_LENGTH} - 1")
    foreach(LINGYAO_LANGUAGE_LOCK_INDEX RANGE ${LINGYAO_LANGUAGE_LOCK_LAST})
      string(JSON LINGYAO_LANGUAGE_LOCK_NAME GET "${LINGYAO_LANGUAGE_LOCK_JSON}" artifacts ${LINGYAO_LANGUAGE_LOCK_INDEX} name)
      if(LINGYAO_LANGUAGE_LOCK_NAME MATCHES "\\.db$")
        list(APPEND LINGYAO_LANGUAGE_DICTIONARIES_PINNED "${LINGYAO_LANGUAGE_LOCK_NAME}")
      endif()
    endforeach()
  endif()
  if(NOT LINGYAO_LANGUAGE_DICTIONARIES_PINNED)
    message(FATAL_ERROR "LINGYAO_REQUIRE_LANGUAGE_DICTIONARIES is ON but ${LINGYAO_LANGUAGE_DICTIONARIES_LOCK} pins no dictionary")
  endif()
  foreach(LINGYAO_LANGUAGE_DATABASE IN LISTS LINGYAO_LANGUAGE_DICTIONARIES_PINNED)
    if(NOT LINGYAO_LANGUAGE_DATABASE IN_LIST LINGYAO_LANGUAGE_DICTIONARIES_INSTALLED)
      message(FATAL_ERROR "LINGYAO_REQUIRE_LANGUAGE_DICTIONARIES is ON but ${LINGYAO_LANGUAGE_DATABASE}, pinned by resources/language-dictionaries.lock.json, was not found in '${LINGYAO_LANGUAGE_DICTIONARIES}'")
    endif()
  endforeach()
endif()
if(LINGYAO_DESKTOP_BINARY)
  if(NOT EXISTS "${LINGYAO_DESKTOP_BINARY}")
    message(FATAL_ERROR "LINGYAO_DESKTOP_BINARY does not exist: ${LINGYAO_DESKTOP_BINARY}")
  endif()
  # Quote the configured path as one POSIX shell word, including apostrophes.
  string(REPLACE "'" "'\\''" LINGYAO_SETTINGS_SYSTEM_CONFIG
         "${CMAKE_INSTALL_FULL_SYSCONFDIR}/${LINGYAO_CLIENT_DIRECTORY}/runtime-options.json")
  # 设置命令和桌面入口以版本的包名命名（full 仍是 lingyao-linux-settings 和 lingyao-linux.desktop）。
  lingyao_edition_source(LINGYAO_SETTINGS_SOURCE data/lingyao-linux-settings.in)
  lingyao_edition_source(LINGYAO_DESKTOP_ENTRY_SOURCE data/lingyao-linux.desktop.in)
  configure_file("${LINGYAO_SETTINGS_SOURCE}" ${CMAKE_CURRENT_BINARY_DIR}/${LINGYAO_EDITION_PACKAGE}-settings @ONLY)
  configure_file("${LINGYAO_DESKTOP_ENTRY_SOURCE}" ${CMAKE_CURRENT_BINARY_DIR}/${LINGYAO_EDITION_PACKAGE}.desktop @ONLY)
  install(PROGRAMS "${LINGYAO_DESKTOP_BINARY}" DESTINATION "${CMAKE_INSTALL_BINDIR}" RENAME lingyao-linux-desktop)
  install(PROGRAMS ${CMAKE_CURRENT_BINARY_DIR}/${LINGYAO_EDITION_PACKAGE}-settings DESTINATION "${CMAKE_INSTALL_BINDIR}")
  install(FILES ${CMAKE_CURRENT_BINARY_DIR}/${LINGYAO_EDITION_PACKAGE}.desktop DESTINATION "${LINGYAO_SYSTEM_DATADIR}/applications")
  # The Omarchy theme-set hook runs lingyao-linux-settings, so it ships with it; lingyao-linux-setup links it into ~/.config/omarchy/hooks/theme-set.d on an Omarchy desktop.
  lingyao_edition_source(LINGYAO_OMARCHY_SOURCE data/omarchy/theme-set.in)
  configure_file("${LINGYAO_OMARCHY_SOURCE}" ${CMAKE_CURRENT_BINARY_DIR}/omarchy/theme-set @ONLY)
  install(PROGRAMS ${CMAKE_CURRENT_BINARY_DIR}/omarchy/theme-set DESTINATION "${CMAKE_INSTALL_DATADIR}/${LINGYAO_CLIENT_DIRECTORY}/omarchy")
  # The bar widget and its menu stand in for the tray Omarchy disables; the menu opens lingyao-linux-settings panels, so both ship with it too. lingyao-linux-setup links the plugin directory into ~/.config/omarchy/plugins.
  lingyao_edition_source(LINGYAO_OMARCHY_SOURCE data/omarchy/menu.in)
  configure_file("${LINGYAO_OMARCHY_SOURCE}" ${CMAKE_CURRENT_BINARY_DIR}/omarchy/menu @ONLY)
  lingyao_edition_source(LINGYAO_OMARCHY_SOURCE data/omarchy/plugin/Widget.qml.in)
  configure_file("${LINGYAO_OMARCHY_SOURCE}" ${CMAKE_CURRENT_BINARY_DIR}/omarchy/plugin/Widget.qml @ONLY)
  lingyao_edition_source(LINGYAO_OMARCHY_MANIFEST_SOURCE data/omarchy/plugin/manifest.json)
  install(PROGRAMS ${CMAKE_CURRENT_BINARY_DIR}/omarchy/menu DESTINATION "${CMAKE_INSTALL_DATADIR}/${LINGYAO_CLIENT_DIRECTORY}/omarchy")
  install(FILES "${LINGYAO_OMARCHY_MANIFEST_SOURCE}" ${CMAKE_CURRENT_BINARY_DIR}/omarchy/plugin/Widget.qml
          DESTINATION "${CMAKE_INSTALL_DATADIR}/${LINGYAO_CLIENT_DIRECTORY}/omarchy/plugin")
endif()
# Nothing here starts the MCP server: an agent's MCP configuration names the command and runs it over stdio, so it only has to be on PATH.
if(LINGYAO_MCP_BINARY)
  if(NOT EXISTS "${LINGYAO_MCP_BINARY}")
    message(FATAL_ERROR "LINGYAO_MCP_BINARY does not exist: ${LINGYAO_MCP_BINARY}")
  endif()
  install(PROGRAMS "${LINGYAO_MCP_BINARY}" DESTINATION "${CMAKE_INSTALL_BINDIR}")
  # full 再以 lingyao 的名字放一个指向它的相对链接，供在终端里手动敲 lingyao expand、lingyao config，与 macOS 的 Homebrew cask 相同。其他版本装在自己的前缀下，那里的 bin 不在 PATH 上，同名的命令也只能有一个，留给 full。
  if(LINGYAO_EDITION_IS_FULL)
    file(MAKE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/mcp")
    file(CREATE_LINK lingyao-mcp "${CMAKE_CURRENT_BINARY_DIR}/mcp/lingyao" SYMBOLIC)
    install(FILES "${CMAKE_CURRENT_BINARY_DIR}/mcp/lingyao" DESTINATION "${CMAKE_INSTALL_BINDIR}")
  endif()
endif()
# The built-in sound packs, synthesized by scripts/generate_sound_packs.py and dedicated to the public domain, beside the resource directory rather than in it: that directory has to hold exactly what the dictionary lock pins. The hosts and the settings window name this directory to client-core as the built-in pack root.
install(DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/../../resources/sound-packs/"
        DESTINATION "${CMAKE_INSTALL_DATADIR}/${LINGYAO_CLIENT_DIRECTORY}/sound-packs")
# 桌面入口的 Icon=lingyao-linux、Fcitx5 输入法条目的 Icon 和 IBus 组件的 <icon> 都按名字
# 解析，所以这些文件决定了托盘、输入法列表和启动器上显示的是 logo 还是占位图。它们此前
# 装在桌面二进制那个分支里，于是只装输入法、不装设置窗口的安装一张图标都没有，而那恰恰
# 是最小可用的安装方式。
# 所有版本用同一个图标，其他版本把同样的文件装成以自己包名命名的图标，几个版本的包才不会争同一个文件。
if(LINGYAO_EDITION_IS_FULL)
  install(DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/data/icons/"
          DESTINATION "${CMAKE_INSTALL_DATADIR}/icons")
else()
  file(GLOB LINGYAO_ICON_FILES RELATIVE "${CMAKE_CURRENT_SOURCE_DIR}/data/icons"
       "${CMAKE_CURRENT_SOURCE_DIR}/data/icons/hicolor/*/apps/lingyao-linux.*")
  foreach(LINGYAO_ICON_FILE IN LISTS LINGYAO_ICON_FILES)
    get_filename_component(LINGYAO_ICON_DIRECTORY "${LINGYAO_ICON_FILE}" DIRECTORY)
    get_filename_component(LINGYAO_ICON_EXTENSION "${LINGYAO_ICON_FILE}" LAST_EXT)
    install(FILES "${CMAKE_CURRENT_SOURCE_DIR}/data/icons/${LINGYAO_ICON_FILE}"
            DESTINATION "${LINGYAO_SYSTEM_DATADIR}/icons/${LINGYAO_ICON_DIRECTORY}"
            RENAME "${LINGYAO_EDITION_PACKAGE}${LINGYAO_ICON_EXTENSION}")
  endforeach()
endif()
configure_file(cmake/icon-cache.cmake.in ${CMAKE_CURRENT_BINARY_DIR}/icon-cache.cmake @ONLY)
install(SCRIPT ${CMAKE_CURRENT_BINARY_DIR}/icon-cache.cmake)
if(LINGYAO_RUNTIME_OPTIONS_FILE)
 install(FILES "${LINGYAO_RUNTIME_OPTIONS_FILE}" DESTINATION "${CMAKE_INSTALL_SYSCONFDIR}/${LINGYAO_CLIENT_DIRECTORY}" RENAME runtime-options.json)
endif()
install(FILES ${CMAKE_CURRENT_BINARY_DIR}/${LINGYAO_EDITION_PACKAGE}.xml DESTINATION "${LINGYAO_SYSTEM_DATADIR}/ibus/component")
# 其他版本在前缀的 bin 目录里声明自己的版本（crates/client-core 的 Edition::of_linux_package），设置应用和 lingyao-mcp 据此找到本版本的状态目录和 socket；full 不带这个文件。
if(NOT LINGYAO_EDITION_IS_FULL)
  execute_process(
    COMMAND "${Python3_EXECUTABLE}" "${CMAKE_CURRENT_SOURCE_DIR}/scripts/edition_linux.py"
            marker --edition "${LINGYAO_EDITION}" --output "${CMAKE_CURRENT_BINARY_DIR}/edition/edition.json"
    RESULT_VARIABLE LINGYAO_EDITION_MARKER_RESULT)
  if(NOT LINGYAO_EDITION_MARKER_RESULT EQUAL 0)
    message(FATAL_ERROR "Cannot write the edition marker for ${LINGYAO_EDITION}")
  endif()
  install(FILES "${CMAKE_CURRENT_BINARY_DIR}/edition/edition.json" DESTINATION "${CMAKE_INSTALL_BINDIR}")
endif()
# 装在自己前缀下的版本在 /usr/bin 放两个指向前缀的命令（<package>-setup、<package>-settings），用户和桌面入口不必知道前缀在哪。符号链接按原样安装；链接目标是前缀里的绝对路径。
if(LINGYAO_EDITION_SYSTEM_PATHS)
  set(LINGYAO_USER_COMMANDS setup)
  if(LINGYAO_DESKTOP_BINARY)
    list(APPEND LINGYAO_USER_COMMANDS settings)
  endif()
  file(MAKE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/edition/usr-bin")
  foreach(LINGYAO_USER_COMMAND IN LISTS LINGYAO_USER_COMMANDS)
    file(CREATE_LINK "${CMAKE_INSTALL_FULL_BINDIR}/${LINGYAO_EDITION_PACKAGE}-${LINGYAO_USER_COMMAND}"
         "${CMAKE_CURRENT_BINARY_DIR}/edition/usr-bin/${LINGYAO_EDITION_PACKAGE}-${LINGYAO_USER_COMMAND}" SYMBOLIC)
    install(FILES "${CMAKE_CURRENT_BINARY_DIR}/edition/usr-bin/${LINGYAO_EDITION_PACKAGE}-${LINGYAO_USER_COMMAND}"
            DESTINATION "/usr/bin")
  endforeach()
endif()
install(FILES "${LINGYAO_HOST_LIBRARY}" DESTINATION "${CMAKE_INSTALL_LIBDIR}/${LINGYAO_CLIENT_DIRECTORY}")
file(RELATIVE_PATH LINGYAO_HOST_LIBRARY_RELATIVE_DIR
  "${CMAKE_INSTALL_FULL_BINDIR}" "${CMAKE_INSTALL_FULL_LIBDIR}/${LINGYAO_CLIENT_DIRECTORY}")
set_target_properties(lingyao-linux-ibus lingyao-linux-dictionary lingyao-linux-cloud-dictionary lingyao-linux-cloud-clipboard lingyao-linux-online lingyao-linux-translation lingyao-linux-handwriting
                      lingyao-linux-voice lingyao-linux-emoji lingyao-linux-clipboard-capture lingyao-linux-prepare PROPERTIES
  INSTALL_RPATH "$ORIGIN/${LINGYAO_HOST_LIBRARY_RELATIVE_DIR}")

add_executable(linux-native-compose-test tests/input/native_compose.cpp)
add_executable(linux-wave-overlay-model-test
  tests/runtime/wave_overlay_model.cpp src/overlay/WaveOverlayIbusSurface.cpp
  src/overlay/WaveOverlaySurfaceFactory.cpp)
target_compile_features(linux-wave-overlay-model-test PRIVATE cxx_std_17)
target_compile_options(linux-wave-overlay-model-test PRIVATE -Wall -Wextra -Werror)
target_include_directories(linux-wave-overlay-model-test PRIVATE src)
target_link_libraries(linux-wave-overlay-model-test PRIVATE PkgConfig::IBUS)
if(X11_SURFACE_FOUND)
  target_sources(linux-wave-overlay-model-test PRIVATE src/overlay/WaveOverlayX11Surface.cpp)
  target_compile_definitions(linux-wave-overlay-model-test PRIVATE LINGYAO_LINUX_HAS_X11_SURFACE)
  target_link_libraries(linux-wave-overlay-model-test PRIVATE PkgConfig::X11_SURFACE)
endif()
if(WAYLAND_CLIENT_FOUND AND WAYLAND_SCANNER_EXECUTABLE AND LINGYAO_XDG_SHELL_XML)
  target_sources(linux-wave-overlay-model-test PRIVATE
                 src/overlay/WaveOverlayWaylandSurface.cpp "${LINGYAO_LAYER_SHELL_CODE}"
                 ${LINGYAO_XDG_SHELL_CODE})
  target_include_directories(linux-wave-overlay-model-test PRIVATE
                             "${LINGYAO_WAYLAND_PROTOCOL_DIR}")
  target_compile_definitions(linux-wave-overlay-model-test PRIVATE
                             LINGYAO_LINUX_HAS_WAYLAND_SURFACE)
  target_link_libraries(linux-wave-overlay-model-test PRIVATE
                        PkgConfig::WAYLAND_CLIENT)
  if(WAYLAND_TEXT_FOUND)
    target_compile_definitions(linux-wave-overlay-model-test PRIVATE
                               LINGYAO_LINUX_WAYLAND_TEXT)
    target_link_libraries(linux-wave-overlay-model-test PRIVATE
                          PkgConfig::WAYLAND_TEXT)
  endif()
endif()
add_test(NAME linux-wave-overlay-model COMMAND linux-wave-overlay-model-test)
# The placement it tests is X11's and reads the RandR headers, so it builds where the X11 surface does.
if(X11_SURFACE_FOUND)
  add_executable(linux-wave-overlay-placement-test tests/runtime/wave_overlay_placement.cpp)
  target_compile_features(linux-wave-overlay-placement-test PRIVATE cxx_std_17)
  target_compile_options(linux-wave-overlay-placement-test PRIVATE -Wall -Wextra -Werror)
  target_include_directories(linux-wave-overlay-placement-test PRIVATE src)
  target_link_libraries(linux-wave-overlay-placement-test PRIVATE nlohmann_json::nlohmann_json)
  add_test(NAME linux-wave-overlay-placement COMMAND linux-wave-overlay-placement-test)
endif()
add_executable(linux-mode-badge-style-test tests/runtime/mode_badge_style.cpp)
target_compile_features(linux-mode-badge-style-test PRIVATE cxx_std_17)
target_compile_options(linux-mode-badge-style-test PRIVATE -Wall -Wextra -Werror)
target_include_directories(linux-mode-badge-style-test PRIVATE src)
target_link_libraries(linux-mode-badge-style-test PRIVATE nlohmann_json::nlohmann_json)
add_test(NAME linux-mode-badge-style COMMAND linux-mode-badge-style-test)
target_compile_options(linux-native-compose-test PRIVATE -Wall -Wextra -Werror)
target_include_directories(linux-native-compose-test PRIVATE src)
target_link_libraries(linux-native-compose-test PRIVATE PkgConfig::XKBCOMMON)
add_test(NAME linux-native-compose COMMAND linux-native-compose-test
  "${CMAKE_CURRENT_SOURCE_DIR}/tests/input/compose.fixture")

option(LINGYAO_ENABLE_PACKAGING "Enable Linux TGZ and Debian package generation" OFF)
# IBus 与 Fcitx5 是并列的两个系统入口，不是宿主和它的插件，所以一次普通的开发构建
# 没有理由把其中一个整个落下。这个默认值原先跟着打包开关走，于是直接配置本目录只会
# 构建 IBus 宿主，Fcitx5 插件仅对正在做包的人编译。改为跟着环境走：装了开发包就构建
# 它，没装就把取得它的办法打出来，而不是悄悄丢掉这个平台的一半。打包仍然强制包含它，
# -DLINGYAO_ENABLE_FCITX5=OFF 仍然可以显式退出。
find_package(Fcitx5Core 5.0.20 QUIET)
if(LINGYAO_ENABLE_PACKAGING OR Fcitx5Core_FOUND)
  set(LINGYAO_ENABLE_FCITX5_DEFAULT ON)
else()
  set(LINGYAO_ENABLE_FCITX5_DEFAULT OFF)
endif()
option(LINGYAO_ENABLE_FCITX5 "Build the native Fcitx5 input method addon"
       ${LINGYAO_ENABLE_FCITX5_DEFAULT})
if(NOT LINGYAO_ENABLE_FCITX5)
  message(STATUS "跳过：Fcitx5 插件；请安装 Fcitx5 开发包（Fcitx5Core 5.0.20+），"
                 "或在配置时传入 -DLINGYAO_ENABLE_FCITX5=ON")
endif()
# License and third-party notices, the Linux counterpart of the macOS bundle's Resources/Licenses. Every install redistributes the code compiled into the host library, so plain `cmake --install` gets them as well, not only packages. The project license is `copyright` here (GPL-3.0.txt on macOS); it also covers the input engine (crates/engine), which is this project's code. What the engine carries from elsewhere keeps its own notice: zinnia, whose recognizer crates/engine/src/handwriting ports; the place names `@` mode offers, from modood/Administrative-divisions-of-China (WTFPL); the Korean Hanja table, from libhangul's data/hanja/hanja.txt (BSD-3-Clause); the Jyutping and bopomofo data of the Cantonese and Zhuyin schemes, from rime-cantonese (CC BY 4.0) and libchewing-data (LGPL-2.1-or-later), and the stroke orders of the Stroke scheme, from rime-stroke (LGPL-3.0, with the CNS11643 attribution), whose notices travel with every engine build even where those schemes are not offered; the provenance of the dictionary data lingyao-linux-setup downloads, carried verbatim from lingyao-engine as resources/licenses/lingyao-engine-dictionary-NOTICE.md, the copy every platform ships; and the provenance of the helpcode tables installed into the packaged resource directory: the five the Engine brought (ENGINE-NOTICE.md) and jiajia (NOTICE.md).
set(LINGYAO_NOTICE_SOURCES
  "${CMAKE_CURRENT_SOURCE_DIR}/../../LICENSE"
  "${CMAKE_CURRENT_SOURCE_DIR}/data/THIRD_PARTY_NOTICES.txt"
  "${CMAKE_CURRENT_SOURCE_DIR}/../../resources/licenses/lingyao-engine-dictionary-NOTICE.md"
  "${CMAKE_CURRENT_SOURCE_DIR}/../../resources/helpcodes/ENGINE-NOTICE.md"
  "${CMAKE_CURRENT_SOURCE_DIR}/../../resources/helpcodes/NOTICE.md"
  "${CMAKE_CURRENT_SOURCE_DIR}/../../resources/licenses/Zinnia-LICENSE.txt"
  "${CMAKE_CURRENT_SOURCE_DIR}/../../resources/licenses/Administrative-divisions-of-China-WTFPL.txt"
  "${CMAKE_CURRENT_SOURCE_DIR}/../../resources/licenses/libhangul-hanja-BSD-3-Clause.txt"
  "${CMAKE_CURRENT_SOURCE_DIR}/../../resources/licenses/rime-cantonese-CC-BY-4.0.txt"
  "${CMAKE_CURRENT_SOURCE_DIR}/../../resources/licenses/libchewing-data-LGPL-2.1.txt"
  "${CMAKE_CURRENT_SOURCE_DIR}/../../resources/licenses/ewts-MIT.txt"
  "${CMAKE_CURRENT_SOURCE_DIR}/../../resources/licenses/rime-stroke-LGPL-3.0.txt"
  "${CMAKE_CURRENT_SOURCE_DIR}/../../crates/client-core/data/opencc/LICENSE")
# `copyright` is the name Debian policy requires for the package license.
set(LINGYAO_NOTICE_NAMES
  copyright
  THIRD_PARTY_NOTICES.txt
  lingyao-engine-dictionary-NOTICE.md
  lingyao-engine-helpcode-NOTICE.md
  lingyao-helpcode-jiajia-NOTICE.md
  Zinnia-LICENSE.txt
  Administrative-divisions-of-China-WTFPL.txt
  libhangul-hanja-BSD-3-Clause.txt
  rime-cantonese-CC-BY-4.0.txt
  libchewing-data-LGPL-2.1.txt
  ewts-MIT.txt
  rime-stroke-LGPL-3.0.txt
  OpenCC-Apache-2.0.txt)
# The handwriting model's LGPL-2.1 license travels with the model, so it is a notice only when the model is installed.
if(LINGYAO_HANDWRITING_MODEL_DIR)
  list(APPEND LINGYAO_NOTICE_SOURCES "${LINGYAO_HANDWRITING_MODEL_DIR}/HandwritingModel-LICENSE.txt")
  list(APPEND LINGYAO_NOTICE_NAMES HandwritingModel-LICENSE.txt)
endif()
# Header-only nlohmann/json is compiled into the IBus engine, the provider programs and the Fcitx5 addon; no runtime package carries its copyright, so a pinned copy of its license ships instead.
list(APPEND LINGYAO_NOTICE_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/data/licenses/nlohmann_json-MIT.txt")
list(APPEND LINGYAO_NOTICE_NAMES nlohmann_json-MIT.txt)
# lingyao-voice-local compiles the sherpa-onnx C API header in; the runtime libraries, when installed, add ONNX Runtime and the notices of what it bundles.
list(APPEND LINGYAO_NOTICE_SOURCES "${LINGYAO_SHARED_VOICE_DIR}/third_party/sherpa-onnx/LICENSE")
list(APPEND LINGYAO_NOTICE_NAMES sherpa-onnx-Apache-2.0.txt)
if(LINGYAO_VOICE_RUNTIME_DIR)
  list(APPEND LINGYAO_NOTICE_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/data/licenses/onnxruntime-MIT.txt"
       "${CMAKE_CURRENT_SOURCE_DIR}/data/licenses/onnxruntime-ThirdPartyNotices.txt")
  list(APPEND LINGYAO_NOTICE_NAMES onnxruntime-MIT.txt onnxruntime-ThirdPartyNotices.txt)
endif()
# wayland-scanner compiles the layer-shell and xdg-shell protocol code into the IBus host, the wave overlay and the Fcitx5 addon, and only when xdg-shell.xml was found (both the IBus and the Fcitx5 side require it). The layer-shell license (HPND) asks for its notice in supporting documentation and xdg-shell's (MIT) in all copies, so the <copyright> block of the XML actually compiled is written out as the notice.
if(LINGYAO_XDG_SHELL_XML)
  set(LINGYAO_PROTOCOL_XMLS "${CMAKE_CURRENT_SOURCE_DIR}/data/wayland/wlr-layer-shell-unstable-v1.xml" "${LINGYAO_XDG_SHELL_XML}")
  set(LINGYAO_PROTOCOL_NOTICES wayland-wlr-layer-shell-LICENSE.txt wayland-xdg-shell-LICENSE.txt)
  foreach(LINGYAO_PROTOCOL_XML LINGYAO_PROTOCOL_NOTICE IN ZIP_LISTS LINGYAO_PROTOCOL_XMLS LINGYAO_PROTOCOL_NOTICES)
    file(READ "${LINGYAO_PROTOCOL_XML}" LINGYAO_PROTOCOL_CONTENT)
    if(NOT LINGYAO_PROTOCOL_CONTENT MATCHES "<copyright>(.*)</copyright>")
      message(FATAL_ERROR "No <copyright> block in ${LINGYAO_PROTOCOL_XML}")
    endif()
    get_filename_component(LINGYAO_PROTOCOL_FILE "${LINGYAO_PROTOCOL_XML}" NAME)
    file(WRITE "${CMAKE_CURRENT_BINARY_DIR}/notices/${LINGYAO_PROTOCOL_NOTICE}" "Wayland protocol ${LINGYAO_PROTOCOL_FILE}, compiled in as wayland-scanner output\n${CMAKE_MATCH_1}")
    set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS "${LINGYAO_PROTOCOL_XML}")
    list(APPEND LINGYAO_NOTICE_SOURCES "${CMAKE_CURRENT_BINARY_DIR}/notices/${LINGYAO_PROTOCOL_NOTICE}")
    list(APPEND LINGYAO_NOTICE_NAMES "${LINGYAO_PROTOCOL_NOTICE}")
  endforeach()
endif()
# Rust crates are statically linked into the host library (a cdylib), the MCP server and the desktop binary, and the desktop binary embeds a frontend bundled from npm packages. collect-notices.py gathers their license files from the resolved graphs; package-container.sh runs it and passes the results here. A development checkout has no such files, so only packaging requires them.
set(LINGYAO_RUST_NOTICES "" CACHE FILEPATH "Collected license files of the Rust crates linked into the host library, the MCP server and the desktop binary")
set(LINGYAO_FRONTEND_NOTICES "" CACHE FILEPATH "Collected license files of the npm packages bundled into the desktop frontend")
if(LINGYAO_ENABLE_PACKAGING AND NOT LINGYAO_RUST_NOTICES)
  message(FATAL_ERROR "Packaging requires LINGYAO_RUST_NOTICES; generate it with platforms/linux/collect-notices.py cargo (package-container.sh does)")
endif()
if(LINGYAO_ENABLE_PACKAGING AND LINGYAO_DESKTOP_BINARY AND NOT LINGYAO_FRONTEND_NOTICES)
  message(FATAL_ERROR "Packaging the desktop binary requires LINGYAO_FRONTEND_NOTICES; generate it with platforms/linux/collect-notices.py npm (package-container.sh does)")
endif()
if(LINGYAO_RUST_NOTICES)
  list(APPEND LINGYAO_NOTICE_SOURCES "${LINGYAO_RUST_NOTICES}")
  list(APPEND LINGYAO_NOTICE_NAMES rust-crates-NOTICES.txt)
endif()
if(LINGYAO_FRONTEND_NOTICES)
  list(APPEND LINGYAO_NOTICE_SOURCES "${LINGYAO_FRONTEND_NOTICES}")
  list(APPEND LINGYAO_NOTICE_NAMES frontend-npm-NOTICES.txt)
endif()
set(LINGYAO_MISSING_NOTICES "")
foreach(LINGYAO_NOTICE_SOURCE LINGYAO_NOTICE_NAME IN ZIP_LISTS LINGYAO_NOTICE_SOURCES LINGYAO_NOTICE_NAMES)
  if(EXISTS "${LINGYAO_NOTICE_SOURCE}" AND NOT IS_DIRECTORY "${LINGYAO_NOTICE_SOURCE}")
    install(FILES "${LINGYAO_NOTICE_SOURCE}"
            DESTINATION "${CMAKE_INSTALL_DATADIR}/doc/${LINGYAO_CLIENT_DIRECTORY}" RENAME "${LINGYAO_NOTICE_NAME}")
  else()
    list(APPEND LINGYAO_MISSING_NOTICES "${LINGYAO_NOTICE_SOURCE}")
  endif()
endforeach()
if(LINGYAO_MISSING_NOTICES)
  list(JOIN LINGYAO_MISSING_NOTICES "\n  " LINGYAO_MISSING_NOTICE_LIST)
  # A redistributable package without the notices of the code it contains must not be produced; a development install only warns.
  if(LINGYAO_ENABLE_PACKAGING)
    message(FATAL_ERROR "Packaging requires every third-party notice; missing:\n  ${LINGYAO_MISSING_NOTICE_LIST}")
  endif()
  message(WARNING "Installing without these third-party notices:\n  ${LINGYAO_MISSING_NOTICE_LIST}")
endif()
# Fcitx5 插件先配置：打包要知道它的插件目录（装在自己前缀下的版本取自 Fcitx5Core.pc），才能把那个归 fcitx5 所有的目录排除在 RPM 的文件列表之外。
if(LINGYAO_ENABLE_FCITX5)
  add_subdirectory(fcitx5)
endif()
if(LINGYAO_ENABLE_PACKAGING)
  include(cmake/packaging.cmake)
endif()

# assert() 是这些测试唯一的断言手段，而 Release 配置定义的 NDEBUG 会把它们整个消掉：
# 测试于是一个条件都不检查，还照样报告通过，只在 assert 里出现的局部变量同时变成未使
# 用变量，-Werror 再把构建打断。此前只有两个目标单独带了 -UNDEBUG，其余三十来个没有。
# 断言对构建类型的依赖不该逐个目标去记，统一加在这里。
get_property(lingyao_linux_targets DIRECTORY PROPERTY BUILDSYSTEM_TARGETS)
foreach(lingyao_linux_target IN LISTS lingyao_linux_targets)
  if(lingyao_linux_target MATCHES "-test$")
    target_compile_options(${lingyao_linux_target} PRIVATE -UNDEBUG)
  endif()
endforeach()
