cmake_minimum_required(VERSION 3.25)

project(LINGYAOClientTsf LANGUAGES CXX)
include("${CMAKE_CURRENT_SOURCE_DIR}/../Edition.cmake")
enable_testing()
add_subdirectory(tests/registration_profiles)
add_subdirectory(tests/registration_categories)
add_test(NAME lingyao-tsf-version-resource COMMAND "${CMAKE_COMMAND}"
  "-DSOURCE_ROOT=${CMAKE_CURRENT_SOURCE_DIR}"
  -P "${CMAKE_CURRENT_SOURCE_DIR}/tests/version_resource.cmake")
add_executable(lingyao-tsf-key-repeat-guard-test tests/input/key_repeat_guard.cpp)
target_compile_features(lingyao-tsf-key-repeat-guard-test PRIVATE cxx_std_17)
target_include_directories(lingyao-tsf-key-repeat-guard-test PRIVATE .)
if(MSVC)
  target_compile_options(lingyao-tsf-key-repeat-guard-test PRIVATE /UNDEBUG /W4 /WX)
else()
  target_compile_options(lingyao-tsf-key-repeat-guard-test PRIVATE -UNDEBUG -Wall -Wextra -Werror)
endif()
add_test(NAME lingyao-tsf-key-repeat-guard COMMAND lingyao-tsf-key-repeat-guard-test)
add_executable(lingyao-tsf-smart-punctuation-fingerprint-test tests/input/smart_punctuation_fingerprint.cpp)
target_compile_features(lingyao-tsf-smart-punctuation-fingerprint-test PRIVATE cxx_std_17)
target_include_directories(lingyao-tsf-smart-punctuation-fingerprint-test PRIVATE Global)
if(MSVC)
  target_compile_options(lingyao-tsf-smart-punctuation-fingerprint-test PRIVATE /UNDEBUG /W4 /WX /utf-8)
else()
  target_compile_options(lingyao-tsf-smart-punctuation-fingerprint-test PRIVATE -UNDEBUG -Wall -Wextra -Werror)
endif()
add_test(NAME lingyao-tsf-smart-punctuation-fingerprint COMMAND lingyao-tsf-smart-punctuation-fingerprint-test)
add_executable(lingyao-tsf-client-key-router-test tests/input/client_key_router.cpp)
target_compile_features(lingyao-tsf-client-key-router-test PRIVATE cxx_std_17)
target_include_directories(lingyao-tsf-client-key-router-test PRIVATE . Global IME Header Key)
if(MSVC)
  target_compile_options(lingyao-tsf-client-key-router-test PRIVATE /UNDEBUG /W4 /WX)
else()
  target_compile_options(lingyao-tsf-client-key-router-test PRIVATE -UNDEBUG -Wall -Wextra -Werror)
endif()
add_test(NAME lingyao-tsf-client-key-router COMMAND lingyao-tsf-client-key-router-test)
add_executable(lingyao-tsf-authenticated-client-key-router-test tests/input/authenticated_client_key_router.cpp)
target_compile_features(lingyao-tsf-authenticated-client-key-router-test PRIVATE cxx_std_17)
target_include_directories(lingyao-tsf-authenticated-client-key-router-test PRIVATE .)
if(MSVC)
  target_compile_options(lingyao-tsf-authenticated-client-key-router-test PRIVATE /UNDEBUG /W4 /WX)
else()
  target_compile_options(lingyao-tsf-authenticated-client-key-router-test PRIVATE -UNDEBUG -Wall -Wextra -Werror)
endif()
add_test(NAME lingyao-tsf-authenticated-client-key-router COMMAND lingyao-tsf-authenticated-client-key-router-test)
add_executable(lingyao-tsf-keyboard-cancellation-test tests/input/keyboard_cancellation.cpp)
target_compile_features(lingyao-tsf-keyboard-cancellation-test PRIVATE cxx_std_17)
if(MSVC)
  target_compile_options(lingyao-tsf-keyboard-cancellation-test PRIVATE /UNDEBUG /W4 /WX)
