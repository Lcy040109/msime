#pragma once

// 由 platforms/linux/scripts/edition_linux.py 从 shared/contracts/editions.json 生成，不要手改；改了版本表之后运行 `python3 platforms/linux/scripts/edition_linux.py gen` 并提交结果。
//
// 每个 Linux 构建必须定义且只定义一个版本选择宏（LINGYAO_EDITION_FULL, LINGYAO_EDITION_PINYIN, LINGYAO_EDITION_WUBI, LINGYAO_EDITION_JAPANESE, LINGYAO_EDITION_VIETNAMESE, LINGYAO_EDITION_TIBETAN），CMake 按缓存变量 LINGYAO_EDITION 定义。少了它就停在这里，而不是悄悄编成 full、去读写 full 的状态目录和 socket。
//
// full 的名字与引入版本之前相同；其他版本的每用户目录、IBus 引擎、Fcitx5 插件与动作名、图标和命令名都带版本，所以几个版本可以同时安装，两个版本的 Fcitx5 插件也可以被同一个 fcitx5 进程同时加载。

#if (defined(LINGYAO_EDITION_FULL) + defined(LINGYAO_EDITION_PINYIN) + defined(LINGYAO_EDITION_WUBI) + defined(LINGYAO_EDITION_JAPANESE) + defined(LINGYAO_EDITION_VIETNAMESE) + defined(LINGYAO_EDITION_TIBETAN)) != 1
#error "Define exactly one of LINGYAO_EDITION_FULL, LINGYAO_EDITION_PINYIN, LINGYAO_EDITION_WUBI, LINGYAO_EDITION_JAPANESE, LINGYAO_EDITION_VIETNAMESE, LINGYAO_EDITION_TIBETAN; platforms/linux/cmake/Edition.cmake does this from LINGYAO_EDITION"
#endif
#if defined(LINGYAO_EDITION_FULL)
#define LINGYAO_EDITION_ID "full"
#define LINGYAO_EDITION_IS_FULL 1
#define LINGYAO_EDITION_DISPLAY_NAME "\347\201\265\350\200\200\350\276\223\345\205\245\346\263\225"
#define LINGYAO_EDITION_DISPLAY_NAME_EN "LINGYAO"
#define LINGYAO_EDITION_PACKAGE "lingyao-linux"
#define LINGYAO_EDITION_CLIENT_DIRECTORY "lingyao-client"
#define LINGYAO_EDITION_IBUS_ENGINE "lingyao-linux"
#define LINGYAO_EDITION_IBUS_LONGNAME "Lingyao \347\201\265\350\200\200\350\276\223\345\205\245\346\263\225"
#define LINGYAO_EDITION_IBUS_LANGUAGE "zh"
#define LINGYAO_EDITION_FCITX5_ADDON "lingyao"
#define LINGYAO_EDITION_ICON "lingyao-linux"
#define LINGYAO_EDITION_SETUP_PROGRAM "lingyao-linux-setup"
#define LINGYAO_EDITION_SETTINGS_PROGRAM "lingyao-linux-settings"
#define LINGYAO_EDITION_TAURI_IDENTIFIER "app.lingyao.linux"
#define LINGYAO_EDITION_TELEMETRY_DIRECTORY "lingyao"
#define LINGYAO_EDITION_DEFAULT_SCHEME "quanpin"
#define LINGYAO_EDITION_INPUT_SCHEMES "quanpin", "shuangpin", "wubi", "japanese", "korean", "cantonese", "zhuyin", "vietnamese", "tibetan", "stroke"
#define LINGYAO_EDITION_TEMPORARY_JAPANESE 1
#define LINGYAO_EDITION_HANDWRITING 1
#elif defined(LINGYAO_EDITION_PINYIN)
#define LINGYAO_EDITION_ID "pinyin"
#define LINGYAO_EDITION_IS_FULL 0
#define LINGYAO_EDITION_DISPLAY_NAME "\347\201\265\350\200\200\346\213\274\351\237\263"
#define LINGYAO_EDITION_DISPLAY_NAME_EN "LINGYAO Pinyin"
#define LINGYAO_EDITION_PACKAGE "lingyao-linux-pinyin"
#define LINGYAO_EDITION_CLIENT_DIRECTORY "lingyao-client-pinyin"
#define LINGYAO_EDITION_IBUS_ENGINE "lingyao-linux-pinyin"
#define LINGYAO_EDITION_IBUS_LONGNAME "Lingyao \347\201\265\350\200\200\346\213\274\351\237\263"
#define LINGYAO_EDITION_IBUS_LANGUAGE "zh"
#define LINGYAO_EDITION_FCITX5_ADDON "lingyao-pinyin"
#define LINGYAO_EDITION_ICON "lingyao-linux-pinyin"
#define LINGYAO_EDITION_SETUP_PROGRAM "lingyao-linux-pinyin-setup"
#define LINGYAO_EDITION_SETTINGS_PROGRAM "lingyao-linux-pinyin-settings"
#define LINGYAO_EDITION_TAURI_IDENTIFIER "app.lingyao.linux.pinyin"
#define LINGYAO_EDITION_TELEMETRY_DIRECTORY "lingyao-pinyin"
#define LINGYAO_EDITION_DEFAULT_SCHEME "quanpin"
#define LINGYAO_EDITION_INPUT_SCHEMES "quanpin", "shuangpin"
#define LINGYAO_EDITION_TEMPORARY_JAPANESE 1
#define LINGYAO_EDITION_HANDWRITING 1
#elif defined(LINGYAO_EDITION_WUBI)
#define LINGYAO_EDITION_ID "wubi"
#define LINGYAO_EDITION_IS_FULL 0
#define LINGYAO_EDITION_DISPLAY_NAME "\347\201\265\350\200\200\344\272\224\347\254\224"
#define LINGYAO_EDITION_DISPLAY_NAME_EN "LINGYAO Wubi"
#define LINGYAO_EDITION_PACKAGE "lingyao-linux-wubi"
#define LINGYAO_EDITION_CLIENT_DIRECTORY "lingyao-client-wubi"
#define LINGYAO_EDITION_IBUS_ENGINE "lingyao-linux-wubi"
#define LINGYAO_EDITION_IBUS_LONGNAME "Lingyao \347\201\265\350\200\200\344\272\224\347\254\224"
#define LINGYAO_EDITION_IBUS_LANGUAGE "zh"
#define LINGYAO_EDITION_FCITX5_ADDON "lingyao-wubi"
#define LINGYAO_EDITION_ICON "lingyao-linux-wubi"
#define LINGYAO_EDITION_SETUP_PROGRAM "lingyao-linux-wubi-setup"
#define LINGYAO_EDITION_SETTINGS_PROGRAM "lingyao-linux-wubi-settings"
#define LINGYAO_EDITION_TAURI_IDENTIFIER "app.lingyao.linux.wubi"
#define LINGYAO_EDITION_TELEMETRY_DIRECTORY "lingyao-wubi"
#define LINGYAO_EDITION_DEFAULT_SCHEME "wubi"
#define LINGYAO_EDITION_INPUT_SCHEMES "wubi"
#define LINGYAO_EDITION_TEMPORARY_JAPANESE 0
#define LINGYAO_EDITION_HANDWRITING 1
#elif defined(LINGYAO_EDITION_JAPANESE)
#define LINGYAO_EDITION_ID "japanese"
#define LINGYAO_EDITION_IS_FULL 0
#define LINGYAO_EDITION_DISPLAY_NAME "\347\201\265\350\200\200\346\227\245\350\257\255"
#define LINGYAO_EDITION_DISPLAY_NAME_EN "LINGYAO Japanese"
#define LINGYAO_EDITION_PACKAGE "lingyao-linux-japanese"
#define LINGYAO_EDITION_CLIENT_DIRECTORY "lingyao-client-japanese"
#define LINGYAO_EDITION_IBUS_ENGINE "lingyao-linux-japanese"
#define LINGYAO_EDITION_IBUS_LONGNAME "Lingyao \347\201\265\350\200\200\346\227\245\350\257\255"
#define LINGYAO_EDITION_IBUS_LANGUAGE "ja"
#define LINGYAO_EDITION_FCITX5_ADDON "lingyao-japanese"
#define LINGYAO_EDITION_ICON "lingyao-linux-japanese"
#define LINGYAO_EDITION_SETUP_PROGRAM "lingyao-linux-japanese-setup"
#define LINGYAO_EDITION_SETTINGS_PROGRAM "lingyao-linux-japanese-settings"
#define LINGYAO_EDITION_TAURI_IDENTIFIER "app.lingyao.linux.japanese"
#define LINGYAO_EDITION_TELEMETRY_DIRECTORY "lingyao-japanese"
#define LINGYAO_EDITION_DEFAULT_SCHEME "japanese"
#define LINGYAO_EDITION_INPUT_SCHEMES "japanese"
#define LINGYAO_EDITION_TEMPORARY_JAPANESE 0
#define LINGYAO_EDITION_HANDWRITING 0
#elif defined(LINGYAO_EDITION_VIETNAMESE)
#define LINGYAO_EDITION_ID "vietnamese"
#define LINGYAO_EDITION_IS_FULL 0
#define LINGYAO_EDITION_DISPLAY_NAME "\347\201\265\350\200\200\350\266\212\345\215\227\350\257\255"
#define LINGYAO_EDITION_DISPLAY_NAME_EN "LINGYAO Vietnamese"
#define LINGYAO_EDITION_PACKAGE "lingyao-linux-vietnamese"
#define LINGYAO_EDITION_CLIENT_DIRECTORY "lingyao-client-vietnamese"
#define LINGYAO_EDITION_IBUS_ENGINE "lingyao-linux-vietnamese"
#define LINGYAO_EDITION_IBUS_LONGNAME "Lingyao \347\201\265\350\200\200\350\266\212\345\215\227\350\257\255"
#define LINGYAO_EDITION_IBUS_LANGUAGE "vi"
#define LINGYAO_EDITION_FCITX5_ADDON "lingyao-vietnamese"
#define LINGYAO_EDITION_ICON "lingyao-linux-vietnamese"
#define LINGYAO_EDITION_SETUP_PROGRAM "lingyao-linux-vietnamese-setup"
#define LINGYAO_EDITION_SETTINGS_PROGRAM "lingyao-linux-vietnamese-settings"
#define LINGYAO_EDITION_TAURI_IDENTIFIER "app.lingyao.linux.vietnamese"
#define LINGYAO_EDITION_TELEMETRY_DIRECTORY "lingyao-vietnamese"
#define LINGYAO_EDITION_DEFAULT_SCHEME "vietnamese"
#define LINGYAO_EDITION_INPUT_SCHEMES "vietnamese"
#define LINGYAO_EDITION_TEMPORARY_JAPANESE 0
#define LINGYAO_EDITION_HANDWRITING 0
#elif defined(LINGYAO_EDITION_TIBETAN)
#define LINGYAO_EDITION_ID "tibetan"
#define LINGYAO_EDITION_IS_FULL 0
#define LINGYAO_EDITION_DISPLAY_NAME "\347\201\265\350\200\200\350\227\217\346\226\207"
#define LINGYAO_EDITION_DISPLAY_NAME_EN "LINGYAO Tibetan"
#define LINGYAO_EDITION_PACKAGE "lingyao-linux-tibetan"
#define LINGYAO_EDITION_CLIENT_DIRECTORY "lingyao-client-tibetan"
#define LINGYAO_EDITION_IBUS_ENGINE "lingyao-linux-tibetan"
#define LINGYAO_EDITION_IBUS_LONGNAME "Lingyao \347\201\265\350\200\200\350\227\217\346\226\207"
#define LINGYAO_EDITION_IBUS_LANGUAGE "bo"
#define LINGYAO_EDITION_FCITX5_ADDON "lingyao-tibetan"
#define LINGYAO_EDITION_ICON "lingyao-linux-tibetan"
#define LINGYAO_EDITION_SETUP_PROGRAM "lingyao-linux-tibetan-setup"
#define LINGYAO_EDITION_SETTINGS_PROGRAM "lingyao-linux-tibetan-settings"
#define LINGYAO_EDITION_TAURI_IDENTIFIER "app.lingyao.linux.tibetan"
#define LINGYAO_EDITION_TELEMETRY_DIRECTORY "lingyao-tibetan"
#define LINGYAO_EDITION_DEFAULT_SCHEME "tibetan"
#define LINGYAO_EDITION_INPUT_SCHEMES "tibetan"
#define LINGYAO_EDITION_TEMPORARY_JAPANESE 0
#define LINGYAO_EDITION_HANDWRITING 0
#endif
