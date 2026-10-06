#include "lingyaoui/Application.h"

#include <objbase.h>
#include <windows.h>

namespace lingyaoui
{
bool Application::Initialize()
{
    SetProcessDpiAwarenessContext(DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2);
    return SUCCEEDED(CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED));
}

void Application::Shutdown()
{
    CoUninitialize();
}
} // namespace lingyaoui
