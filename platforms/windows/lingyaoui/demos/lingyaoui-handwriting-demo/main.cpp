#include "HandwritingPanel.h"

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
    theme.windowBackground = D2D1::ColorF(0x202027);
    theme.surface = D2D1::ColorF(0x292A31);
    theme.borderStrong = D2D1::ColorF(0x45454F);
    theme.primary = D2D1::ColorF(0x8C55A2);
    theme.primaryFocusStrong = D2D1::ColorF(0xD88BDE);
    theme.textPrimary = D2D1::ColorF(0xF5F5F7);
    theme.textSecondary = D2D1::ColorF(0xB8B8C0);
    lingyaoui::ThemeManager::SetCurrent(std::move(theme));

    lingyaoui::Window window(L"lingyaoui.HandwritingDemo", L"\u6c34\u6749\u624b\u5199\u8bc6\u522b\u677f", 980, 650);
    window.SetWindowStyle(WS_POPUP, WS_EX_TOOLWINDOW | WS_EX_TOPMOST);
    window.SetDragRegionHeight(38.0f);
    window.SetRoundedCorners(true);
    if (!window.Create())
    {
        lingyaoui::Application::Shutdown();
        return -1;
    }

    auto scene = std::make_unique<lingyaoui::Scene>();
    scene->SetRoot(std::make_shared<lingyaoui::HandwritingPanel>());
    window.SetScene(std::move(scene));
    const int result = window.Run(nCmdShow);
    lingyaoui::Application::Shutdown();
    return result;
}
