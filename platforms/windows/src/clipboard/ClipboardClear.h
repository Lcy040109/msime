#pragma once
#include "CandidateClickWorker.h"
namespace lingyao::windows {
struct ClipboardClear {};
using ClipboardClearWorker = SingleClickWorker<ClipboardClear>;
}
