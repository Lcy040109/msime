# The adapter links the Host API's C ABI, so the library is required at configure time.
if(NOT LINGYAO_HOST_LIBRARY OR NOT IS_ABSOLUTE "${LINGYAO_HOST_LIBRARY}" OR
   NOT EXISTS "${LINGYAO_HOST_LIBRARY}" OR IS_DIRECTORY "${LINGYAO_HOST_LIBRARY}")
  message(FATAL_ERROR
    "LINGYAO_HOST_LIBRARY must name an existing absolute-path Cargo-built host library "
    "or Windows import library matching the TSF target architecture. "
    "Build lingyao-host-api for that architecture before configuring the DLL.")
endif()
