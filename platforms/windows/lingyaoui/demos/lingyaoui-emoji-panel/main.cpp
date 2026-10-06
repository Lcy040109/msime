#include "EmojiPanel.h"

#include "lingyaoui/Application.h"
#include "lingyaoui/Scene.h"
#include "lingyaoui/Theme.h"
#include "lingyaoui/Window.h"

#include <memory>

int WINAPI wWinMain(HINSTANCE, HINSTANCE, PWSTR, int nCmdShow)
{
    if (!lingyaoui::Application::Initialize())
    {
        return -1;
    }

    lingyaoui::Theme theme = lingyaoui::ThemeManager::GetCurrent();
    theme.windowBackground = D2D1::ColorF(0x202027);
    theme.surface = D2D1::ColorF(0x202027);
    theme.borderStrong = D2D1::ColorF(0x45454F);
    theme.primary = D2D1::ColorF(0x8C55A2);
    theme.primaryFocusStrong = D2D1::ColorF(0xD88BDE);
    theme.textPrimary = D2D1::ColorF(0xF5F5F7);
    theme.textSecondary = D2D1::ColorF(0xC9C9D0);
    lingyaoui::ThemeManager::SetCurrent(std::move(theme));

    // Window sizes are physical pixels for a per-monitor-DPI-aware Win32 popup. The panel renders
    // its 550 x 610 design surface at 2/3 scale, producing the requested 550 x 610 window at 150%.
    lingyaoui::Window window(L"lingyaoui.EmojiPanel", L"Emoji and more", 550, 610);
    window.SetWindowStyle(WS_POPUP, WS_EX_TOOLWINDOW);
    window.SetDragRegionHeight(56.0f * 2.0f / 3.0f);
    window.SetRoundedCorners(true);
    if (!window.Create())
    {
        lingyaoui::Application::Shutdown();
        return -1;
    }

    auto scene = std::make_unique<lingyaoui::Scene>();
    scene->SetRoot(std::make_shared<lingyaoui::EmojiPanel>());
    window.SetScene(std::move(scene));
    const int result = window.Run(nCmdShow);
    lingyaoui::Application::Shutdown();
    return result;
}