else()
  target_compile_options(lingyao-tsf-keyboard-cancellation-test PRIVATE -UNDEBUG -Wall -Wextra -Werror)
endif()
add_test(NAME lingyao-tsf-keyboard-cancellation COMMAND lingyao-tsf-keyboard-cancellation-test)
foreach(path_standard IN ITEMS 17 20)
  add_executable(lingyao-tsf-host-path-${path_standard}-test tests/runtime/host_path_encoding.cpp)
  set_target_properties(lingyao-tsf-host-path-${path_standard}-test PROPERTIES
    CXX_STANDARD ${path_standard} CXX_STANDARD_REQUIRED YES CXX_EXTENSIONS NO)
  if(MSVC)
    target_compile_options(lingyao-tsf-host-path-${path_standard}-test PRIVATE /UNDEBUG /W4 /WX /utf-8)
  else()
    target_compile_options(lingyao-tsf-host-path-${path_standard}-test PRIVATE -UNDEBUG -Wall -Wextra -Werror)
  endif()
  add_test(NAME lingyao-tsf-host-path-${path_standard} COMMAND lingyao-tsf-host-path-${path_standard}-test)
endforeach()
add_test(NAME lingyao-tsf-host-library-config COMMAND "${CMAKE_COMMAND}"
  "-DSOURCE_ROOT=${CMAKE_CURRENT_SOURCE_DIR}"
  "-DTEST_ROOT=${CMAKE_CURRENT_BINARY_DIR}/host-library-config-test"
  -P "${CMAKE_CURRENT_SOURCE_DIR}/tests/host_library_config.cmake")
