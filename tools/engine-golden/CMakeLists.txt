# Builds the golden recorder against an already-built reference engine (see README.md).
# Mirrors how the reference links its test executables (LINGYAO-Engine/CMakeLists.txt: target_link_libraries(<test> PRIVATE LingyaoIme::Engine)) and the exact flags of build-ref/CMakeFiles/eval_sentences.dir/{flags.make,link.txt}.
cmake_minimum_required(VERSION 3.25)
project(LingyaoEngineGolden LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Release)
endif()

set(LINGYAO_ENGINE_REF_SRC "" CACHE PATH "Reference LINGYAO-Engine source tree (pinned archive + overlays)")
set(LINGYAO_ENGINE_REF_BUILD "" CACHE PATH "Configured and built reference tree containing libLingyaoImeEngine.a")
if(NOT EXISTS "${LINGYAO_ENGINE_REF_SRC}/include/lingyao/session.h")
    message(FATAL_ERROR "LINGYAO_ENGINE_REF_SRC must point at the reference LINGYAO-Engine source tree")
endif()
if(NOT EXISTS "${LINGYAO_ENGINE_REF_BUILD}/libLingyaoImeEngine.a")
    message(FATAL_ERROR "LINGYAO_ENGINE_REF_BUILD must contain libLingyaoImeEngine.a")
endif()

# Same dependency set the engine target exports (Boost headers, header-only fmt, SQLite3, Threads).
find_package(Boost REQUIRED)
find_package(SQLite3 REQUIRED)
find_package(Threads REQUIRED)
find_package(nlohmann_json 3 CONFIG REQUIRED)

add_library(LingyaoImeEngineRef STATIC IMPORTED)
set_target_properties(LingyaoImeEngineRef PROPERTIES
    IMPORTED_LOCATION "${LINGYAO_ENGINE_REF_BUILD}/libLingyaoImeEngine.a"
    INTERFACE_INCLUDE_DIRECTORIES "${LINGYAO_ENGINE_REF_SRC};${LINGYAO_ENGINE_REF_SRC}/include"
    INTERFACE_COMPILE_DEFINITIONS "FMT_HEADER_ONLY=1")
if(TARGET SQLite3::SQLite3)
    set(GOLDEN_SQLITE SQLite3::SQLite3)
else()
    set(GOLDEN_SQLITE SQLite::SQLite3)
endif()
target_link_libraries(LingyaoImeEngineRef INTERFACE Boost::headers ${GOLDEN_SQLITE} Threads::Threads)

add_executable(engine_golden_recorder recorder.cpp)
target_link_libraries(engine_golden_recorder PRIVATE LingyaoImeEngineRef nlohmann_json::nlohmann_json)
