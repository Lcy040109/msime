#include "KeyboardPanel.h"

#include "lingyaoui/Application.h"
#include "lingyaoui/Scene.h"
#include "lingyaoui/Theme.h"
#include "lingyaoui/Window.h"

#include <memory>

int WINAPI wWinMain(HINSTANCE, HINSTANCE, PWSTR, int nCmdShow)
{
    if (!lingyaoui::Application::Initialize())
        return -1;

    lingyaoui::Theme theme = lingyaoui::ThemeManager::GetCurrent();
    theme.windowBackground = D2D1::ColorF(0x17181D);
    theme.surface = D2D1::ColorF(0x17181D);
    theme.textPrimary = D2D1::ColorF(0xF1F1F3);
    theme.textSecondary = D2D1::ColorF(0xAEB0B7);
    lingyaoui::ThemeManager::SetCurrent(std::move(theme));

    lingyaoui::Window window(L"lingyaoui.KeyboardDemo", L"Dark touch keyboard", 1100, 400);
    window.SetWindowStyle(WS_POPUP, WS_EX_TOOLWINDOW | WS_EX_NOACTIVATE);
    window.SetDragRegionHeight(28.0f);
    window.SetRoundedCorners(true);
    if (!window.Create())
    {
        lingyaoui::Application::Shutdown();
        return -1;
    }

    auto scene = std::make_unique<lingyaoui::Scene>();
    scene->SetRoot(std::make_shared<lingyaoui::KeyboardPanel>());
    window.SetScene(std::move(scene));
    const int result = window.Run(nCmdShow);
    lingyaoui::Application::Shutdown();
    return result;
}