add_executable(lingyao-tsf-character-result-test tests/input/character_result.cpp)
target_compile_features(lingyao-tsf-character-result-test PRIVATE cxx_std_17)
target_include_directories(lingyao-tsf-character-result-test PRIVATE ../../../crates/host-api/include)
add_test(NAME lingyao-tsf-character-result COMMAND lingyao-tsf-character-result-test)
add_executable(lingyao-tsf-host-focus-test tests/runtime/host_focus.cpp)
target_compile_features(lingyao-tsf-host-focus-test PRIVATE cxx_std_17)
add_test(NAME lingyao-tsf-host-focus COMMAND lingyao-tsf-host-focus-test)
add_executable(lingyao-tsf-prepared-options-test tests/runtime/prepared_options.cpp PreparedHostOptions.cpp)
target_compile_features(lingyao-tsf-prepared-options-test PRIVATE cxx_std_17)
add_test(NAME lingyao-tsf-prepared-options COMMAND lingyao-tsf-prepared-options-test)
add_executable(lingyao-tsf-module-path-test tests/runtime/module_path.cpp)
target_compile_features(lingyao-tsf-module-path-test PRIVATE cxx_std_17)
add_test(NAME lingyao-tsf-module-path COMMAND lingyao-tsf-module-path-test)
add_executable(lingyao-tsf-candidate-ownership-test tests/candidate/candidate_ownership.cpp)
target_compile_features(lingyao-tsf-candidate-ownership-test PRIVATE cxx_std_17)
add_test(NAME lingyao-tsf-candidate-ownership COMMAND lingyao-tsf-candidate-ownership-test)
add_executable(lingyao-tsf-preedit-caret-test tests/input/preedit_caret.cpp)
target_compile_features(lingyao-tsf-preedit-caret-test PRIVATE cxx_std_17)
add_test(NAME lingyao-tsf-preedit-caret COMMAND lingyao-tsf-preedit-caret-test)
find_package(nlohmann_json 3.11 REQUIRED)
add_executable(lingyao-tsf-raw-commit-test tests/input/raw_commit.cpp EngineResponse.cpp)
target_compile_features(lingyao-tsf-raw-commit-test PRIVATE cxx_std_17)
target_include_directories(lingyao-tsf-raw-commit-test PRIVATE ../../../crates/host-api/include)
target_link_libraries(lingyao-tsf-raw-commit-test PRIVATE nlohmann_json::nlohmann_json)
add_test(NAME lingyao-tsf-raw-commit COMMAND lingyao-tsf-raw-commit-test)
add_executable(lingyao-tsf-host-composition-test tests/input/host_composition.cpp EngineResponse.cpp)
target_compile_features(lingyao-tsf-host-composition-test PRIVATE cxx_std_17)
target_include_directories(lingyao-tsf-host-composition-test PRIVATE ../../../crates/host-api/include)
target_link_libraries(lingyao-tsf-host-composition-test PRIVATE nlohmann_json::nlohmann_json)
add_test(NAME lingyao-tsf-host-composition COMMAND lingyao-tsf-host-composition-test)
add_executable(lingyao-tsf-engine-response-test tests/input/engine_response.cpp EngineResponse.cpp)
target_compile_features(lingyao-tsf-engine-response-test PRIVATE cxx_std_17)
target_include_directories(lingyao-tsf-engine-response-test PRIVATE ../../../crates/host-api/include)
target_link_libraries(lingyao-tsf-engine-response-test PRIVATE nlohmann_json::nlohmann_json)
add_test(NAME lingyao-tsf-engine-response COMMAND lingyao-tsf-engine-response-test)
add_executable(lingyao-tsf-punctuation-key-policy-test tests/input/punctuation_key_policy.cpp)
target_compile_features(lingyao-tsf-punctuation-key-policy-test PRIVATE cxx_std_17)
add_test(NAME lingyao-tsf-punctuation-key-policy COMMAND lingyao-tsf-punctuation-key-policy-test)
add_executable(lingyao-tsf-korean-key-test tests/input/korean_key.cpp)
target_compile_features(lingyao-tsf-korean-key-test PRIVATE cxx_std_17)
target_include_directories(lingyao-tsf-korean-key-test PRIVATE ../../../crates/host-api/include)
add_test(NAME lingyao-tsf-korean-key COMMAND lingyao-tsf-korean-key-test)
add_executable(lingyao-tsf-host-composed-key-test tests/input/host_composed_key.cpp)
target_compile_features(lingyao-tsf-host-composed-key-test PRIVATE cxx_std_17)
target_include_directories(lingyao-tsf-host-composed-key-test PRIVATE ../../../crates/host-api/include)
add_test(NAME lingyao-tsf-host-composed-key COMMAND lingyao-tsf-host-composed-key-test)
# How the TIP routes the keys of the V, "/" and "@" modes, which must match the Server's EditPolicy.h.
add_executable(lingyao-tsf-local-mode-key-policy-test tests/input/local_mode_key_policy.cpp)
target_compile_features(lingyao-tsf-local-mode-key-policy-test PRIVATE cxx_std_17)
if(MSVC)
  target_compile_options(lingyao-tsf-local-mode-key-policy-test PRIVATE /W4 /WX)
else()
  target_compile_options(lingyao-tsf-local-mode-key-policy-test PRIVATE -Wall -Wextra -Werror)
endif()
add_test(NAME lingyao-tsf-local-mode-key-policy COMMAND lingyao-tsf-local-mode-key-policy-test)
# AltGr arrives as Ctrl+Alt: a chord that produces a character is typing, not an application shortcut.
add_executable(lingyao-tsf-altgr-key-policy-test tests/input/altgr_key_policy.cpp)
target_compile_features(lingyao-tsf-altgr-key-policy-test PRIVATE cxx_std_17)
if(MSVC)
  target_compile_options(lingyao-tsf-altgr-key-policy-test PRIVATE /W4 /WX)
else()
  target_compile_options(lingyao-tsf-altgr-key-policy-test PRIVATE -Wall -Wextra -Werror)
