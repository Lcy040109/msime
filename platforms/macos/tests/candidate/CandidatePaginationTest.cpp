#include "../../src/input/InputControllerKeyRouting.h"
#include "../../src/candidate/CandidateWheelRouting.h"
#include <stdexcept>

static void require(bool value, const char *message) { if (!value) throw std::runtime_error(message); }

int main() {
    using namespace lingyao::mac;
    require(CandidatePageStart(0, 23, 9) == 0, "first page start");
    require(CandidatePageStart(8, 23, 9) == 0, "selected item stays on first page");
    require(CandidatePageStart(9, 23, 9) == 9, "second page start");
    require(CandidatePageStart(99, 23, 9) == 18, "out of range selection clamps to last page");
    require(CandidatePageEnd(9, 23, 9) == 17, "second page end");
    require(CandidatePageEnd(18, 23, 9) == 22, "short final page end");
    require(CandidatePageStart(0, 0, 9) == 0 && CandidatePageEnd(0, 0, 9) == 0, "empty page");
    require(ClassifyControllerKey(kVK_PageUp, true) == ControllerKeyAction::MoveCandidatePageUp, "page up key");
    require(ClassifyControllerKey(kVK_PageDown, true) == ControllerKeyAction::MoveCandidatePageDown, "page down key");
    require(ClassifyControllerKey(kVK_ANSI_LeftBracket, true, CandidatePageShortcut::Brackets, '[', false) == ControllerKeyAction::MoveCandidatePageUp, "bracket page up");
    require(ClassifyControllerKey(kVK_ANSI_RightBracket, true, CandidatePageShortcut::Brackets, ']', false) == ControllerKeyAction::MoveCandidatePageDown, "bracket page down");
    require(ClassifyControllerKey(kVK_ANSI_LeftBracket, true, CandidatePageShortcut::Brackets, '[', true) == ControllerKeyAction::Character, "modified bracket passthrough");
    require(ClassifyControllerKey(kVK_ANSI_LeftBracket, true, CandidatePageShortcut::Brackets, '[', false) == ControllerKeyAction::MoveCandidatePageUp, "physical bracket page up");
    require(ClassifyControllerKey(kVK_ANSI_Minus, true, CandidatePageShortcut::MinusEqual, '-', false, true) == ControllerKeyAction::Character, "Japanese minus passthrough");
    require(ClassifyControllerKey(kVK_ANSI_Equal, true, CandidatePageShortcut::MinusEqual, '+', false) == ControllerKeyAction::Character, "Unicode plus passthrough");
    require(ClassifyControllerKey(0, true, CandidatePageShortcut::Brackets, '[', false) == ControllerKeyAction::Character, "wrong physical bracket rejected");
    require(lingyao::mac::IsJapaneseMinusEqualInput(3, false, '-') && lingyao::mac::IsJapaneseMinusEqualInput(3, false, '='), "direct Japanese scheme punctuation");
    require(lingyao::mac::IsJapaneseMinusEqualInput(0, true, '-') && lingyao::mac::IsJapaneseMinusEqualInput(0, true, '='), "temporary Japanese punctuation");
    require(!lingyao::mac::IsJapaneseMinusEqualInput(0, false, '-') && !lingyao::mac::IsJapaneseMinusEqualInput(3, false, '['), "non-Japanese punctuation remains navigation");
    require(lingyao::mac::IsJapaneseMinusEqualKey(3, false, 27, 'x') &&
                lingyao::mac::IsJapaneseMinusEqualKey(3, false, 24, 'x'),
            "Japanese physical minus/equal keys bypass paging despite layout characters");
    require(lingyao::mac::IsJapaneseMinusEqualKey(0, true, 0, '-') &&
                !lingyao::mac::IsJapaneseMinusEqualKey(0, false, 27, '-'),
            "temporary Japanese keeps character fallback and ordinary input keeps paging");
    require(lingyao::mac::PhysicalCandidateDigitSlot(18) == 0 && lingyao::mac::PhysicalCandidateDigitSlot(25) == 8, "physical number row mapping");
    require(lingyao::mac::PhysicalCandidateDigitSlot(83) == 0 && lingyao::mac::PhysicalCandidateDigitSlot(92) == 8, "keypad digit mapping");
    require(lingyao::mac::PhysicalCandidateDigitSlot(82) == -1 && lingyao::mac::PhysicalCandidateDigitSlot(29) == -1 && lingyao::mac::PhysicalCandidateDigitSlot(0) == -1, "non-candidate key codes rejected");
    require(lingyao::mac::ShouldRoutePhysicalCandidateDigit(true, false, false, false), "ordinary candidate digits route");
    require(!lingyao::mac::ShouldRoutePhysicalCandidateDigit(true, false, true, false), "digits a mode spells with reach the engine");
    require(!lingyao::mac::ShouldRoutePhysicalCandidateDigit(true, true, false, false), "nine-key digits reach the engine");
    require(!lingyao::mac::ShouldRoutePhysicalCandidateDigit(true, false, false, true), "modified digits reach the engine");
    require(!lingyao::mac::ShouldRoutePhysicalCandidateDigit(false, false, false, false), "hidden candidate panel does not route digits");
    require(lingyao::mac::ShouldRouteSpellingShiftCandidateDigit(true, true, true, false),
            "a mode spelling with digits selects with Shift and a digit, which its input cannot use");
    require(!lingyao::mac::ShouldRouteSpellingShiftCandidateDigit(true, true, false, false),
            "an unshifted digit is still input");
    require(!lingyao::mac::ShouldRouteSpellingShiftCandidateDigit(true, false, true, false),
            "outside such a mode a shifted digit is punctuation, not a selection");
    require(!lingyao::mac::ShouldRouteSpellingShiftCandidateDigit(false, true, true, false),
            "with no candidate panel there is nothing to select");
    require(!lingyao::mac::ShouldRouteSpellingShiftCandidateDigit(true, true, true, true),
            "a shifted digit the mode spells with, such as ( in expression mode, stays input");
    require(lingyao::mac::PhysicalCandidateDigitCharacter(0) == '1' && lingyao::mac::PhysicalCandidateDigitCharacter(8) == '9' &&
                lingyao::mac::PhysicalCandidateDigitCharacter(-1) == '\0' && lingyao::mac::PhysicalCandidateDigitCharacter(9) == '\0',
            "candidate slots name the digit their key types");
    require(lingyao::mac::PhysicalKeySoundClass(49) == 1 && lingyao::mac::PhysicalKeySoundClass(36) == 2 &&
                lingyao::mac::PhysicalKeySoundClass(76) == 2 && lingyao::mac::PhysicalKeySoundClass(51) == 3,
            "space, both enter keys and backspace have their own key sound class");
    require(lingyao::mac::PhysicalKeySoundClass(0) == 0 && lingyao::mac::PhysicalKeySoundClass(117) == 0 &&
                lingyao::mac::PhysicalKeySoundClass(18) == 0,
            "letters, digits and forward delete use the default key sound");
    require(lingyao::mac::IsKeypadDecimal(65) && !lingyao::mac::IsKeypadDecimal(0), "keypad decimal mapping");
    require(lingyao::mac::KeypadPunctuation(65) == '.' && lingyao::mac::KeypadPunctuation(67) == '*' &&
                lingyao::mac::KeypadPunctuation(69) == '+' && lingyao::mac::KeypadPunctuation(75) == '/' &&
                lingyao::mac::KeypadPunctuation(78) == '-' && lingyao::mac::KeypadPunctuation(81) == '=' &&
                lingyao::mac::KeypadPunctuation(95) == ',', "keypad punctuation mapping");
    require(lingyao::mac::KeypadPunctuation(82) == '\0' && lingyao::mac::KeypadPunctuation(0) == '\0',
            "non-punctuation keypad codes rejected");
    using lingyao::mac::CandidateWheelAction;
    require(lingyao::mac::CandidateWheelPageAction(1, true, true, false) == CandidateWheelAction::PreviousPage, "wheel previous page");
    require(lingyao::mac::CandidateWheelPageAction(-1, true, false, true) == CandidateWheelAction::NextPage, "wheel next page");
    require(lingyao::mac::CandidateWheelPageAction(-1, false, true, true) == CandidateWheelAction::None, "disabled wheel passthrough");
    require(lingyao::mac::CandidateWheelPageAction(1, true, false, true) == CandidateWheelAction::None, "wheel respects first page");
    require(lingyao::mac::CandidateWheelPageAction(-1, true, true, false) == CandidateWheelAction::None, "wheel respects last page");
    using lingyao::mac::ConsumeCandidateWheelDelta;
    double wheel = 0.0;
    int wheelPages = 0;
    for (int event = 0; event < 20; ++event)
        wheelPages += ConsumeCandidateWheelDelta(wheel, -3.0, true, event == 0, false, 40.0);
    require(wheelPages == -1 && wheel == -20.0, "one short trackpad swipe pages once and keeps the remainder");
    require(ConsumeCandidateWheelDelta(wheel, -100.0, true, false, true, 40.0) == 0 && wheel == 0.0,
            "momentum scrolling never pages and drops the remainder");
    wheel = -30.0;
    require(ConsumeCandidateWheelDelta(wheel, 30.0, true, false, false, 40.0) == 0 && wheel == 30.0,
            "direction reversal drops the old remainder");
    require(ConsumeCandidateWheelDelta(wheel, 10.0, true, false, false, 40.0) == 1 && wheel == 0.0,
            "precise scrolling pages once per full notch toward the previous page");
    wheel = 30.0;
    require(ConsumeCandidateWheelDelta(wheel, 5.0, true, true, false, 40.0) == 0 && wheel == 5.0,
            "gesture begin starts from an empty accumulator");
    wheel = 0.0;
    require(ConsumeCandidateWheelDelta(wheel, -130.0, true, false, false, 40.0) == -3 && wheel == -10.0,
            "a multi-notch precise delta splits into several pages");
    wheel = 25.0;
    require(ConsumeCandidateWheelDelta(wheel, -6.0, false, false, false, 40.0) == -1 && wheel == 0.0,
            "classic wheel pages once per notch regardless of line acceleration");
    require(ConsumeCandidateWheelDelta(wheel, 0.0, false, false, false, 40.0) == 0, "zero classic delta does not page");
    static_assert(lingyao::mac::CandidateWheelPreciseNotch > 0.0);
    static_assert(lingyao::mac::KoreanKeyLetter('r', false) == 'r' && lingyao::mac::KoreanKeyLetter('R', false) == 'r',
                  "Caps Lock must not turn a Korean key into its shifted jamo");
    static_assert(lingyao::mac::KoreanKeyLetter('r', true) == 'R' && lingyao::mac::KoreanKeyLetter('R', true) == 'R',
                  "Shift decides the case of a Korean key");
    static_assert(lingyao::mac::KoreanKeyLetter('1', true) == '1' && lingyao::mac::KoreanKeyLetter('.', false) == '.' &&
                      lingyao::mac::KoreanKeyLetter(' ', true) == ' ',
                  "Only letters are recased for Korean");
    require(lingyao::mac::JapaneseSpaceCommitsFallback(1, lingyao::mac::CandidateSourceFallback),
            "a lone Fallback row (bare Shift+R) is committed by Japanese Space instead of arming a conversion");
    require(!lingyao::mac::JapaneseSpaceCommitsFallback(1, 0) &&
                !lingyao::mac::JapaneseSpaceCommitsFallback(2, lingyao::mac::CandidateSourceFallback) &&
                !lingyao::mac::JapaneseSpaceCommitsFallback(0, lingyao::mac::CandidateSourceFallback),
            "Japanese Space still arms a conversion for real candidates");
}
