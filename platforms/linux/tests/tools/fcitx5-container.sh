#!/usr/bin/env bash
set -euo pipefail
[[ ${LINGYAO_ISOLATED_LINUX_TEST:-} == 1 && -d /resources && -d /build ]] || exit 2

cmake -S platforms/linux -B /build/fcitx5 -G Ninja \
  -DLINGYAO_HOST_LIBRARY=/build/cargo/debug/liblingyao_host_api.so \
  -DLINGYAO_ENABLE_FCITX5=ON -DLINGYAO_ENABLE_PACKAGING=OFF \
  -DLINGYAO_FCITX5_TEST_RESOURCES=/resources
cmake --build /build/fcitx5 --target lingyao-fcitx5 fcitx5-native-test
ctest --test-dir /build/fcitx5 -R '^fcitx5-(native-context|native-ai|daemon-frontend|gtk-editor)$' \
  --output-on-failure
echo "Fcitx5 native addon, daemon, and GTK editor acceptance passed"
