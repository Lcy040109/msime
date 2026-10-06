#pragma once

#include <d2d1.h>

namespace lingyaoui
{
struct Brush
{
    D2D1_COLOR_F fill = D2D1::ColorF(0xFFFFFF);
    D2D1_COLOR_F stroke = D2D1::ColorF(0x000000);
    float strokeWidth = 1.0f;
    float radiusX = 0.0f;
    float radiusY = 0.0f;
};
} // namespace lingyaoui