endif()
add_test(NAME lingyao-tsf-altgr-key-policy COMMAND lingyao-tsf-altgr-key-policy-test)
add_executable(lingyao-tsf-paired-punctuation-wiring-test tests/input/paired_punctuation_wiring.cpp)
target_compile_features(lingyao-tsf-paired-punctuation-wiring-test PRIVATE cxx_std_17)
add_test(NAME lingyao-tsf-paired-punctuation-wiring COMMAND lingyao-tsf-paired-punctuation-wiring-test ${CMAKE_CURRENT_SOURCE_DIR})
add_executable(lingyao-tsf-smart-punctuation-focus-wiring-test tests/input/smart_punctuation_focus_wiring.cpp)
target_compile_features(lingyao-tsf-smart-punctuation-focus-wiring-test PRIVATE cxx_std_17)
add_test(NAME lingyao-tsf-smart-punctuation-focus-wiring COMMAND lingyao-tsf-smart-punctuation-focus-wiring-test ${CMAKE_CURRENT_SOURCE_DIR})

# The TSF tip is an in-process DLL.  It is intentionally a separate target
# from the out-of-process Windows Server.
if(NOT WIN32)
  return()
endif()
add_executable(lingyao-tsf-class-factory-test tests/runtime/class_factory.cpp)
target_compile_features(lingyao-tsf-class-factory-test PRIVATE cxx_std_17)
target_link_libraries(lingyao-tsf-class-factory-test PRIVATE ole32)
if(MSVC)
  target_compile_options(lingyao-tsf-class-factory-test PRIVATE /UNDEBUG /W4 /WX)
else()
  target_compile_options(lingyao-tsf-class-factory-test PRIVATE -UNDEBUG -Wall -Wextra -Werror)
endif()
add_test(NAME lingyao-tsf-class-factory COMMAND lingyao-tsf-class-factory-test)
add_executable(lingyao-tsf-paired-punctuation-policy-test tests/input/paired_punctuation_policy.cpp)
target_compile_features(lingyao-tsf-paired-punctuation-policy-test PRIVATE cxx_std_17)
add_test(NAME lingyao-tsf-paired-punctuation-policy COMMAND lingyao-tsf-paired-punctuation-policy-test)
set(LINGYAO_HOST_LIBRARY "" CACHE FILEPATH "Cargo-built host library or import library matching the TSF architecture")
include("${CMAKE_CURRENT_SOURCE_DIR}/RequireHostLibrary.cmake")
enable_language(RC)

add_library(lingyao-tsf SHARED
  Candidate/EnumTfCandidates.cpp Candidate/SearchCandidateProvider.cpp
  Candidate/TipCandidateList.cpp Candidate/TipCandidateString.cpp
  Compartment/Compartment.cpp
  Composition/Composition.cpp Composition/CompositionProcessorEngine.cpp
  Composition/EndComposition.cpp Composition/StartComposition.cpp
  DisplayAttribute/DisplayAttribute.cpp DisplayAttribute/DisplayAttributeInfo.cpp
  DisplayAttribute/DisplayAttributeProvider.cpp DisplayAttribute/EnumDisplayAttributeInfo.cpp
  Edit/EditSession.cpp Edit/GetTextExtentEditSession.cpp Edit/TextEditSink.cpp
  Global/Globals.cpp
  IME/ActiveLanguageProfileNotifySink.cpp IME/FunctionProviderSink.cpp
  IME/LingyaoIME.cpp IME/LingyaoIMEBaseStructure.cpp
  IPC/Ipc.cpp IPC/PassthroughStatisticsQueue.cpp IPC/KeyPressStatisticsQueue.cpp
  Key/KeyEventSink.cpp Key/KeyHandler.cpp Key/KeyHandlerEditSession.cpp
  Key/KeyStateCategory.cpp
  LanguageBar/LanguageBar.cpp
  Register/Register.cpp Register/RegKey.cpp
  Tf/TfInputProcessorProfile.cpp Tf/TfTextLayoutSink.cpp
  Thread/ThreadFocusSink.cpp Thread/ThreadMgrEventSink.cpp Thread/ThreadState.cpp
  UI/CandidateSessionState.cpp UI/CandidateListUIPresenter.cpp
  Utils/CommonUtils.cpp Utils/FanyUtils.cpp
  DllMain.cpp Server.cpp
  EngineSessionAdapter.cpp EngineSessionAdapter.h EngineResponse.cpp
  HostOptionsPaths.cpp HostOptionsPaths.h PreparedHostOptions.cpp
  IME/LingyaoIME.rc
  IME/LingyaoIME.def
)
add_dependencies(lingyao-tsf-class-factory-test lingyao-tsf)

