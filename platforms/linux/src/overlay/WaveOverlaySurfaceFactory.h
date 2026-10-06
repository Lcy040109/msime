#pragma once

#include "WaveOverlaySurface.h"
#include <ibus.h>

#include <memory>

namespace lingyao::linux_host {

std::unique_ptr<WaveOverlaySurface> create_wave_overlay_surface(
    IBusEngine *engine, WaveOverlaySurface::ActionHandler action_handler = {});

}  // namespace lingyao::linux_host
