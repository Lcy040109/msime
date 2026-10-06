cmake_minimum_required(VERSION 3.25)

project(lingyaoui VERSION 0.1.0 LANGUAGES CXX)

include(CTest)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

add_definitions(
    /D_UNICODE=1
    /DUNICODE=1
    /DNOMINMAX=1
    /DWIN32_LEAN_AND_MEAN=1
)

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)

add_library(lingyaoui STATIC
    src/Application.cpp
    src/Brush.cpp
    src/Controls.cpp
    src/DebugLog.cpp
    src/DeviceResources.cpp
    src/Fonts.cpp
    src/TextBox.cpp
    src/Layout.cpp
    src/Scene.cpp
    src/Theme.cpp
    src/Window.cpp
    src/WindowClass.cpp
    src/tsf/DisplayAttribute.cpp
    src/tsf/TextContainer.cpp
    src/tsf/TextEditor.cpp
    src/tsf/TextEditSink.cpp
    src/tsf/TextLayout.cpp
    src/tsf/TextStore.cpp
    src/tsf/TsfTextServices.cpp
    include/lingyaoui/Application.h
    include/lingyaoui/Brush.h
    src/DebugLog.h
    include/lingyaoui/Controls.h
    include/lingyaoui/DeviceResources.h
    include/lingyaoui/Fonts.h
    include/lingyaoui/Layout.h
    include/lingyaoui/Scene.h
    include/lingyaoui/Theme.h
    include/lingyaoui/Types.h
    include/lingyaoui/Window.h
    include/lingyaoui/LruCache.h
    src/tsf/DisplayAttribute.h
    src/tsf/private.h
    src/tsf/TextContainer.h
    src/tsf/TextEditor.h
    src/tsf/TextEditSink.h
    src/tsf/TextLayout.h
    src/tsf/TextStore.h
    src/tsf/TsfTextServices.h
)

target_include_directories(lingyaoui
    PUBLIC
        ${CMAKE_CURRENT_SOURCE_DIR}/include
    PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/src/tsf
)

target_link_libraries(lingyaoui PUBLIC
    d2d1.lib
    dxguid.lib
    d3d11.lib
    dcomp.lib
    dxgi.lib
    dwrite.lib
    dwmapi.lib
    imm32.lib
    ole32.lib
    oleaut32.lib
    uuid.lib
    windowscodecs.lib
    shlwapi.lib
)

add_executable(lingyaoui-demo WIN32
    demos/lingyaoui-demo/DemoScene.cpp
    demos/lingyaoui-demo/DemoScene.h
    demos/lingyaoui-demo/main.cpp
    demos/lingyaoui-demo/lingyaoui-demo.rc
    demos/lingyaoui-demo/resource.h
)

target_link_libraries(lingyaoui-demo PRIVATE lingyaoui)
target_compile_definitions(lingyaoui-demo PRIVATE LINGYAOUI_ASSET_DIR=L\"${CMAKE_CURRENT_SOURCE_DIR}/assets\")

add_executable(lingyaoui-emoji-panel WIN32
    demos/lingyaoui-emoji-panel/EmojiPanel.cpp
    demos/lingyaoui-emoji-panel/EmojiPanel.h
    demos/lingyaoui-emoji-panel/main.cpp
    demos/lingyaoui-emoji-panel/lingyaoui-emoji-panel.rc
    demos/lingyaoui-emoji-panel/resource.h
)

target_link_libraries(lingyaoui-emoji-panel PRIVATE lingyaoui)

add_executable(lingyaoui-keyboard-demo WIN32
    demos/lingyaoui-keyboard-demo/KeyboardPanel.cpp
    demos/lingyaoui-keyboard-demo/KeyboardPanel.h
    demos/lingyaoui-keyboard-demo/main.cpp
    demos/lingyaoui-keyboard-demo/lingyaoui-keyboard-demo.rc
    demos/lingyaoui-keyboard-demo/resource.h
)

target_link_libraries(lingyaoui-keyboard-demo PRIVATE lingyaoui)

option(LINGYAOUI_BUILD_HANDWRITING_DEMO "Build the Windows SDK C++/WinRT handwriting demo" ON)
if(LINGYAOUI_BUILD_HANDWRITING_DEMO)
add_executable(lingyaoui-handwriting-demo WIN32
    demos/lingyaoui-handwriting-demo/HandwritingPanel.cpp
    demos/lingyaoui-handwriting-demo/HandwritingPanel.h
    demos/lingyaoui-handwriting-demo/main.cpp
    demos/lingyaoui-handwriting-demo/lingyaoui-handwriting-demo.rc
    demos/lingyaoui-handwriting-demo/resource.h
)

target_link_libraries(lingyaoui-handwriting-demo PRIVATE lingyaoui windowsapp.lib)
install(TARGETS lingyaoui-handwriting-demo RUNTIME DESTINATION bin)

# C++/WinRT needs C++20 coroutines. Under C++17 it falls back to
# <experimental/coroutine>, which recent MSVC STL versions reject outright.
target_compile_features(lingyaoui-handwriting-demo PRIVATE cxx_std_20)
endif()
install(TARGETS lingyaoui-demo lingyaoui-emoji-panel lingyaoui-keyboard-demo RUNTIME DESTINATION bin)

if(MINGW)
    # All demos use wWinMain, not the narrow WinMain CRT entry point.
    foreach(demo lingyaoui-demo lingyaoui-emoji-panel lingyaoui-keyboard-demo lingyaoui-handwriting-demo)
        if(TARGET ${demo})
            target_link_options(${demo} PRIVATE -municode)
        endif()
    endforeach()
endif()

if(MSVC)
    target_compile_options(lingyaoui PRIVATE /W4 /permissive-)
    target_compile_options(lingyaoui-demo PRIVATE /W4 /permissive-)
    target_compile_options(lingyaoui-emoji-panel PRIVATE /W4 /permissive-)
    target_compile_options(lingyaoui-keyboard-demo PRIVATE /W4 /permissive-)
    if(TARGET lingyaoui-handwriting-demo)
        target_compile_options(lingyaoui-handwriting-demo PRIVATE /W4 /permissive-)
    endif()
endif()

if(BUILD_TESTING)
    add_subdirectory(tests)
endif()