find_package(fmt CONFIG REQUIRED)
find_path(UTF8CPP_INCLUDE_DIR NAMES utf8cpp/utf8.h REQUIRED)

target_include_directories(lingyao-tsf PRIVATE
  . Candidate Compartment Composition DisplayAttribute Edit FanyLog Global
  Header IME IPC Key LanguageBar Register Tf Thread UI Utils
  ../../../shared/contracts
  ${UTF8CPP_INCLUDE_DIR}
  ../../../crates/host-api/include
)
target_compile_features(lingyao-tsf PRIVATE cxx_std_17)
target_compile_definitions(lingyao-tsf PRIVATE UNICODE _UNICODE)
target_link_libraries(lingyao-tsf PRIVATE nlohmann_json::nlohmann_json fmt::fmt-header-only ole32 oleaut32 user32 advapi32 shell32 uuid)
# TSF objects are obtained through COM; GUIDs come from uuid. No direct TF_*
# exports are used, and MinGW distributions need not ship an msctf import lib.
if(MINGW)
  target_sources(lingyao-tsf PRIVATE Global/TsfPropertyGuids.cpp)
endif()
target_link_libraries(lingyao-tsf PRIVATE "${LINGYAO_HOST_LIBRARY}")
set_target_properties(lingyao-tsf PROPERTIES OUTPUT_NAME LingyaoImeTsf)
install(TARGETS lingyao-tsf
  RUNTIME DESTINATION bin
  LIBRARY DESTINATION lib
  ARCHIVE DESTINATION lib
)
if(MSVC)
  target_compile_options(lingyao-tsf PRIVATE /W4 /Zc:__cplusplus /Zc:threadSafeInit-)
  set_property(TARGET lingyao-tsf PROPERTY MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")
endif()

# Windows on Arm loads the 64-bit TIP into native ARM64 processes and into emulated x64 ones, which share one registry view and so one InprocServer32 path. The DLL there is Arm64X: native ARM64 code for the first, ARM64EC code for the second (https://learn.microsoft.com/windows/arm/arm64x-build). It is linked in two passes over two build trees: the ARM64 pass (-A ARM64) records its linker inputs in a response file, and the ARM64EC pass (-A ARM64EC) links them beside its own with /MACHINE:ARM64X. Each pass links its own LINGYAO_HOST_LIBRARY, so the two halves import different host DLLs: Build-Client.ps1 gives the ARM64 pass an import library naming the ARM64 host and the ARM64EC pass the x64 one, which the emulated process runs.
set(LINGYAO_TSF_ARM64X "" CACHE STRING "Arm64X pass of the TSF DLL: empty, ARM64 or ARM64EC")
set(LINGYAO_TSF_ARM64X_RESPONSE "" CACHE FILEPATH "Linker input list the ARM64 pass writes and the ARM64EC pass reads")
if(LINGYAO_TSF_ARM64X)
  if(NOT MSVC OR NOT IS_ABSOLUTE "${LINGYAO_TSF_ARM64X_RESPONSE}")
    message(FATAL_ERROR "LINGYAO_TSF_ARM64X needs MSVC and an absolute LINGYAO_TSF_ARM64X_RESPONSE")
  endif()
  if(LINGYAO_TSF_ARM64X STREQUAL "ARM64")
    get_filename_component(lingyao_arm64x_response_dir "${LINGYAO_TSF_ARM64X_RESPONSE}" DIRECTORY)
    file(MAKE_DIRECTORY "${lingyao_arm64x_response_dir}")
    target_link_options(lingyao-tsf PRIVATE "/LINKREPROFULLPATHRSP:${LINGYAO_TSF_ARM64X_RESPONSE}")
  elseif(LINGYAO_TSF_ARM64X STREQUAL "ARM64EC")
    if(NOT EXISTS "${LINGYAO_TSF_ARM64X_RESPONSE}")
      message(FATAL_ERROR "Build the ARM64 pass first: ${LINGYAO_TSF_ARM64X_RESPONSE} does not exist")
    endif()
    # One quoted absolute path per line. The ARM64 pass's resource file is not taken: this pass compiles the same one.
    file(STRINGS "${LINGYAO_TSF_ARM64X_RESPONSE}" lingyao_arm64_objects REGEX "obj\"$")
    file(STRINGS "${LINGYAO_TSF_ARM64X_RESPONSE}" lingyao_arm64_libraries REGEX "lib\"$")
    file(STRINGS "${LINGYAO_TSF_ARM64X_RESPONSE}" lingyao_arm64_definition REGEX "def\"$")
    if(NOT lingyao_arm64_objects OR NOT lingyao_arm64_definition)
      message(FATAL_ERROR "${LINGYAO_TSF_ARM64X_RESPONSE} lists no ARM64 objects or module definition")
    endif()
    string(REPLACE "\"" "" lingyao_arm64_objects "${lingyao_arm64_objects}")
    string(REPLACE "\"" "" lingyao_arm64_libraries "${lingyao_arm64_libraries}")
    string(REPLACE "\"" "" lingyao_arm64_definition "${lingyao_arm64_definition}")
    string(REGEX REPLACE "^/[Dd][Ee][Ff]:" "/DEFARM64NATIVE:" lingyao_arm64_definition "${lingyao_arm64_definition}")
    target_sources(lingyao-tsf PRIVATE ${lingyao_arm64_objects})
    # CMake puts /machine:ARM64EC into the default linker flags for this platform, after the target's own options, where it would win and produce an ARM64EC image (x64 machine type, no ARM64 view) instead.
    string(REGEX REPLACE "/[Mm][Aa][Cc][Hh][Ii][Nn][Ee]:[Aa][Rr][Mm]64[Ee][Cc]" "" CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS}")
    target_link_options(lingyao-tsf PRIVATE /MACHINE:ARM64X "${lingyao_arm64_definition}" ${lingyao_arm64_libraries})
    set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS "${LINGYAO_TSF_ARM64X_RESPONSE}")
  else()
    message(FATAL_ERROR "LINGYAO_TSF_ARM64X must be empty, ARM64 or ARM64EC, not ${LINGYAO_TSF_ARM64X}")
  endif()
