#include "tests/includes/test_framework.h"

#include "../../src/DebugLog.h"

TEST_CASE(debug_log_write_length_is_bounded)
{
    REQUIRE(lingyaoui::DebugLogWriteLength(-1, 2048) == 0);
    REQUIRE(lingyaoui::DebugLogWriteLength(0, 2048) == 0);
    REQUIRE(lingyaoui::DebugLogWriteLength(2047, 2048) == 2047);
    REQUIRE(lingyaoui::DebugLogWriteLength(2048, 2048) == 2047);
    REQUIRE(lingyaoui::DebugLogWriteLength(10000, 2048) == 2047);
    REQUIRE(lingyaoui::DebugLogWriteLength(100, 0) == 0);
}
