#include "lingyaoui/Application.h"
#include "lingyaoui/Window.h"

#include "DemoScene.h"

int WINAPI wWinMain(HINSTANCE, HINSTANCE, PWSTR, int nCmdShow)
{
    if (!lingyaoui::Application::Initialize())
    {
        return -1;
    }

    lingyaoui::Window window(L"lingyaoui.Window", L"lingyaoui Demo", 1500, 1200);
    if (!window.Create())
    {
        lingyaoui::Application::Shutdown();
        return -1;
    }

    window.SetScene(lingyaoui::CreateDemoScene());
    const int exitCode = window.Run(nCmdShow);
    lingyaoui::Application::Shutdown();
    return exitCode;
}
