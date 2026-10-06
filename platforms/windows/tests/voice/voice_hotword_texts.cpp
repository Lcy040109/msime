#include "VoiceHotwordTexts.h"

#include <cassert>
#include <nlohmann/json.hpp>

int main() {
  const auto hotwords = nlohmann::json::array({
      {{"text", "灵耀"}, {"pinyin", "shui shan"}},
      {{"text", "输入法"}, {"pinyin", "shu ru fa"}},
      {{"pinyin", "missing text"}},
  });

  const auto texts = lingyao::windows::hotword_texts(hotwords);
  assert((texts == std::vector<std::string>{"灵耀", "输入法"}));
  assert(texts.capacity() >= hotwords.size());
}