endif()
add_executable(lingyao-tsf-commit-and-continue-payload-test
  tests/commit_candidate_and_continue_payload.cpp)
target_include_directories(lingyao-tsf-commit-and-continue-payload-test PRIVATE .)
target_compile_features(lingyao-tsf-commit-and-continue-payload-test PRIVATE cxx_std_17)
add_test(NAME lingyao-tsf-commit-and-continue-payload
  COMMAND lingyao-tsf-commit-and-continue-payload-test)
add_executable(lingyao-tsf-passthrough-statistics-test
  tests/passthrough_statistics.cpp)
target_include_directories(lingyao-tsf-passthrough-statistics-test PRIVATE IPC)
target_compile_features(lingyao-tsf-passthrough-statistics-test PRIVATE cxx_std_17)
add_test(NAME lingyao-tsf-passthrough-statistics
  COMMAND lingyao-tsf-passthrough-statistics-test)
add_executable(lingyao-tsf-key-press-statistics-test
  tests/key_press_statistics.cpp)
target_include_directories(lingyao-tsf-key-press-statistics-test PRIVATE IPC)
target_compile_features(lingyao-tsf-key-press-statistics-test PRIVATE cxx_std_17)
add_test(NAME lingyao-tsf-key-press-statistics
  COMMAND lingyao-tsf-key-press-statistics-test)
