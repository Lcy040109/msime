cmake_minimum_required(VERSION 3.25)

if(NOT WIN32)
  return()
endif()

project(LingyaoTsfEditControl LANGUAGES CXX)

set(TSF_EDIT_CONTROL_SOURCES
    src/DisplayAttribute.cpp
    src/TextContainer.cpp
    src/TextEditSink.cpp
    src/TextEditor.cpp
    src/TextInputCtrl.cpp
    src/TextLayout.cpp
    src/TextStore.cpp
    src/TsfD2DTextBox.cpp
    src/TsfTextServices.cpp)

add_library(lingyao-tsf-edit-control STATIC ${TSF_EDIT_CONTROL_SOURCES})
target_include_directories(lingyao-tsf-edit-control
                           PUBLIC include
                           PRIVATE src ../../tsf/Header)
target_compile_features(lingyao-tsf-edit-control PUBLIC cxx_std_17)
target_compile_definitions(lingyao-tsf-edit-control PRIVATE UNICODE _UNICODE)
target_compile_options(lingyao-tsf-edit-control PRIVATE
  $<$<CXX_COMPILER_ID:MSVC>:/W4;/WX;/utf-8>
  $<$<NOT:$<CXX_COMPILER_ID:MSVC>>:-Wall;-Wextra>)
target_link_libraries(lingyao-tsf-edit-control PUBLIC
  d2d1 dwrite imm32 ole32 oleaut32 user32 gdi32)

add_executable(lingyao-tsf-edit-control-demo WIN32 demo/TsfD2DTextBoxDemo.cpp)
target_compile_features(lingyao-tsf-edit-control-demo PRIVATE cxx_std_17)
target_compile_definitions(lingyao-tsf-edit-control-demo PRIVATE UNICODE _UNICODE)
target_compile_options(lingyao-tsf-edit-control-demo PRIVATE
  $<$<CXX_COMPILER_ID:MSVC>:/W4;/WX;/utf-8>
  $<$<NOT:$<CXX_COMPILER_ID:MSVC>>:-Wall;-Wextra>)
if(NOT MSVC)
  target_link_options(lingyao-tsf-edit-control-demo PRIVATE -municode)
endif()
target_link_libraries(lingyao-tsf-edit-control-demo PRIVATE lingyao-tsf-edit-control)
